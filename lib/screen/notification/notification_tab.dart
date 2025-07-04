import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';
import '../../config/global_color.dart';
import '../login/controller/login_controller.dart';

class NotificationTab extends StatelessWidget {
  const NotificationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.find<SettingController>();

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor:
              settingController.isDarkMode.value
                  ? GlobalColors.appBarDarkBg
                  : GlobalColors.appBarLightBg,
          elevation: 0,
          title: Text(
            'Thông báo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:
                  settingController.isDarkMode.value
                      ? GlobalColors.appBarDarkText
                      : GlobalColors.appBarLightText,
            ),
          ),
        ),
        body: Container(), // Placeholder
      ),
    );
  }
}
