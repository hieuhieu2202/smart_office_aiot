import 'package:get/get.dart';
import 'package:smart_factory/features/camera_test/view/scan_test_screen.dart';

class ScanService {
  Future<Map<String, dynamic>?> scanQr() async {
    final result = await Get.to(() => const ScanTestScreen());
    if (result is Map<String, dynamic>) {
      return result;
    }
    return null;
  }
}
