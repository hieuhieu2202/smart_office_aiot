import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/yield_rate_api.dart';

class YieldReportController extends GetxController {
  var dates = <String>[].obs;
  var dataNickNames = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  late Rx<DateTime> startDateTime;
  late Rx<DateTime> endDateTime;

  final DateFormat _format = DateFormat('yyyy/MM/dd HH:mm');

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDateTime = Rx<DateTime>(
      DateTime(now.year, now.month, now.day - 2, 7, 30),
    );
    endDateTime = Rx<DateTime>(
      DateTime(now.year, now.month, now.day, 19, 30),
    );
    fetchReport();
  }

  String get range => '${_format.format(startDateTime.value)} - ${_format.format(endDateTime.value)}';

  Future<void> fetchReport({String nickName = 'All'}) async {
    isLoading.value = true;
    try {
      final data = await YieldRateApi.getOutputReport(
        rangeDateTime: range,
        nickName: nickName,
      );
      final res = data['Data'] ?? {};
      dates.value = List<String>.from(res['ClassDates'] ?? []);
      dataNickNames.value =
          List<Map<String, dynamic>>.from(res['DataNickNames'] ?? []);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void updateStart(DateTime dt) => startDateTime.value = dt;
  void updateEnd(DateTime dt) => endDateTime.value = dt;
}
