import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/te_management_api.dart';

class TEManagementController extends GetxController {
  TEManagementController({
    String initialModelSerial = 'SWITCH',
    String initialModel = '',
  })  : modelSerial = initialModelSerial.obs,
        model = initialModel.obs;

  final RxList<List<Map<String, dynamic>>> data = <List<Map<String, dynamic>>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  late Rx<DateTime> startDate;
  late Rx<DateTime> endDate;
  final DateFormat _fmt = DateFormat('yyyy/MM/dd HH:mm');

  final RxString modelSerial;
  final RxString model;
  final RxString quickFilter = ''.obs;
  final RxBool filterPanelOpen = false.obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDate = Rx<DateTime>(DateTime(now.year, now.month, now.day, 7, 30));
    endDate = Rx<DateTime>(DateTime(now.year, now.month, now.day, 19, 30));
    fetchData();
  }

  String get range =>
      '${_fmt.format(startDate.value)} - ${_fmt.format(endDate.value)}';

  Future<void> fetchData() async {
    try {
      isLoading.value = true;
      error.value = '';
      final res = await TEManagementApi.fetchTableDetail(
        rangeDateTime: range,
        modelSerial: modelSerial.value,
        model: model.value,
      );
      data.value = res;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
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
    fetchData();
    closeFilterPanel();
  }

  List<List<Map<String, dynamic>>> get filteredData {
    final q = quickFilter.value.trim().toLowerCase();
    if (q.isEmpty) return data;

    final List<List<Map<String, dynamic>>> result = [];
    for (final group in data) {
      if (group.isEmpty) continue;
      final modelName = (group.first['MODEL_NAME'] ?? '').toString();
      if (modelName.toLowerCase().contains(q)) {
        result.add(group);
        continue;
      }
      final filtered = group.where((row) {
        for (final v in row.values) {
          if (v.toString().toLowerCase().contains(q)) return true;
        }
        return false;
      }).toList();
      if (filtered.isNotEmpty) result.add(filtered);
    }
    return result;
  }
}
