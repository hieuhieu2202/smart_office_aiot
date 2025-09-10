import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../config/global_color.dart';
import '../../model/notification_message.dart';
import '../../widget/custom_app_bar.dart';
import '../../widget/full_screen_image.dart';
import '../home/widget/qr/pdf_viewer_screen.dart';
import '../setting/controller/setting_controller.dart';
import '../../service/app_update_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationDetail extends StatelessWidget {
  final NotificationMessage notification;
  const NotificationDetail({super.key, required this.notification});

  Future<void> _openAttachment(BuildContext context) async {
    final String? url = notification.fileUrl;
    if (url == null || url.isEmpty) {
      if (notification.fileBase64 == null ||
          notification.fileBase64!.isEmpty) return;
      final file = await AppUpdateService.loadFile(notification);
      if (file == null) return;
      final Uri localUri = Uri.file(file.path);
      if (AppUpdateService.isInstallable(notification.fileName)) {
        await AppUpdateService.handleNotification(notification);
      } else {
        await launchUrl(localUri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final Uri resolved = AppUpdateService.resolveFileUrl(url);
    final String lower = resolved.path.toLowerCase();
    if (AppUpdateService.isInstallable(url)) {
      await AppUpdateService.handleNotification(notification);
    } else if (lower.endsWith('.pdf')) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
                url: resolved.toString(),
                title: notification.title,
              )));
    } else if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif')) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FullScreenImage(imageUrl: resolved.toString())));
    } else {
      await launchUrl(resolved, mode: LaunchMode.externalApplication);
    }
  }

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
            if ((notification.fileUrl?.isNotEmpty ?? false) ||
                (notification.fileName?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attach_file, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(
                                notification.fileName ?? notification.fileUrl!)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _openAttachment(context),
                      child: const Text('Open file'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

