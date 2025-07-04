import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SplashController extends GetxController {
  final box = GetStorage();
  var opacity = 1.0.obs;

  @override
  void onInit() {
    super.onInit();

    // ✅ Bắt đầu sau 3s
    Future.delayed(const Duration(seconds: 3), () {
      opacity.value = 0.0;

      // ✅ Chờ hiệu ứng mờ hoàn tất (0.5s) rồi điều hướng
      Future.delayed(const Duration(milliseconds: 500), () {
        final selectedLanguage = box.read('selectedLanguage');
        final isLoggedIn = box.read('isLoggedIn') ?? false;

        if (selectedLanguage == null) {
          // 🟡 Chưa chọn ngôn ngữ => Chuyển sang màn chọn ngôn ngữ
          Get.offNamed('/select-language');
        } else if (isLoggedIn) {
          // 🟢 Đã đăng nhập => Vào màn hình chính
          Get.offNamed('/navbar');
        } else {
          // 🔴 Chưa đăng nhập => Vào màn login
          box.write('isLoggedIn', false);
          box.write('username', '');
          box.save();
          Get.offNamed('/login');
        }
      });
    });
  }
}
