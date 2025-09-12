import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';

import 'controller/notification_controller.dart';

class NotificationFilesPage extends StatelessWidget {
  const NotificationFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded files'),
      ),
      body: Obx(() {
        final entries = controller.downloadedFiles.entries.toList();
        if (entries.isEmpty) {
          return const Center(child: Text('No files'));
        }
        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final path = entry.value;
            final name = path.split('/').last;
            return ListTile(
              title: Text(name),
              subtitle: Text(entry.key),
              onTap: () async {
                try {
                  await OpenFilex.open(path);
                } catch (e) {
                  Get.snackbar('Error', e.toString());
                }
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => controller.deleteFile(entry.key),
              ),
            );
          },
        );
      }),
    );
  }
}
