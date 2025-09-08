import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/aoivi_dashboard_api.dart';

class AOIVIDashboardController extends GetxController {
  AOIVIDashboardController({this.defaultGroup = "ALL"});

  // Thông tin mặc định
  final String defaultGroup;
  final String defaultMachine = "ALL";
  final String defaultModel = "ALL";
  late final String defaultRange;
  final int defaultOpTime = 30;

  var machineNames = <String>[].obs;
  var modelNames = <String>[].obs;

  var selectedGroup = ''.obs;
  var selectedMachine = ''.obs;
  var selectedModel = ''.obs;
  var selectedRangeDateTime = ''.obs;

  var isLoading = false.obs;
  // Loading trạng thái cho việc tải filter (group/machine/model)
  var isFilterLoading = false.obs;
  var monitoringData = Rxn<Map>(); // Dùng Rxn để tránh lỗi null

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
    loadMachines(selectedGroup.value);
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
  void resetFilters() {
    selectedMachine.value = defaultMachine;
    selectedModel.value = defaultModel;
    selectedRangeDateTime.value = getDefaultRange();
    fetchMonitoring(
      machineName: defaultMachine,
      modelName: defaultModel,
      rangeDateTime: getDefaultRange(),
      opTime: defaultOpTime,
      showLoading: true,
    );
  }

  /// Load danh sách machine theo group
  Future<void> loadMachines(String group) async {
    isFilterLoading.value = true;
    try {
      final names = await PTHDashboardApi.getMachineNames(group);
      machineNames.value =
          names.isEmpty
              ? []
              : (["ALL", ...names.where((item) => item != "ALL")]);
      // Nếu chưa có selected, set về mặc định
      if (!machineNames.contains(selectedMachine.value)) {
        selectedMachine.value =
            machineNames.isNotEmpty ? machineNames.first : defaultMachine;
      }
      await loadModels(group, selectedMachine.value);
    } finally {
      isFilterLoading.value = false;
    }
  }

  /// Load danh sách model theo group + machine
  Future<void> loadModels(String group, String machine) async {
    isFilterLoading.value = true;
    try {
      final names = await PTHDashboardApi.getModelNames(group, machine);
      modelNames.value =
          names.isEmpty
              ? ["ALL"]
              : (["ALL", ...names.where((item) => item != "ALL")]);
      if (!modelNames.contains(selectedModel.value)) {
        selectedModel.value = modelNames.first;
      }
    } finally {
      isFilterLoading.value = false;
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
        groupName = filters['groupName'] ?? selectedGroup.value;
        machineName = filters['machineName'] ?? selectedMachine.value;
        modelName = filters['modelName'] ?? selectedModel.value;
        rangeDateTime = filters['rangeDateTime'] ?? selectedRangeDateTime.value;
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
