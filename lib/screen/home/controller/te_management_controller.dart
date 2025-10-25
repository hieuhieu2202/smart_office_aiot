import 'dart:collection';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../model/te_management/te_report_models.dart';
import '../../../service/te_management_api.dart';

class TEManagementController extends GetxController {
  TEManagementController({
    String initialModelSerial = 'SWITCH',
    String initialModel = '',
  })  : _initialModel = initialModel,
        modelSerial = initialModelSerial.obs,
        model = initialModel.obs;

  final String _initialModel;

  final RxList<TEReportGroup> data = <TEReportGroup>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  Future<void>? _activeFetch;

  late Rx<DateTime> startDate;
  late Rx<DateTime> endDate;
  final DateFormat _fmt = DateFormat('yyyy/MM/dd HH:mm');

  final RxString modelSerial;
  final RxString model;
  final RxString quickFilter = ''.obs;
  final RxBool filterPanelOpen = false.obs;
  final RxList<String> availableModels = <String>[].obs;
  final RxList<String> selectedModels = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDate = Rx<DateTime>(DateTime(now.year, now.month, now.day, 7, 30));
    endDate = Rx<DateTime>(DateTime(now.year, now.month, now.day, 19, 30));
    if (_initialModel.trim().isNotEmpty) {
      final seeds = _initialModel
          .split(',')
          .map((e) => e.trim())
          .where((element) => element.isNotEmpty)
          .toList();
      selectedModels.assignAll(LinkedHashSet<String>.from(seeds));
    }
    fetchData();
  }

  String get range =>
      '${_fmt.format(startDate.value)} - ${_fmt.format(endDate.value)}';

  Future<void> fetchData({bool force = false}) async {
    final inFlight = _activeFetch;
    if (inFlight != null) {
      if (!force) {
        print('>> [TEManagement] Skip fetch - request already in-flight');
        return inFlight;
      }
      print('>> [TEManagement] Waiting for active fetch before forcing refresh');
      try {
        await inFlight;
      } catch (_) {}
    }

    final serial = modelSerial.value;
    final selectedFilter = selectedModelsFilter;
    final modelName = selectedFilter.isNotEmpty ? selectedFilter : model.value;
    final requestRange = range;
    final stopwatch = Stopwatch()..start();
    print(
      '>> [TEManagement] Fetch start serial=$serial model="$modelName" range="$requestRange"',
    );

    Future<void> run() async {
      try {
        isLoading.value = true;
        error.value = '';
        final res = await TEManagementApi.fetchTableDetail(
          rangeDateTime: requestRange,
          modelSerial: serial,
          model: modelName,
        );
        final parsed = res
            .where((group) => group.isNotEmpty)
            .map((group) => TEReportGroup.fromMaps(group))
            .where((group) => group.hasData)
            .toList();
        data.value = parsed;
        final names = parsed
            .map((group) => group.modelName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        availableModels.assignAll(names);
        if (selectedModels.isNotEmpty) {
          final filteredSelection = LinkedHashSet<String>.from(selectedModels)
            ..retainAll(names);
          selectedModels.assignAll(filteredSelection.toList());
        }
        model.value = selectedModelsFilter;
        stopwatch.stop();
        print(
          '>> [TEManagement] Fetch success serial=$serial model="$modelName" range="$requestRange" '
          'groups=${res.length} elapsed=${stopwatch.elapsedMilliseconds}ms',
        );
      } catch (e, stack) {
        stopwatch.stop();
        error.value = e.toString();
        print(
          '>> [TEManagement] Fetch error serial=$serial model="$modelName" range="$requestRange" err=$e',
        );
        print(stack);
      } finally {
        isLoading.value = false;
      }
    }

    final future = run();
    _activeFetch = future;
    try {
      await future;
    } finally {
      if (identical(_activeFetch, future)) {
        _activeFetch = null;
      }
    }
  }

  void updateQuickFilter(String v) => quickFilter.value = v;

  void openFilterPanel() => filterPanelOpen.value = true;
  void closeFilterPanel() => filterPanelOpen.value = false;

  void applyFilter(
    DateTime start,
    DateTime end,
    String serial,
    String modelName,
  ) {
    startDate.value = start;
    endDate.value = end;
    modelSerial.value = serial;
    model.value = modelName;
    if (modelName.trim().isNotEmpty) {
      final next = modelName
          .split(',')
          .map((e) => e.trim())
          .where((element) => element.isNotEmpty)
          .toList();
      selectedModels.assignAll(LinkedHashSet<String>.from(next).toList());
    } else {
      selectedModels.clear();
    }
    fetchData(force: true);
    closeFilterPanel();
  }

  void setDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
  }

  void setSelectedModels(List<String> models) {
    final unique = LinkedHashSet<String>.from(
      models.map((e) => e.trim()).where((element) => element.isNotEmpty),
    );
    selectedModels.assignAll(unique.toList());
    model.value = selectedModelsFilter;
  }

  void clearSelectedModels() {
    selectedModels.clear();
    model.value = '';
  }

  List<String> get selectedModelList {
    final unique = LinkedHashSet<String>.from(selectedModels);
    return unique.toList();
  }

  List<String> get availableModelList => List<String>.from(availableModels);

  String get selectedModelsFilter {
    if (selectedModels.isEmpty) return '';
    final unique = LinkedHashSet<String>.from(selectedModels);
    return unique.join(',');
  }

  List<TEReportGroup> get filteredData {
    final q = quickFilter.value.trim().toLowerCase();
    final selection = LinkedHashSet<String>.from(selectedModels);
    final bool hasSelection = selection.isNotEmpty;
    if (q.isEmpty) {
      if (!hasSelection) return data;
      return data.where((group) => selection.contains(group.modelName)).toList();
    }

    final List<TEReportGroup> result = [];
    for (final group in data) {
      if (hasSelection && !selection.contains(group.modelName)) {
        continue;
      }
      if (group.modelName.toLowerCase().contains(q)) {
        result.add(group);
        continue;
      }
      final rows = group.rows.where((row) => row.matches(q)).toList();
      if (rows.isNotEmpty) {
        result.add(group.copyWith(rows: rows));
      }
    }
    if (!hasSelection && result.isEmpty) {
      return data
          .where((group) => group.rows.any((row) => row.matches(q)))
          .map((group) =>
              group.copyWith(rows: group.rows.where((row) => row.matches(q)).toList()))
          .where((group) => group.rows.isNotEmpty)
          .toList();
    }
    return result;
  }
}
