import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';
import '../../config/global_color.dart';
import '../../generated/l10n.dart';
import '../../widget/custom_app_bar.dart';
import '../../widget/top_notification.dart';

class NotificationTab extends StatefulWidget {
  const NotificationTab({super.key});

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  late final SettingController settingController;

  @override
  void initState() {
    super.initState();
    settingController = Get.find<SettingController>();
  }

  @override
  Widget build(BuildContext context) {
    final S text = S.of(context);
    return Obx(() {
      final bool isDark = settingController.isDarkMode.value;
      return Scaffold(
        appBar: CustomAppBar(
          title: Text(text.notification),
          isDark: isDark,
          accent: GlobalColors.accentByIsDark(isDark),
          titleAlign: TextAlign.left,
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () =>
                TopNotification.show(context, 'No notifications'),
            child: const Text('Show notification'),
          ),
        ),
      );
    });
  }
}
