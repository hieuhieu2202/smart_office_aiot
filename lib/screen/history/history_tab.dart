import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/global_color.dart';
import '../login/controller/login_controller.dart';
import '../setting/controller/setting_controller.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {

    final LoginController loginController = Get.find<LoginController>();
    final SettingController settingController = Get.find<SettingController>();
    return Obx(() => Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: settingController.isDarkMode.value
            ? GlobalColors.appBarDarkBg
            : GlobalColors.appBarLightBg,
        elevation: 0,
        title: Text(
          'Lịch sử',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: settingController.isDarkMode.value
                ? GlobalColors.appBarDarkText
                : GlobalColors.appBarLightText,
          ),
        ),
      ),
      body: Container(), // Placeholder
    ));
  }
}
