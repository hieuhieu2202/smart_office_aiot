import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/global_color.dart';
import '../../model/notification_entry.dart';
import '../../model/notification_message.dart';
import '../../service/notification_attachment_service.dart';
import '../../widget/custom_app_bar.dart';
import '../setting/controller/setting_controller.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.entry});

  final NotificationEntry entry;

  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.find<SettingController>();
    final bool isDark = settingController.isDarkMode.value;
    final Color accent = GlobalColors.accentByIsDark(isDark);
    final NotificationMessage message = entry.message;

    final Color primaryText =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    final Color secondaryText = isDark
        ? GlobalColors.darkSecondaryText
        : GlobalColors.lightSecondaryText;

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(message.title),
        isDark: isDark,
        accent: accent,
        titleAlign: TextAlign.left,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: accent,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.22 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      if (message.formattedTimestamp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 16, color: secondaryText),
                              const SizedBox(width: 6),
                              Text(
                                message.formattedTimestamp!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Nội dung',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? GlobalColors.cardDarkBg
                    : GlobalColors.cardLightBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.25)
                        : Colors.blueGrey.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 12),
                  )
                ],
              ),
              child: SelectableText(
                message.body,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: primaryText,
                ),
              ),
            ),
            if (message.hasLink || message.hasAttachment) ...[
              const SizedBox(height: 24),
              Text(
                'Tác vụ nhanh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 12),
              if (message.hasLink)
                ElevatedButton.icon(
                  onPressed: () => _openLink(message.link!),
                  icon: const Icon(Icons.link_rounded),
                  label: Text(
                    message.link!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              if (message.hasAttachment)
                OutlinedButton.icon(
                  onPressed: () => NotificationAttachmentService.openAttachment(message),
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    message.fileName ?? 'Tệp đính kèm',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(foregroundColor: accent),
                ),
            ],
            if (message.appVersion != null) ...[
              const SizedBox(height: 24),
              Text(
                'Thông tin phiên bản liên quan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 12),
              _buildVersionCard(isDark, accent, message.appVersion!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard(
    bool isDark,
    Color accent,
    NotificationAppVersion appVersion,
  ) {
    final Color primaryText =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    final Color secondaryText = isDark
        ? GlobalColors.darkSecondaryText
        : GlobalColors.lightSecondaryText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appVersion.versionName ?? 'Phiên bản không xác định',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: primaryText,
              fontSize: 16,
            ),
          ),
          if (appVersion.releaseDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: secondaryText),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(appVersion.releaseDate!.toLocal()),
                    style: TextStyle(fontSize: 13, color: secondaryText),
                  ),
                ],
              ),
            ),
          if ((appVersion.releaseNotes ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                appVersion.releaseNotes!,
                style: TextStyle(color: secondaryText, height: 1.4),
              ),
            ),
          if ((appVersion.fileUrl ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton.icon(
                onPressed: () => NotificationAttachmentService.openAttachment(
                  NotificationMessage(
                    id: appVersion.appVersionId?.toString(),
                    title: appVersion.versionName ?? '',
                    body: appVersion.releaseNotes ?? '',
                    fileUrl: appVersion.fileUrl,
                    fileName: appVersion.fileName,
                    link: null,
                    targetVersion: appVersion.versionName,
                    timestampUtc: appVersion.releaseDate,
                    appVersion: appVersion,
                  ),
                ),
                icon: Icon(Icons.download_rounded, color: accent),
                label: Text(
                  appVersion.fileName ?? 'Tải gói cập nhật',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(foregroundColor: accent),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openLink(String rawUrl) async {
    final uri = _parseUri(rawUrl);
    if (uri == null) {
      Get.snackbar(
        'Liên kết không hợp lệ',
        rawUrl,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success) {
      Get.snackbar(
        'Không thể mở liên kết',
        uri.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.85),
        colorText: Colors.white,
      );
    }
  }

  Uri? _parseUri(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    Uri? uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$trimmed');
    }
    if (uri == null || !uri.hasScheme) return null;
    return uri;
  }
}
