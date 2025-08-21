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
  }

  Future<void> setLanguage(String code) async {
    currentLocale.value = Locale(code);
    box.write('selectedLanguage', code);
    await box.save(); // Đảm bảo flush ngay ra storage
    Get.updateLocale(currentLocale.value);
    Get.forceAppUpdate();
  }

  String get currentLanguageCode => currentLocale.value.languageCode;
}
