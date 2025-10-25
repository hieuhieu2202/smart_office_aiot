import 'dart:async';
import 'dart:collection';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/te_report.dart';
import '../../domain/usecases/get_error_detail.dart';
import '../../domain/usecases/get_model_names.dart';
import '../../domain/usecases/get_te_report.dart';

class TEManagementController extends GetxController {
  TEManagementController({
    required this.getReportUseCase,
    required this.getModelNamesUseCase,
    required this.getErrorDetailUseCase,
    this.initialModelSerial = 'SWITCH',
    this.initialModel = '',
    this.pollingInterval = const Duration(seconds: 10),
  });

  final GetTEReportUseCase getReportUseCase;
  final GetModelNamesUseCase getModelNamesUseCase;
  final GetErrorDetailUseCase getErrorDetailUseCase;

  final String initialModelSerial;
  final String initialModel;
  final Duration pollingInterval;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxList<String> selectedModels = <String>[].obs;
  final RxList<String> availableModels = <String>[].obs;
  final Rx<DateTime> lastUpdated = DateTime.now().obs;

  final Rx<DateTime> startDate = Rx<DateTime>(_todayStart());
  final Rx<DateTime> endDate = Rx<DateTime>(_todayEnd());

  final DateFormat _rangeFormatter = DateFormat('yyyy/MM/dd HH:mm');

  Timer? _pollTimer;
  Future<void>? _activeFetch;

  final List<TEGroupedRows> _groupOrder = [];
  final List<TEGroupedRows> _filteredOrder = [];
  Map<String, TEReportRowEntity> _rowsByKey = {};
  final Map<String, DateTime> _rowUpdateTimes = {};

  String _modelSerial = 'SWITCH';

  List<TEGroupedRows> get visibleGroups => List.unmodifiable(_filteredOrder);

  String get rangeLabel =>
      '${_rangeFormatter.format(startDate.value)} - ${_rangeFormatter.format(endDate.value)}';

  bool get hasError => errorMessage.isNotEmpty;

  static DateTime _todayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 7, 30);
  }

  static DateTime _todayEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 19, 30);
  }

  @override
  void onInit() {
    super.onInit();
    _modelSerial = initialModelSerial.trim().isEmpty
        ? 'SWITCH'
        : initialModelSerial.trim().toUpperCase();
    if (initialModel.trim().isNotEmpty) {
      final seeds = initialModel
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      selectedModels.assignAll(LinkedHashSet<String>.from(seeds));
    }
    _fetchInitial();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> _fetchInitial() async {
    await fetchData(showLoading: true, fromPolling: false);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollingInterval, (_) {
      fetchData(showLoading: false, fromPolling: true);
    });
  }

  Future<void> fetchData({required bool showLoading, required bool fromPolling}) async {
    if (_activeFetch != null) {
      if (!fromPolling) {
        await _activeFetch;
      } else {
        return;
      }
    }

    final selectedFilter = _selectedModelsFilter();
    final model = selectedFilter.isNotEmpty ? selectedFilter : initialModel.trim();
    final currentRange = rangeLabel;

    Future<void> runner() async {
      try {
        if (showLoading) {
          isLoading.value = true;
        }
        if (!fromPolling) {
          errorMessage.value = '';
        }
        final groups = await getReportUseCase(
          modelSerial: _modelSerial,
          range: currentRange,
          model: model,
        );
        _applyData(groups, fromPolling: fromPolling);
        lastUpdated.value = DateTime.now();
        if (!fromPolling) {
          await _ensureModelNames();
        }
      } catch (e) {
        if (!fromPolling) {
          errorMessage.value = e.toString();
        }
      } finally {
        if (showLoading) {
          isLoading.value = false;
        }
      }
    }

    final future = runner();
    _activeFetch = future;
    await future;
    if (identical(_activeFetch, future)) {
      _activeFetch = null;
    }
  }

  Future<void> _ensureModelNames() async {
    try {
      final names = await getModelNamesUseCase(modelSerial: _modelSerial);
      if (names.isNotEmpty) {
        availableModels.assignAll(names);
      }
    } catch (_) {}
  }

  void _applyData(List<TEReportGroupEntity> groups, {required bool fromPolling}) {
    final newRows = <String, TEReportRowEntity>{};
    final newOrder = <TEGroupedRows>[];

    for (final group in groups) {
      final keys = <String>[];
      for (final row in group.rows) {
        final key = _buildRowKey(row.modelName, row.groupName);
        newRows[key] = row;
        keys.add(key);
      }
      newOrder.add(TEGroupedRows(modelName: group.modelName, rowKeys: keys));
    }

    final removedKeys = _rowsByKey.keys
        .where((key) => !newRows.containsKey(key))
        .toList();
    if (removedKeys.isNotEmpty) {
      for (final key in removedKeys) {
        _rowUpdateTimes.remove(key);
      }
    }
    final changedKeys = <String>{};
    newRows.forEach((key, row) {
      final current = _rowsByKey[key];
      if (current == null || !current.contentEquals(row)) {
        changedKeys.add(key);
      }
    });

    final orderChanged = !_ordersEqual(newOrder, _groupOrder) || removedKeys.isNotEmpty;

    _rowsByKey = newRows;
    _groupOrder
      ..clear()
      ..addAll(newOrder);

    for (final key in changedKeys) {
      _rowUpdateTimes[key] = DateTime.now();
    }

    _applyFilters(emitUpdate: orderChanged || !fromPolling);

    if (!orderChanged) {
      for (final key in changedKeys) {
        update(['row_$key']);
      }
    }

    final currentNames = <String>{
      for (final group in _groupOrder)
        if (group.modelName.trim().isNotEmpty) group.modelName.trim(),
    };
    if (currentNames.isNotEmpty) {
      final merged = <String>{...availableModels.toList(), ...currentNames}.toList()
        ..sort();
      availableModels.assignAll(merged);
    }
  }

  void _applyFilters({bool emitUpdate = true}) {
    final query = searchQuery.value.trim().toLowerCase();
    final selection = selectedModels
        .map((model) => model.trim().toLowerCase())
        .where((model) => model.isNotEmpty)
        .toSet();

    final filtered = <TEGroupedRows>[];
    for (final group in _groupOrder) {
      if (selection.isNotEmpty && !selection.contains(group.modelName.toLowerCase())) {
        continue;
      }
      final visibleKeys = <String>[];
      for (final key in group.rowKeys) {
        final row = _rowsByKey[key];
        if (row == null) continue;
        if (query.isEmpty || _matches(row, query)) {
          visibleKeys.add(key);
        }
      }
      if (visibleKeys.isNotEmpty) {
        filtered.add(TEGroupedRows(modelName: group.modelName, rowKeys: visibleKeys));
      }
    }

    _filteredOrder
      ..clear()
      ..addAll(filtered);

    if (emitUpdate) {
      update(['table']);
    }
  }

  bool _matches(TEReportRowEntity row, String query) {
    if (row.modelName.toLowerCase().contains(query)) return true;
    if (row.groupName.toLowerCase().contains(query)) return true;
    final values = [
      row.wipQty.toString(),
      row.input.toString(),
      row.firstFail.toString(),
      row.repairQty.toString(),
      row.firstPass.toString(),
      row.repairPass.toString(),
      row.pass.toString(),
      row.totalPass.toString(),
      row.fpr.toStringAsFixed(2),
      row.spr.toStringAsFixed(2),
      row.rr.toStringAsFixed(2),
    ];
    return values.any((value) => value.toLowerCase().contains(query));
  }

  String _selectedModelsFilter() {
    if (selectedModels.isEmpty) return '';
    final unique = LinkedHashSet<String>.from(selectedModels);
    return unique.join(',');
  }

  String _buildRowKey(String model, String group) {
    return '${model.trim()}::${group.trim()}';
  }

  bool _ordersEqual(List<TEGroupedRows> a, List<TEGroupedRows> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  TEReportRowEntity? rowByKey(String key) => _rowsByKey[key];

  DateTime? rowLastUpdated(String key) => _rowUpdateTimes[key];

  void updateSearch(String value) {
    searchQuery.value = value;
    _applyFilters();
  }

  void setDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    fetchData(showLoading: true, fromPolling: false);
  }

  void resetDateRange() {
    startDate.value = _todayStart();
    endDate.value = _todayEnd();
    fetchData(showLoading: true, fromPolling: false);
  }

  void setSelectedModels(List<String> models) {
    final unique = LinkedHashSet<String>.from(
      models.map((value) => value.trim()).where((value) => value.isNotEmpty),
    );
    selectedModels.assignAll(unique.toList());
    _applyFilters();
    fetchData(showLoading: true, fromPolling: false);
  }

  void clearSelectedModels() {
    selectedModels.clear();
    _applyFilters();
    fetchData(showLoading: true, fromPolling: false);
  }

  void applyFilters({
    DateTime? start,
    DateTime? end,
    List<String>? models,
    bool clearModels = false,
  }) {
    if (start != null) {
      startDate.value = start;
    }
    if (end != null) {
      endDate.value = end;
    }
    if (clearModels) {
      selectedModels.clear();
    }
    if (models != null) {
      final unique = LinkedHashSet<String>.from(
        models.map((value) => value.trim()).where((value) => value.isNotEmpty),
      );
      selectedModels.assignAll(unique.toList());
    }
    _applyFilters();
    fetchData(showLoading: true, fromPolling: false);
  }

  Future<TEErrorDetailEntity?> fetchErrorDetail({required String rowKey}) async {
    final row = _rowsByKey[rowKey];
    if (row == null) return null;
    return getErrorDetailUseCase(
      range: rangeLabel,
      model: row.modelName,
      group: row.groupName,
    );
  }
}

class TEGroupedRows {
  TEGroupedRows({required this.modelName, required this.rowKeys});

  final String modelName;
  final List<String> rowKeys;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TEGroupedRows) return false;
    if (modelName != other.modelName) return false;
    if (rowKeys.length != other.rowKeys.length) return false;
    for (var i = 0; i < rowKeys.length; i++) {
      if (rowKeys[i] != other.rowKeys[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([modelName, ...rowKeys]);
}
