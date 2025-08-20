import 'package:get/get.dart';
import '../../../service/avi_machine_api.dart';

class PthAviController extends GetxController {
  // API input parameters
  final machineType = 'PTH_AVI';

  RxString selectedMachine = 'All'.obs;
  RxList<String> machineNames = <String>[].obs;

  RxString selectedModel = 'All'.obs;
  RxList<String> modelNames = <String>[].obs;

  RxString selectedDateTime = ''.obs;
  RxInt selectedOpTime = 30.obs;

  // API output data
  RxInt totalPass = 0.obs;
  RxInt totalFail = 0.obs;
  RxDouble yieldPercent = 0.0.obs;
  RxDouble fpr = 0.0.obs;
  RxDouble rr = 0.0.obs;
  RxDouble avgCycleTime = 0.0.obs;

  RxList<Map<String, dynamic>> outputList = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> runtimeList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    await loadMachineNames();
    await loadModelNames();
  }

  Future<void> loadMachineNames() async {
    try {
      final machines = await PthAviApi.fetchMachineNames(machineType: machineType);
      machineNames.assignAll(machines);
    } catch (e) {
      machineNames.assignAll(['All']);
    }
  }

  Future<void> loadModelNames() async {
    try {
      final models = await PthAviApi.fetchModelNames(machineName: selectedMachine.value);
      modelNames.assignAll(models);
    } catch (e) {
      modelNames.assignAll(['All']);
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      final data = await PthAviApi.fetchMonitoringData(
        machineType: machineType,
        machineName: selectedMachine.value,
        modelName: selectedModel.value,
        rangeDateTime: selectedDateTime.value,
        opTime: selectedOpTime.value,
      );

      if (data.isEmpty || data['Data'] == null) return;
      final summary = data['Data']['Summary'] ?? {};

      totalPass.value = summary['PASS'] ?? 0;
      totalFail.value = summary['FAIL'] ?? 0;
      yieldPercent.value = (summary['YR'] ?? 0).toDouble();
      fpr.value = (summary['FPR'] ?? 0).toDouble();
      rr.value = (summary['RR'] ?? 0).toDouble();

      avgCycleTime.value = data['Data']['Runtime']?['Running']?.toDouble() ?? 0.0;
      outputList.assignAll(List<Map<String, dynamic>>.from(data['Data']['Output'] ?? []));

      final machines = data['Data']['Runtime']?['RuntimeMachine'] ?? [];
      runtimeList.assignAll(List<Map<String, dynamic>>.from(machines));
    } catch (e) {
      print('[ERROR] fetchDashboardData: $e');
    }
  }

  // --- Chart Data ---
  List<String> getDateLabels() {
    return outputList.map((e) => e['SECTION'].toString()).toList();
  }

  List<int> getPassList() {
    return outputList.map((e) => (e['PASS'] ?? 0) as int).toList();
  }

  List<int> getFailList() {
    return outputList.map((e) => (e['FAIL'] ?? 0) as int).toList();
  }

  List<double> getYieldRateList() {
    return outputList.map<double>((e) {
      final yr = e['YR'];
      if (yr is num) return yr.toDouble();
      return 0.0;
    }).toList();
  }

  String getDateLabel(int index) {
    if (index >= 0 && index < outputList.length) {
      final section = outputList[index]['SECTION'];
      return section != null ? section.toString() : '';
    }
    return '';
  }
}
