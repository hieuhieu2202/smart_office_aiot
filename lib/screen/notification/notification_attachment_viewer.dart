import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:photo_view/photo_view.dart';

import '../../config/global_color.dart';
import '../../model/notification_attachment_payload.dart';
import '../../widget/custom_app_bar.dart';
import '../setting/controller/setting_controller.dart';

class NotificationAttachmentViewer extends StatelessWidget {
  NotificationAttachmentViewer({super.key, required this.payload})
      : assert(payload.isInline, 'Viewer chỉ dùng cho tệp nội tuyến.');

  final NotificationAttachmentPayload payload;

  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.find<SettingController>();
    final bool isDark = settingController.isDarkMode.value;
    final Color accent = GlobalColors.accentByIsDark(isDark);
    final File file = payload.file!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: Text(payload.fileName),
        isDark: isDark,
        accent: accent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: accent,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Mở bằng ứng dụng khác',
            icon: const Icon(Icons.open_in_new_rounded),
            color: accent,
            onPressed: () async {
              final result = await OpenFilex.open(file.path);
              if (result.type != ResultType.done) {
                Get.snackbar(
                  'Không thể mở tệp',
                  result.message ?? 'Ứng dụng trên thiết bị không hỗ trợ định dạng này.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.redAccent.withOpacity(0.9),
                  colorText: Colors.white,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: PhotoView(
          imageProvider: MemoryImage(payload.bytes!),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}
