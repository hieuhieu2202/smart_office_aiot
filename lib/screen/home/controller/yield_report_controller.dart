import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/yield_rate_api.dart';

class YieldReportController extends GetxController {
  var dates = <String>[].obs;
  var dataNickNames = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReport();
  }

  String _defaultRange() {
    final now = DateTime.now();
    final df = DateFormat('yyyy/MM/dd');
    final start = df.format(now.subtract(const Duration(days: 2)));
    final end = df.format(now);
    return '$start 07:30 - $end 19:30';
  }

  Future<void> fetchReport({String? rangeDateTime, String nickName = 'All'}) async {
    isLoading.value = true;
    try {
      final data = await YieldRateApi.getOutputReport(
        rangeDateTime: rangeDateTime ?? _defaultRange(),
        nickName: nickName,
      );
      final res = data['Data'] ?? {};
      dates.value = List<String>.from(res['ClassDates'] ?? []);
      dataNickNames.value = List<Map<String, dynamic>>.from(res['DataNickNames'] ?? []);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
