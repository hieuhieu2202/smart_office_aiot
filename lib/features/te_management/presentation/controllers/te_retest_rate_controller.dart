import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  final Rx<DateTime> startDate = DateTime.now().obs;
  final Rx<DateTime> endDate = DateTime.now().obs;

  late String _modelSerial;

  final DateFormat _rangeFormatter = DateFormat('yyyy/MM/dd HH:mm');
  final DateFormat _dateFormatter = DateFormat('yyyy/MM/dd');

  String get rangeLabel =>
      '${_rangeFormatter.format(startDate.value)} - ${_rangeFormatter.format(endDate.value)}';

  bool get hasError => errorMessage.isNotEmpty;

  bool get canExport => detail.value.hasData;

  List<String> get formattedDates =>
      detail.value.dates.map(_formatDateString).toList(growable: false);

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

  Future<void> initialize() async {
    await fetchReport(showLoading: true);
    if (availableModels.isEmpty) {
      await _loadModelNames();
    }
  }

  Future<void> fetchReport({bool showLoading = true}) async {
    final currentRange = rangeLabel;
    final filter = _selectedModelsFilter();

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
    } catch (error) {
      errorMessage.value = error.toString();
      detail.value = TERetestDetailEntity.empty();
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
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

  Future<TERetestExportResult> exportToCsv() async {
    final currentDetail = detail.value;
    if (!currentDetail.hasData) {
      return const TERetestExportResult(
        success: false,
        message: 'No data available to export.',
      );
    }

    final headerDates = formattedDates;
    final totalColumns = headerDates.length * 2;

    final rows = <List<String>>[];
    final header = <String>['#', 'Model Name', 'Group Name'];
    for (final date in headerDates) {
      header.add('$date Day');
      header.add('$date Night');
    }
    rows.add(header);

    var index = 1;
    for (final row in currentDetail.rows) {
      var firstGroup = true;
      for (final group in row.groupNames) {
        final rr = row.retestRate[group] ?? const <double?>[];
        final cells = <String>[];
        cells.add(firstGroup ? index.toString() : '');
        cells.add(firstGroup ? row.modelName : '');
        cells.add(group);
        for (var i = 0; i < totalColumns; i++) {
          final value = i < rr.length ? rr[i] : null;
          if (value == null) {
            cells.add('N/A');
          } else {
            cells.add('${value.toStringAsFixed(2)}%');
          }
        }
        rows.add(cells);
        firstGroup = false;
      }
      index++;
    }

    final buffer = StringBuffer();
    for (final line in rows) {
      buffer.writeln(line.map(_escapeCsv).join(','));
    }

    final output = buffer.toString().trim();
    if (output.isEmpty) {
      return const TERetestExportResult(
        success: false,
        message: 'No data available to export.',
      );
    }

    try {
      await Clipboard.setData(ClipboardData(text: output));
      return TERetestExportResult(
        success: true,
        message:
            'CSV copied to clipboard. Paste into a spreadsheet to save the file.',
      );
    } catch (error) {
      return TERetestExportResult(
        success: false,
        message: 'Failed to copy CSV to clipboard: $error',
      );
    }
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

  String _escapeCsv(String input) {
    final sanitized = input.replaceAll('"', '""');
    if (sanitized.contains(',') || sanitized.contains('\n') ||
        sanitized.contains('"')) {
      return '"$sanitized"';
    }
    return sanitized;
  }
}

class TERetestExportResult {
  const TERetestExportResult({required this.success, required this.message});

  final bool success;
  final String message;
}
