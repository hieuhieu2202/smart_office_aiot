import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:ui';

class LanguageController extends GetxController {
  final box = GetStorage();
  var currentLocale = const Locale('vi').obs;

  @override
  void onInit() {
    super.onInit();
    final savedCode = box.read('selectedLanguage') ?? 'vi';
    currentLocale.value = Locale(savedCode);
    Get.updateLocale(currentLocale.value);
    print('LanguageController init: ${currentLocale.value.languageCode}');
  }

  void setLanguage(String code) {
    currentLocale.value = Locale(code);
    box.write('selectedLanguage', code);
    Get.updateLocale(currentLocale.value);
    Get.forceAppUpdate(); // Ép rebuild toàn ứng dụng
    print('Locale updated to: ${currentLocale.value.languageCode}');
  }

  String get currentLanguageCode => currentLocale.value.languageCode;
}