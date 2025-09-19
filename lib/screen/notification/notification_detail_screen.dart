import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/global_color.dart';
import '../../model/notification_attachment_payload.dart';
import '../../model/notification_entry.dart';
import '../../model/notification_message.dart';
import '../../service/notification_attachment_service.dart';
import '../../widget/custom_app_bar.dart';
import '../setting/controller/setting_controller.dart';

class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({super.key, required this.entry});

  final NotificationEntry entry;

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late final Future<NotificationAttachmentPayload?> _attachmentFuture;

  @override
  void initState() {
    super.initState();
    _attachmentFuture = NotificationAttachmentService.resolve(widget.entry.message);
  }

  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.find<SettingController>();
    final bool isDark = settingController.isDarkMode.value;
    final Color accent = GlobalColors.accentByIsDark(isDark);
    final NotificationMessage message = widget.entry.message;

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
            _buildHeader(isDark, accent, message, primaryText, secondaryText),
            const SizedBox(height: 18),
            _buildMetadataChips(isDark, accent, message),
            const SizedBox(height: 24),
            _buildBodyCard(isDark, message, primaryText),
            const SizedBox(height: 24),
            _buildAttachmentSection(context, isDark, accent, message, secondaryText),
            if (message.appVersion != null) ...[
              const SizedBox(height: 24),
              _buildVersionCard(isDark, accent, message.appVersion!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    bool isDark,
    Color accent,
    NotificationMessage message,
    Color primaryText,
    Color secondaryText,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
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
                      Icon(Icons.schedule, size: 16, color: secondaryText),
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
    );
  }

  Widget _buildMetadataChips(
    bool isDark,
    Color accent,
    NotificationMessage message,
  ) {
    final List<Widget> chips = [];
    final String? appName = message.appName?.trim();
    final String? appKey = message.appKey?.trim();
    final String? targetVersion = message.targetVersion?.trim();
    final String? relatedVersion = message.appVersion?.versionName?.trim();

    if (appName != null && appName.isNotEmpty) {
      chips.add(_buildInfoChip(
        isDark: isDark,
        accent: accent,
        icon: Icons.apps_rounded,
        label: appName,
      ));
    }
    if (appKey != null && appKey.isNotEmpty) {
      chips.add(_buildInfoChip(
        isDark: isDark,
        accent: accent,
        icon: Icons.vpn_key_rounded,
        label: 'Key: $appKey',
      ));
    }
    if (targetVersion != null && targetVersion.isNotEmpty) {
      chips.add(_buildInfoChip(
        isDark: isDark,
        accent: accent,
        icon: Icons.system_update_alt_rounded,
        label: 'Yêu cầu: $targetVersion',
      ));
    }
    if (relatedVersion != null && relatedVersion.isNotEmpty) {
      chips.add(_buildInfoChip(
        isDark: isDark,
        accent: accent,
        icon: Icons.new_releases_outlined,
        label: 'Đính kèm: $relatedVersion',
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips,
    );
  }

  Widget _buildInfoChip({
    required bool isDark,
    required Color accent,
    required IconData icon,
    required String label,
  }) {
    final Color background = accent.withOpacity(isDark ? 0.18 : 0.1);
    final Color textColor =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCard(
    bool isDark,
    NotificationMessage message,
    Color primaryText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        borderRadius: BorderRadius.circular(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nội dung',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            message.body,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection(
    BuildContext context,
    bool isDark,
    Color accent,
    NotificationMessage message,
    Color secondaryText,
  ) {
    final bool hasAttachment = message.hasAttachment;
    final bool hasLink = message.hasLink;

    if (!hasAttachment && !hasLink) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<NotificationAttachmentPayload?>(
      future: _attachmentFuture,
      builder: (context, snapshot) {
        final payload = snapshot.data;
        final bool waiting = snapshot.connectionState == ConnectionState.waiting;
        final List<Widget> tiles = [];

        if (payload?.hasInlineImage == true) {
          tiles.add(_buildInlineImageCard(isDark, accent, message, payload!));
        } else if (payload != null) {
          tiles.add(_buildAttachmentTile(isDark, accent, message, payload));
        } else if (hasAttachment && waiting) {
          tiles.add(_buildAttachmentLoadingCard(isDark));
        } else if (hasAttachment && snapshot.hasError) {
          tiles.add(_buildAttachmentErrorCard(isDark, secondaryText));
        } else if (hasAttachment && !waiting && payload == null) {
          tiles.add(_buildAttachmentUnavailableCard(isDark, secondaryText));
        }

        if (hasLink) {
          tiles.add(_buildLinkTile(isDark, accent, message.link!, secondaryText));
        }

        if (tiles.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tệp & liên kết',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? GlobalColors.darkPrimaryText
                    : GlobalColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 12),
            ...tiles,
          ],
        );
      },
    );
  }

  Widget _buildInlineImageCard(
    bool isDark,
    Color accent,
    NotificationMessage message,
    NotificationAttachmentPayload payload,
  ) {
    final borderRadius = BorderRadius.circular(18);
    return GestureDetector(
      onTap: () => NotificationAttachmentService.openAttachment(message),
      child: Hero(
        tag: 'notification-attachment-${widget.entry.key}',
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 3 / 2,
                child: Image.memory(
                  payload.bytes!,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.black.withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payload.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.open_in_full_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentTile(
    bool isDark,
    Color accent,
    NotificationMessage message,
    NotificationAttachmentPayload payload,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(isDark ? 0.35 : 0.25)),
      ),
      child: ListTile(
        leading: Icon(
          payload.hasInlineImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
          color: accent,
        ),
        title: Text(
          payload.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: payload.mimeType != null
            ? Text(
                payload.mimeType!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(Icons.open_in_new_rounded, color: accent),
        onTap: () => NotificationAttachmentService.openAttachment(message),
      ),
    );
  }

  Widget _buildAttachmentLoadingCard(bool isDark) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.8),
      ),
    );
  }

  Widget _buildAttachmentUnavailableCard(bool isDark, Color secondaryText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.attachment_outlined, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tệp đính kèm không khả dụng.',
              style: TextStyle(color: secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentErrorCard(bool isDark, Color secondaryText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.redAccent.withOpacity(0.14)
            : Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Không thể tải tệp đính kèm. Vui lòng thử lại sau.',
              style: TextStyle(color: secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    bool isDark,
    Color accent,
    String rawUrl,
    Color secondaryText,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(Icons.link_rounded, color: accent),
        title: Text(
          rawUrl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Mở trong trình duyệt',
          style: TextStyle(color: secondaryText),
        ),
        trailing: Icon(Icons.open_in_new_rounded, color: accent),
        onTap: () => _openLink(rawUrl),
      ),
    );
  }

  Future<void> _openLink(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
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

    final withScheme = uri.hasScheme ? uri : uri.replace(scheme: 'https');
    final success = await launchUrl(withScheme, mode: LaunchMode.externalApplication);
    if (!success) {
      Get.snackbar(
        'Không thể mở liên kết',
        withScheme.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.85),
        colorText: Colors.white,
      );
    }
  }

  Widget _buildVersionCard(
    bool isDark,
    Color accent,
    NotificationAppVersion appVersion,
  ) {
    final Color primaryText =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    final Color secondaryText =
        isDark ? GlobalColors.darkSecondaryText : GlobalColors.lightSecondaryText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(isDark ? 0.35 : 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.system_update_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phiên bản liên quan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    if (appVersion.versionName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          appVersion.versionName!,
                          style: TextStyle(color: secondaryText),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (appVersion.releaseNotes != null &&
              appVersion.releaseNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Ghi chú phát hành',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              appVersion.releaseNotes!,
              style: TextStyle(color: secondaryText, height: 1.4),
            ),
          ],
          if (appVersion.fileUrl != null && appVersion.fileUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _openLink(appVersion.fileUrl!),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(appVersion.fileName ?? 'Tải xuống'),
              style: OutlinedButton.styleFrom(foregroundColor: accent),
            ),
          ],
        ],
      ),
    );
  }
}
