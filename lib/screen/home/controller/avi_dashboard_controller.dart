import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/aoivi_dashboard_api.dart';

class AOIVIDashboardController extends GetxController {
  var groupNames = <String>[].obs;
  var machineNames = <String>[].obs;
  var modelNames = <String>[].obs;

  var selectedGroup = ''.obs;
  var selectedMachine = ''.obs;
  var selectedModel = ''.obs;
  var selectedRangeDateTime = ''.obs;

  var isLoading = false.obs;
  var isGroupLoading = false.obs;
  var isMachineLoading = false.obs;
  var isModelLoading = false.obs;
  var monitoringData = Rxn<Map>(); // Dùng Rxn để tránh lỗi null

  // Thông tin mặc định
  String defaultGroup = '';
  String defaultMachine = '';
  final String defaultModel = "ALL";
  late final String defaultRange;
  final int defaultOpTime = 30;

  // Thời gian cập nhật gần nhất
  var lastUpdateTime = ''.obs;

  @override
  void onInit() {
    super.onInit();
    defaultRange = getDefaultRange();
    selectedGroup.value = defaultGroup;
    selectedMachine.value = defaultMachine;
    selectedModel.value = defaultModel;
    selectedRangeDateTime.value = defaultRange;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await loadGroups();
    if (selectedGroup.value.isEmpty || selectedMachine.value.isEmpty) {
      return;
    }
    await fetchMonitoring(
      groupName: selectedGroup.value,
      machineName: selectedMachine.value,
      modelName: selectedModel.value,
      rangeDateTime: defaultRange,
      opTime: defaultOpTime,
      showLoading: true,
    );
  }

  /// Trả về khung giờ mặc định: hôm nay 07:30 - 19:30
  String getDefaultRange() {
    final now = DateTime.now();
    String formatDate = DateFormat('yyyy/MM/dd').format(now);
    return "$formatDate 07:30 - $formatDate 19:30";
  }

  /// Reset filter về giá trị mặc định
  Future<void> resetFilters() async {
    selectedRangeDateTime.value = getDefaultRange();
    await loadGroups(updateSelection: false);
    if (groupNames.contains(defaultGroup)) {
      selectedGroup.value = defaultGroup;
    } else if (groupNames.isNotEmpty) {
      selectedGroup.value = groupNames.first;
      defaultGroup = selectedGroup.value;
    } else {
      selectedGroup.value = '';
      defaultGroup = '';
    }

    await loadMachines(
      selectedGroup.value,
      preferredMachine: defaultMachine,
    );

    if (machineNames.contains(defaultMachine)) {
      selectedMachine.value = defaultMachine;
    } else if (machineNames.isNotEmpty) {
      selectedMachine.value = machineNames.first;
      defaultMachine = selectedMachine.value;
    } else {
      selectedMachine.value = '';
      defaultMachine = '';
    }

    if (modelNames.contains(defaultModel)) {
      selectedModel.value = defaultModel;
    } else if (modelNames.isNotEmpty) {
      selectedModel.value = modelNames.first;
    } else {
      selectedModel.value = defaultModel;
    }

    await fetchMonitoring(
      groupName: selectedGroup.value,
      machineName: selectedMachine.value,
      modelName: selectedModel.value,
      rangeDateTime: selectedRangeDateTime.value,
      opTime: defaultOpTime,
      showLoading: true,
    );
  }

  /// Load danh sách group
  Future<List<String>> loadGroups({bool updateSelection = true}) async {
    isGroupLoading.value = true;
    try {
      final names = await PTHDashboardApi.getGroupNames();
      final filtered = names
          .where((item) => item.trim().isNotEmpty && item != "ALL")
          .toList();
      groupNames.value = filtered;

      if (!updateSelection) {
        return groupNames.toList();
      }

      if (filtered.isEmpty) {
        selectedGroup.value = '';
        machineNames.value = [];
        selectedMachine.value = '';
        modelNames.value = [defaultModel];
        selectedModel.value = defaultModel;
        return groupNames.toList();
      }

      String resolvedGroup = selectedGroup.value;
      if (resolvedGroup.isEmpty || !filtered.contains(resolvedGroup)) {
        resolvedGroup = filtered.first;
      }

      selectedGroup.value = resolvedGroup;
      if ((defaultGroup.isEmpty || !filtered.contains(defaultGroup)) &&
          resolvedGroup.isNotEmpty) {
        defaultGroup = resolvedGroup;
      }

      await loadMachines(resolvedGroup);
      return groupNames.toList();
    } finally {
      isGroupLoading.value = false;
    }
  }

  /// Load danh sách machine theo group
  Future<List<String>> loadMachines(String group,
      {bool updateSelection = true, String? preferredMachine}) async {
    if (group.trim().isEmpty) {
      machineNames.value = [];
      if (updateSelection) {
        selectedMachine.value = '';
        modelNames.value = [defaultModel];
        selectedModel.value = defaultModel;
      }
      return const <String>[];
    }
    isMachineLoading.value = true;
    try {
      final names = await PTHDashboardApi.getMachineNames(group);
      final filtered = names
          .where((item) => item.trim().isNotEmpty && item != "ALL")
          .toList();
      machineNames.value = filtered;

      if (filtered.isEmpty) {
        if (updateSelection) {
          selectedMachine.value = '';
          modelNames.value = [defaultModel];
          selectedModel.value = defaultModel;
        } else {
          modelNames.value = [defaultModel];
        }
        return machineNames.toList();
      }

      String? resolvedMachine = preferredMachine;
      if (resolvedMachine != null && !filtered.contains(resolvedMachine)) {
        resolvedMachine = null;
      }

      resolvedMachine ??= selectedMachine.value;

      if (resolvedMachine == null ||
          resolvedMachine.isEmpty ||
          !filtered.contains(resolvedMachine)) {
        resolvedMachine = filtered.first;
      }

      final machineToLoad = resolvedMachine!;

      if (updateSelection) {
        selectedMachine.value = machineToLoad;
        if (defaultMachine.isEmpty || !filtered.contains(defaultMachine)) {
          defaultMachine = machineToLoad;
        }
      }

      await loadModels(
        group,
        machineToLoad,
        updateSelection: updateSelection,
      );

      return machineNames.toList();
    } finally {
      isMachineLoading.value = false;
    }
  }

  /// Load danh sách model theo group + machine
  Future<List<String>> loadModels(String group, String machine,
      {bool updateSelection = true}) async {
    if (group.trim().isEmpty || machine.trim().isEmpty) {
      modelNames.value = [defaultModel];
      if (updateSelection) {
        selectedModel.value = defaultModel;
      }
      return modelNames.toList();
    }
    isModelLoading.value = true;
    try {
      final names = await PTHDashboardApi.getModelNames(group, machine);
      final filtered = names
          .where((item) => item.trim().isNotEmpty && item != defaultModel)
          .toList();
      modelNames.value =
          filtered.isEmpty ? [defaultModel] : ([defaultModel, ...filtered]);
      if (updateSelection && !modelNames.contains(selectedModel.value)) {
        selectedModel.value = modelNames.first;
      }
      return modelNames.toList();
    } finally {
      isModelLoading.value = false;
    }
  }

  /// Lấy dữ liệu dashboard (gọi khi đổi filter hoặc tự động)
  Future<void> fetchMonitoring({
    String? groupName,
    String? machineName,
    String? modelName,
    String? rangeDateTime,
    int? opTime,
    Map<String, dynamic>? filters,
    bool showLoading = true,
  }) async {
    if (showLoading) isLoading.value = true;
    try {
      // Ưu tiên filter nếu có
      if (filters != null) {
        groupName =
            (filters['groupName'] as String?)?.trim().isNotEmpty == true
                ? filters['groupName']
                : selectedGroup.value;
        machineName =
            (filters['machineName'] as String?)?.trim().isNotEmpty == true
                ? filters['machineName']
                : selectedMachine.value;
        modelName =
            (filters['modelName'] as String?)?.trim().isNotEmpty == true
                ? filters['modelName']
                : selectedModel.value;
        final filterRange = (filters['rangeDateTime'] as String?)?.trim();
        rangeDateTime =
            (filterRange != null && filterRange.isNotEmpty)
                ? filterRange
                : selectedRangeDateTime.value;
        opTime = filters['opTime'] ?? defaultOpTime;
      }
      // Cập nhật selected
      selectedGroup.value = groupName ?? selectedGroup.value;
      selectedMachine.value = machineName ?? selectedMachine.value;
      selectedModel.value = modelName ?? selectedModel.value;
      selectedRangeDateTime.value =
          rangeDateTime ?? selectedRangeDateTime.value;

      if (selectedGroup.value.trim().isEmpty ||
          selectedMachine.value.trim().isEmpty) {
        monitoringData.value = null;
        return;
      }

      final data = await PTHDashboardApi.getMonitoringData(
        groupName: selectedGroup.value,
        machineName: selectedMachine.value,
        modelName: selectedModel.value,
        rangeDateTime: selectedRangeDateTime.value,
        opTime: opTime ?? defaultOpTime,
      );
      monitoringData.value = data;
      // Ghi nhận thời gian cập nhật gần nhất
      lastUpdateTime.value = DateFormat('HH:mm:ss').format(DateTime.now());
      if (filters != null) {
        await loadMachines(selectedGroup.value,
            preferredMachine: selectedMachine.value);
      }
    } catch (e) {
      Get.snackbar('Lỗi lấy dữ liệu', e.toString());
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  /// Lấy dữ liệu monitoring theo trạng thái pass, fail
  Future<List<Map<String, dynamic>>> getMonitoringDetailByStatus({
    required String status,
    String? groupName,
    String? machineName,
    String? modelName,
    String? rangeDateTime,
  }) async {
    try {
      final res = await PTHDashboardApi.getMonitoringDetailByStatus(
        status: status,
        groupName: groupName ?? selectedGroup.value,
        machineName: machineName ?? selectedMachine.value,
        modelName: modelName ?? selectedModel.value,
        rangeDateTime: rangeDateTime ?? selectedRangeDateTime.value,
      );
      return res;
    } catch (e) {
      Get.snackbar('Lỗi lấy dữ liệu', e.toString());
      return [];
    }
  }
}
