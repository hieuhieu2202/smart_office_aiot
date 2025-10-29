import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/te_report.dart';
import '../../domain/entities/te_retest_rate.dart';
import '../../domain/usecases/get_model_names.dart';
import '../../domain/usecases/get_retest_rate_report.dart';
import '../../domain/usecases/get_retest_rate_error_detail.dart';

class TERetestRateController extends GetxController {
  TERetestRateController({
    required this.getRetestRateReportUseCase,
    required this.getModelNamesUseCase,
    required this.getRetestRateErrorDetailUseCase,
    this.initialModelSerial = 'SWITCH',
    List<String>? initialModels,
    this.defaultDayWindow = 6,
  }) {
    if (initialModels != null && initialModels.isNotEmpty) {
      final normalized = initialModels
          .map((model) => model.trim())
          .where((model) => model.isNotEmpty)
          .toList();
      selectedModels.assignAll(LinkedHashSet<String>.from(normalized));
    }
  }

  final GetRetestRateReportUseCase getRetestRateReportUseCase;
  final GetModelNamesUseCase getModelNamesUseCase;
  final GetRetestRateErrorDetailUseCase getRetestRateErrorDetailUseCase;
  final String initialModelSerial;
  final int defaultDayWindow;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<DateTime> lastUpdated = DateTime.now().obs;
  final RxList<String> availableModels = <String>[].obs;
  final RxList<String> selectedModels = <String>[].obs;
  final Rx<TERetestDetailEntity> detail = TERetestDetailEntity.empty().obs;
  final Rx<Set<String>> highlightCells = Rx<Set<String>>(<String>{});
  final RxString _searchQuery = ''.obs;

  final Rx<DateTime> startDate = DateTime.now().obs;
  final Rx<DateTime> endDate = DateTime.now().obs;

  late String _modelSerial;
  Timer? _autoRefreshTimer;
  Timer? _highlightClearTimer;

  final DateFormat _rangeFormatter = DateFormat('yyyy/MM/dd HH:mm');
  final DateFormat _dateFormatter = DateFormat('yyyy/MM/dd');
  final Duration _autoRefreshInterval = const Duration(seconds: 20);
  static const String _networkIssueMessage =
      'Không thể kết nối tới máy chủ.\nVui lòng kiểm tra lại đường truyền và thử lại.';

  String get rangeLabel =>
      '${_rangeFormatter.format(startDate.value)} - ${_rangeFormatter.format(endDate.value)}';

  bool get hasError => errorMessage.isNotEmpty;

  String get searchQuery => _searchQuery.value;

  List<String> get formattedDates =>
      detail.value.dates.map(_formatDateString).toList(growable: false);

  TERetestDetailEntity get filteredDetail {
    final current = detail.value;
    final query = _searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return current;
    }

    final filteredRows = current.rows.where((row) {
      final modelMatch = row.modelName.toLowerCase().contains(query);
      if (modelMatch) return true;
      for (final group in row.groupNames) {
        if (group.toLowerCase().contains(query)) {
          return true;
        }
      }
      return false;
    }).toList(growable: false);

    if (filteredRows.isEmpty) {
      return TERetestDetailEntity(
        dates: List<String>.from(current.dates),
        rows: const <TERetestDetailRowEntity>[],
      );
    }

    return TERetestDetailEntity(
      dates: List<String>.from(current.dates),
      rows: filteredRows,
    );
  }

  @override
  void onInit() {
    super.onInit();
    _modelSerial = _normalizeModelSerial(initialModelSerial);
    final now = DateTime.now();
    final defaultEnd = DateTime(now.year, now.month, now.day, 19, 30);
    final defaultStart = defaultEnd.subtract(Duration(days: defaultDayWindow - 1));
    startDate.value = DateTime(
      defaultStart.year,
      defaultStart.month,
      defaultStart.day,
      7,
      30,
    );
    endDate.value = defaultEnd;
  }

  @override
  void onReady() {
    super.onReady();
    initialize();
  }

  Future<void> initialize() async {
    await fetchReport(showLoading: true);
    if (availableModels.isEmpty) {
      await _loadModelNames();
    }
  }

  Future<void> fetchReport({bool showLoading = true}) async {
    final currentRange = rangeLabel;
    final filter = _selectedModelsFilter();
    final previousDetail = detail.value;

    try {
      if (showLoading) {
        isLoading.value = true;
      }
      errorMessage.value = '';
      final data = await getRetestRateReportUseCase(
        modelSerial: _modelSerial,
        range: currentRange,
        model: filter,
      );
      detail.value = data;
      lastUpdated.value = DateTime.now();

      if (data.hasData) {
        final changedCells = _identifyChangedCells(previousDetail, data);
        _setHighlightKeys(changedCells);
      } else {
        _setHighlightKeys(const <String>{});
      }
    } catch (error) {
      errorMessage.value = friendlyErrorMessage(error);
      detail.value = TERetestDetailEntity.empty();
      _setHighlightKeys(const <String>{});
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
      _scheduleAutoRefresh();
    }
  }

  Future<void> refreshModelNames() async {
    await _loadModelNames();
  }

  void setModelSerial(String serial) {
    _modelSerial = _normalizeModelSerial(serial);
  }

  void setDateRange({required DateTime start, required DateTime end}) {
    final normalizedStart = _applyStartTime(start);
    final normalizedEnd = _applyEndTime(end);
    if (!normalizedEnd.isAfter(normalizedStart)) {
      endDate.value = _applyEndTime(normalizedStart);
      startDate.value = normalizedStart;
      return;
    }
    startDate.value = normalizedStart;
    endDate.value = normalizedEnd;
  }

  void setSelectedModels(Iterable<String> models) {
    final normalized = models
        .map((model) => model.trim())
        .where((model) => model.isNotEmpty)
        .toList();
    selectedModels.assignAll(LinkedHashSet<String>.from(normalized));
  }

  void clearSelectedModels() {
    selectedModels.clear();
  }

  void updateSearch(String query) {
    _searchQuery.value = query.trim();
  }

  String friendlyErrorMessage(Object error) {
    if (_isNetworkError(error)) {
      return _networkIssueMessage;
    }
    return error.toString();
  }

  bool _isNetworkError(Object error) {
    if (error is SocketException) {
      return true;
    }
    final description = error.toString();
    return description.contains('SocketException') ||
        description.contains('Failed host lookup');
  }

  bool isNetworkError(Object error) => _isNetworkError(error);

  String formatShiftLabel(int index) => index.isEven ? 'Day' : 'Night';

  String? buildRangeLabelForCell({
    required String dateKey,
    required bool isDayShift,
  }) {
    final date = _parseDateKey(dateKey);
    if (date == null) return null;

    final dayStart = DateTime(date.year, date.month, date.day, 7, 30);
    final dayEnd = DateTime(date.year, date.month, date.day, 19, 30);
    if (isDayShift) {
      return '${_rangeFormatter.format(dayStart)} - ${_rangeFormatter.format(dayEnd)}';
    }

    final nightStart = dayEnd;
    final nightEnd = nightStart.add(const Duration(hours: 12));
    return '${_rangeFormatter.format(nightStart)} - ${_rangeFormatter.format(nightEnd)}';
  }

  Future<TEErrorDetailEntity?> fetchErrorDetailForCell({
    required String dateKey,
    required bool isDayShift,
    required String modelName,
    required String groupName,
  }) async {
    final dateParam = _formatDateForApi(dateKey);
    final shiftParam = isDayShift ? 'D' : 'N';
    final encodedDate = Uri.encodeComponent(dateParam);
    final encodedShift = Uri.encodeComponent(shiftParam);
    final encodedModel = Uri.encodeComponent(modelName);
    final encodedGroup = Uri.encodeComponent(groupName);
    final apiPath =
        'api/nvidia/temanagement/TEManagement/RetestRateErrorDetail?date=$encodedDate&shift=$encodedShift&model=$encodedModel&group=$encodedGroup';
    debugPrint('[TERetestRate] GET $apiPath');
    return getRetestRateErrorDetailUseCase(
      date: dateParam,
      shift: shiftParam,
      model: modelName,
      group: groupName,
    );
  }

  String _formatDateString(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return cleaned;
    }
    try {
      if (cleaned.length == 8) {
        final year = int.parse(cleaned.substring(0, 4));
        final month = int.parse(cleaned.substring(4, 6));
        final day = int.parse(cleaned.substring(6, 8));
        return _rangeFormatter
            .format(DateTime(year, month, day, 0, 0))
            .split(' ')
            .first;
      }
      final parsed = DateTime.tryParse(cleaned);
      if (parsed != null) {
        return _rangeFormatter.format(parsed).split(' ').first;
      }
    } catch (_) {}
    return cleaned;
  }

  DateTime? _parseDateKey(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return null;
    }

    if (cleaned.length == 8 && int.tryParse(cleaned) != null) {
      final year = int.parse(cleaned.substring(0, 4));
      final month = int.parse(cleaned.substring(4, 6));
      final day = int.parse(cleaned.substring(6, 8));
      return DateTime(year, month, day);
    }

    try {
      return DateFormat('yyyy/MM/dd').parse(cleaned);
    } catch (_) {
      return DateTime.tryParse(cleaned);
    }
  }

  String _formatDateForApi(String raw) {
    final parsed = _parseDateKey(raw);
    if (parsed != null) {
      return _dateFormatter.format(parsed);
    }

    final cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return cleaned;
    }

    try {
      final parsedAlt = DateTime.parse(cleaned);
      return _dateFormatter.format(parsedAlt);
    } catch (_) {
      return cleaned;
    }
  }

  Set<String> _identifyChangedCells(
    TERetestDetailEntity previous,
    TERetestDetailEntity current,
  ) {
    if (!current.hasData) {
      return <String>{};
    }

    if (!previous.hasData) {
      return <String>{};
    }

    final result = <String>{};
    final snapshot = _buildSnapshot(previous);
    final totalColumns = current.dates.length * 2;

    for (final row in current.rows) {
      final previousGroups = snapshot[row.modelName];
      for (final groupName in row.groupNames) {
        final previousMetrics = previousGroups?[groupName];
        final rateValues = row.retestRate[groupName] ?? const <double?>[];
        final inputValues = row.input[groupName] ?? const <int?>[];
        final firstFailValues = row.firstFail[groupName] ?? const <int?>[];
        final retestFailValues = row.retestFail[groupName] ?? const <int?>[];
        final passValues = row.pass[groupName] ?? const <int?>[];

        for (var index = 0; index < totalColumns; index++) {
          final rate = _valueAt(rateValues, index);
          final input = _valueAt(inputValues, index);
          final firstFail = _valueAt(firstFailValues, index);
          final retestFail = _valueAt(retestFailValues, index);
          final pass = _valueAt(passValues, index);

          var changed = false;
          if (previousMetrics == null) {
            changed = true;
          } else {
            if (_doubleChanged(rate, previousMetrics.rateAt(index))) {
              changed = true;
            } else if (input != previousMetrics.inputAt(index) ||
                firstFail != previousMetrics.firstFailAt(index) ||
                retestFail != previousMetrics.retestFailAt(index) ||
                pass != previousMetrics.passAt(index)) {
              changed = true;
            }
          }

          if (changed) {
            result.add(buildRetestCellKey(row.modelName, groupName, index));
          }
        }
      }
    }

    return result;
  }

  Map<String, Map<String, _RetestGroupSnapshot>> _buildSnapshot(
    TERetestDetailEntity detail,
  ) {
    final result = <String, Map<String, _RetestGroupSnapshot>>{};
    if (!detail.hasData) {
      return result;
    }

    for (final row in detail.rows) {
      final groups = <String, _RetestGroupSnapshot>{};
      for (final groupName in row.groupNames) {
        groups[groupName] = _RetestGroupSnapshot(
          retestRate:
              List<double?>.of(row.retestRate[groupName] ?? const <double?>[]),
          input: List<int?>.of(row.input[groupName] ?? const <int?>[]),
          firstFail: List<int?>.of(row.firstFail[groupName] ?? const <int?>[]),
          retestFail: List<int?>.of(row.retestFail[groupName] ?? const <int?>[]),
          pass: List<int?>.of(row.pass[groupName] ?? const <int?>[]),
        );
      }
      result[row.modelName] = groups;
    }

    return result;
  }

  void _setHighlightKeys(Set<String> keys) {
    highlightCells.value = Set<String>.of(keys);
    _highlightClearTimer?.cancel();
    if (keys.isEmpty) {
      _highlightClearTimer = null;
      return;
    }

    _highlightClearTimer = Timer(const Duration(seconds: 2), () {
      highlightCells.value = <String>{};
      _highlightClearTimer = null;
    });
  }

  T? _valueAt<T>(List<T?> values, int index) {
    if (index < 0 || index >= values.length) {
      return null;
    }
    return values[index];
  }

  bool _doubleChanged(double? current, double? previous) {
    if (current == null && previous == null) {
      return false;
    }
    if (current == null || previous == null) {
      return true;
    }
    return (current - previous).abs() > 0.0001;
  }

  Future<void> _loadModelNames() async {
    try {
      final names = await getModelNamesUseCase(modelSerial: _modelSerial);
      if (names.isNotEmpty) {
        availableModels.assignAll(names);
      }
    } catch (_) {}
  }

  String _normalizeModelSerial(String value) {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.isEmpty) {
      return 'SWITCH';
    }
    return trimmed;
  }

  String _selectedModelsFilter() {
    if (selectedModels.isEmpty) {
      return '';
    }
    return selectedModels.join(',');
  }

  DateTime _applyStartTime(DateTime value) =>
      DateTime(value.year, value.month, value.day, 7, 30);

  DateTime _applyEndTime(DateTime value) =>
      DateTime(value.year, value.month, value.day, 19, 30);

  void _scheduleAutoRefresh() {
    if (isClosed) {
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;
      return;
    }

    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer(_autoRefreshInterval, () async {
      if (isClosed) {
        return;
      }
      await fetchReport(showLoading: false);
    });
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    _highlightClearTimer?.cancel();
    _highlightClearTimer = null;
    super.onClose();
  }
}

class _RetestGroupSnapshot {
  _RetestGroupSnapshot({
    required this.retestRate,
    required this.input,
    required this.firstFail,
    required this.retestFail,
    required this.pass,
  });

  final List<double?> retestRate;
  final List<int?> input;
  final List<int?> firstFail;
  final List<int?> retestFail;
  final List<int?> pass;

  double? rateAt(int index) =>
      index >= 0 && index < retestRate.length ? retestRate[index] : null;
  int? inputAt(int index) => index >= 0 && index < input.length ? input[index] : null;
  int? firstFailAt(int index) =>
      index >= 0 && index < firstFail.length ? firstFail[index] : null;
  int? retestFailAt(int index) =>
      index >= 0 && index < retestFail.length ? retestFail[index] : null;
  int? passAt(int index) => index >= 0 && index < pass.length ? pass[index] : null;
}
