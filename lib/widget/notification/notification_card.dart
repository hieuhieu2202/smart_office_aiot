import 'package:flutter/material.dart';

import '../../config/Apiconfig.dart';
import '../../config/global_color.dart';
import '../../model/notification_message.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.message,
    required this.isDark,
    required this.accent,
    this.isUnread = false,
    this.onTap,
  });

  final NotificationMessage message;
  final bool isDark;
  final Color accent;
  final bool isUnread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primaryTextColor =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? GlobalColors.darkSecondaryText : GlobalColors.lightSecondaryText;
    final baseCardColor =
        isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;
    final accentOverlay = accent.withOpacity(isDark ? 0.22 : 0.12);
    final cardColor = isUnread
        ? Color.lerp(baseCardColor, accentOverlay, 0.5) ?? accentOverlay
        : baseCardColor;
    final borderColor = isUnread
        ? accent.withOpacity(isDark ? 0.65 : 0.55)
        : Colors.transparent;

    final String? timestamp = message.formattedTimestamp;
    final chips = <Widget>[];

    if (message.hasAttachment) {
      chips.add(_buildMetaChip(
        isDark: isDark,
        accent: accent,
        icon: Icons.attachment_rounded,
        label: message.fileName ?? 'Tệp đính kèm',
      ));
    }
    if (message.hasLink) {
      chips.add(_buildMetaChip(
        isDark: isDark,
        accent: accent,
        icon: Icons.link_rounded,
        label: 'Liên kết',
      ));
    }
    final String? appName = message.appName?.trim();
    if (appName != null && appName.isNotEmpty) {
      chips.add(_buildMetaChip(
        isDark: isDark,
        accent: accent,
        icon: Icons.apps_rounded,
        label: appName,
      ));
    }
    final String? appKey = () {
      final String? raw = message.appKey?.trim();
      if (raw != null && raw.isNotEmpty) {
        return raw;
      }
      final String fallback = ApiConfig.notificationAppKey.trim();
      return fallback.isNotEmpty ? fallback : null;
    }();
    if (appKey != null && appKey.isNotEmpty) {
      chips.add(_buildMetaChip(
        isDark: isDark,
        accent: accent,
        icon: Icons.vpn_key_rounded,
        label: 'Key: $appKey',
      ));
    }
    final String? versionLabel = message.appVersion?.versionName?.trim();
    if (versionLabel != null && versionLabel.isNotEmpty) {
      chips.add(_buildMetaChip(
        isDark: isDark,
        accent: accent,
        icon: Icons.new_releases_outlined,
        label: 'Phiên bản $versionLabel',
      ));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: isUnread ? 1.2 : 1),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(isDark ? 0.6 : 0.4),
                          accent.withOpacity(isDark ? 0.15 : 0.05),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent.withOpacity(isDark ? 0.32 : 0.18),
                                accent.withOpacity(isDark ? 0.18 : 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            color: accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  color: primaryTextColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (timestamp != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(isDark ? 0.18 : 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    timestamp,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                      color: isDark
                                          ? GlobalColors.darkPrimaryText
                                          : GlobalColors.lightPrimaryText,
                                    ),
                                  ),
                                ),
                              ],
                              if (chips.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: chips,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: isDark ? Colors.white54 : Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Positioned(
                right: 20,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip({
    required bool isDark,
    required Color accent,
    required IconData icon,
    required String label,
  }) {
    final Color background = accent.withOpacity(isDark ? 0.16 : 0.1);
    final Color textColor =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
