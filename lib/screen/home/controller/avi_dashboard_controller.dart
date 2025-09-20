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
  final String defaultGroup = "ALL";
  final String defaultMachine = "ALL";
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
    loadGroups();
    fetchMonitoring(
      groupName: defaultGroup,
      machineName: defaultMachine,
      modelName: defaultModel,
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
    selectedGroup.value = defaultGroup;
    selectedMachine.value = defaultMachine;
    selectedModel.value = defaultModel;
    selectedRangeDateTime.value = getDefaultRange();
    await loadMachines(defaultGroup);
    await fetchMonitoring(
      groupName: defaultGroup,
      machineName: defaultMachine,
      modelName: defaultModel,
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
      names.removeWhere((item) => item == "ALL");
      names.insert(0, "ALL");
      groupNames.value = names;
      // Nếu chưa có selected, set về mặc định
      if (updateSelection && !groupNames.contains(selectedGroup.value)) {
        selectedGroup.value = defaultGroup;
      }
      if (updateSelection) {
        await loadMachines(selectedGroup.value);
      }
      return groupNames.toList();
    } finally {
      isGroupLoading.value = false;
    }
  }

  /// Load danh sách machine theo group
  Future<List<String>> loadMachines(String group,
      {bool updateSelection = true, String? preferredMachine}) async {
    isMachineLoading.value = true;
    try {
      final names = await PTHDashboardApi.getMachineNames(group);
      machineNames.value =
          names.isEmpty
              ? []
              : (["ALL", ...names.where((item) => item != "ALL")]);
      // Nếu chưa có selected, set về mặc định
      if (updateSelection) {
        if (!machineNames.contains(selectedMachine.value)) {
          selectedMachine.value =
              machineNames.isNotEmpty ? machineNames.first : defaultMachine;
        }
        await loadModels(group, selectedMachine.value);
      } else {
        final target = (preferredMachine != null &&
                machineNames.contains(preferredMachine))
            ? preferredMachine
            : (machineNames.isNotEmpty ? machineNames.first : null);
        if (target != null) {
          await loadModels(group, target, updateSelection: false);
        } else {
          modelNames.value = ["ALL"];
        }
      }
      return machineNames.toList();
    } finally {
      isMachineLoading.value = false;
    }
  }

  /// Load danh sách model theo group + machine
  Future<List<String>> loadModels(String group, String machine,
      {bool updateSelection = true}) async {
    isModelLoading.value = true;
    try {
      final names = await PTHDashboardApi.getModelNames(group, machine);
      modelNames.value =
          names.isEmpty
              ? ["ALL"]
              : (["ALL", ...names.where((item) => item != "ALL")]);
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
