import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/notification_message.dart';
import 'controller/notification_controller.dart';

class NotificationDetailPage extends StatelessWidget {
  final NotificationMessage message;
  const NotificationDetailPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(message.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (message.link != null && message.link!.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(message.link!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  message.link!,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              message.timestampUtc.toLocal().toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            if (message.fileUrl != null || message.fileBase64 != null) ...[
              Text(message.fileName ?? 'attachment'),
              const SizedBox(height: 8),
              Obx(() {
                final progress =
                    controller.downloadProgress[message.id] ?? 0.0;
                final path = controller.downloadedFiles[message.id];
                if (path != null) {
                  return ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await OpenFilex.open(path);
                      } catch (e) {
                        Get.snackbar('Error', e.toString());
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open'),
                  );
                }
                if (progress > 0 && progress < 1) {
                  return LinearProgressIndicator(value: progress);
                }
                return ElevatedButton.icon(
                  onPressed: () async {
                    if (message.fileUrl != null) {
                      final url = message.fileUrl!;
                      if (url.startsWith('http')) {
                        await controller.downloadAttachment(message);
                      } else {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      }
                    } else {
                      await controller.downloadAttachment(message);
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
