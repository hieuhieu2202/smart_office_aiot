import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SplashController extends GetxController {
  final box = GetStorage();
  var opacity = 1.0.obs;

  @override
  void onInit() {
    super.onInit();

    Future.delayed(const Duration(seconds: 3), () {
      opacity.value = 0.0;

      Future.delayed(const Duration(milliseconds: 500), () {
        final selectedLanguage = box.read('selectedLanguage');
        final isLoggedIn = box.read('isLoggedIn') ?? false;

        print('Splash check: selectedLanguage=$selectedLanguage, isLoggedIn=$isLoggedIn');

        if (selectedLanguage == null || selectedLanguage == "") {
          Get.offNamed('/select-language');
        } else if (isLoggedIn) {
          Get.offNamed('/navbar');
        } else {
          box.write('isLoggedIn', false);
          box.write('username', '');
          box.save();
          Get.offNamed('/login');
        }
      });
    });
  }
}

