import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/global_color.dart';
import '../../generated/l10n.dart';
import '../../widget/custom_app_bar.dart';
import '../setting/controller/setting_controller.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final SettingController settingController = Get.find<SettingController>();

  @override
  Widget build(BuildContext context) {
    final S text = S.of(context);
    return Obx(() {
      final bool isDark = settingController.isDarkMode.value; // Đặt vào trong Obx!
      return Scaffold(
        appBar: CustomAppBar(
          title: Text('History'),
          isDark: isDark,
          accent: GlobalColors.accentByIsDark(isDark),
          titleAlign: TextAlign.left,
        ),
        body: Container(), // Placeholder
      );
    });
  }
}
