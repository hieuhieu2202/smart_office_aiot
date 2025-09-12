import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';

import '../../config/global_color.dart';
import '../../generated/l10n.dart';
import '../../widget/custom_app_bar.dart';
import 'controller/notification_controller.dart';

class NotificationTab extends StatefulWidget {
  const NotificationTab({super.key});

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  late final SettingController settingController;
  late final NotificationController controller;

  @override
  void initState() {
    super.initState();
    settingController = Get.find<SettingController>();
    controller = Get.put(NotificationController());
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.fetchNotifications,
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.separated(
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final msg = controller.notifications[index];
              return ListTile(
                title: Text(msg.title),
                subtitle: Text(msg.body),
                trailing: msg.fileUrl != null
                    ? IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () async {
                          final uri = Uri.parse(msg.fileUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      )
                    : null,
              );
            },
          );
        }),
      );
    });
  }
}
