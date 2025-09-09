import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../config/global_color.dart';
import '../../model/notification_message.dart';
import '../../widget/custom_app_bar.dart';
import '../setting/controller/setting_controller.dart';

class NotificationDetail extends StatelessWidget {
  final NotificationMessage notification;
  const NotificationDetail({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.find<SettingController>();
    final bool isDark = settingController.isDarkMode.value;
    final String time = notification.timestampUtc != null
        ? DateFormat('yyyy-MM-dd HH:mm')
            .format(notification.timestampUtc!.toLocal())
        : '';
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chi tiết',
        isDark: isDark,
        accent: GlobalColors.accentByIsDark(isDark),
        titleAlign: TextAlign.center,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: GlobalColors.accentByIsDark(isDark),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(notification.body),
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (notification.fileUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(notification.fileUrl!),
              ),
          ],
        ),
      ),
    );
  }
}

