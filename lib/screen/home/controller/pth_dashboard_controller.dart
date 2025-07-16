import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/pth_dashboard_api.dart';

class PTHDashboardController extends GetxController {
  var groupNames = <String>[].obs;
  var machineNames = <String>[].obs;
  var modelNames = <String>[].obs;

  var selectedGroup = ''.obs;
  var selectedMachine = ''.obs;
  var selectedModel = ''.obs;
  var selectedRangeDateTime = ''.obs;

  var isLoading = false.obs;
  var monitoringData = {}.obs;

  final String defaultGroup = "PACKING_AVI";
  final String defaultMachine = "ALL";
  final String defaultModel = "ALL";
  late final String defaultRange ;
  final int defaultOpTime = 30;

  @override
  void onInit() {
    super.onInit();
    loadGroups();
    defaultRange= getDefaultRange();
    fetchMonitoring(
      groupName: defaultGroup,
      machineName: defaultMachine,
      modelName: defaultModel,
      rangeDateTime: defaultRange,
      opTime: defaultOpTime,
    );
  }

  String getDefaultRange() {
    final now = DateTime.now();
    String formatDate=DateFormat('yyyy/MM/dd').format(now);
    return "$formatDate 07:30 - $formatDate 19:30";
  }
  // Load danh sách group cho dropdown
  void loadGroups() async {
    isLoading.value = true;
    try {
      final names = await PTHDashboardApi.getGroupNames();
      names.removeWhere((item) => item == "ALL");
      names.insert(0, "ALL");
      groupNames.value = names;
      selectedGroup.value = defaultGroup;
      loadMachines(selectedGroup.value);
    } finally {
      isLoading.value = false;
    }
  }

  // Load danh sách machine theo group
  void loadMachines(String group) async {
    isLoading.value = true;
    try {
      final names = await PTHDashboardApi.getMachineNames(group);
      machineNames.value = names.isEmpty ? [] : (["ALL", ...names.where((item) => item != "ALL")]);
      selectedMachine.value = machineNames.isNotEmpty ? machineNames.first : '';
      loadModels(group, selectedMachine.value);
    } finally {
      isLoading.value = false;
    }
  }

  // Load danh sách model theo group + machine
  void loadModels(String group, String machine) async {
    isLoading.value = true;
    try {
      final names = await PTHDashboardApi.getModelNames(group, machine);
      modelNames.value = names.isEmpty ? ["ALL"] : (["ALL", ...names.where((item) => item != "ALL")]);
      // Nếu giá trị đang chọn không có trong list, mặc định về "ALL"
      selectedModel.value = modelNames.contains(selectedModel.value) ? selectedModel.value : "ALL";
    } finally {
      isLoading.value = false;
    }
  }

  // fetchMonitoring nhận cả từng tham số lẻ hoặc 1 map filters
  Future<void> fetchMonitoring({
    String? groupName,
    String? machineName,
    String? modelName,
    String? rangeDateTime,
    int? opTime,
    Map<String, dynamic>? filters, // <-- Hỗ trợ filters từ filter panel
  }) async {
    isLoading.value = true;
    try {
      // Nếu có filters truyền vào từ filter panel, dùng filters ưu tiên
      if (filters != null) {
        groupName = filters['groupName'] ?? selectedGroup.value;
        machineName = filters['machineName'] ?? selectedMachine.value;
        modelName = filters['modelName'] ?? selectedModel.value;
        rangeDateTime = filters['rangeDateTime'] ?? selectedRangeDateTime.value;
        opTime = filters['opTime'] ?? defaultOpTime;
      }
      // Cập nhật các biến selected
      selectedGroup.value = groupName ?? selectedGroup.value;
      selectedMachine.value = machineName ?? selectedMachine.value;
      selectedModel.value = modelName ?? selectedModel.value;
      selectedRangeDateTime.value = rangeDateTime ?? selectedRangeDateTime.value;

      final data = await PTHDashboardApi.getMonitoringData(
        groupName: groupName ?? defaultGroup,
        machineName: machineName ?? defaultMachine,
        modelName: modelName ?? defaultModel,
        rangeDateTime: rangeDateTime ?? defaultRange,
        opTime: opTime ?? defaultOpTime,
      );

      // DEBUG LOG
      print('[DEBUG] monitoringData (full): $data');
      print('[DEBUG] monitoringData.runtime: ${data['runtime']}');
      print('[DEBUG] monitoringData.summary: ${data['summary']}');
      print('[DEBUG] monitoringData.output: ${data['output']}');

      monitoringData.value = data;
    } catch (e) {
      Get.snackbar('Lỗi lấy dữ liệu', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
