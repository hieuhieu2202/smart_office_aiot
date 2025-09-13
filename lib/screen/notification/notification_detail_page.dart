import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';

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
            if (message.fileUrl != null || message.fileBase64 != null)
              _AttachmentView(message: message),
          ],
        ),
      ),
    );
  }
}

class _AttachmentView extends StatelessWidget {
  final NotificationMessage message;
  const _AttachmentView({required this.message});

  bool get _isImage {
    final name = message.fileName?.toLowerCase() ?? '';
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    if (_isImage) {
      Widget img;
      if (message.fileBase64 != null && message.fileBase64!.isNotEmpty) {
        final bytes = base64Decode(message.fileBase64!);
        img = Image.memory(bytes);
      } else {
        img = Image.network(message.fileUrl!, fit: BoxFit.contain);
      }
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: img,
      );
    }
    return Obx(() {
      return ElevatedButton.icon(
        onPressed: () => controller.openAttachment(message),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Open'),
      );
    });
  }
}
