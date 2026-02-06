import 'package:get/get.dart';
import 'package:smart_factory/screen/home/widget/qr/scan_test_screen.dart';

class ScanService {
  Future<Map<String, dynamic>?> scanQr() async {
    final qr = await Get.to(() => const ScanTestScreen());
    if (qr is Map<String, dynamic>) {
      return qr;
    }
    return null;
  }
}
