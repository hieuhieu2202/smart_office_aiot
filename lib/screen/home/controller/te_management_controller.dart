import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/te_management_api.dart';

class TEManagementController extends GetxController {
  var data = <List<Map<String, dynamic>>>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  late Rx<DateTime> startDate;
  late Rx<DateTime> endDate;
  final DateFormat _fmt = DateFormat('yyyy/MM/dd HH:mm');

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
      );
      data.value = res;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
