import 'package:flutter/material.dart';

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
    final Color primaryTextColor =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    final Color secondaryTextColor = isDark
        ? GlobalColors.darkSecondaryText
        : GlobalColors.lightSecondaryText;

    final Color cardColor = isDark ? const Color(0xFF131A2B) : Colors.white;
    final Color outlineColor = isUnread
        ? accent.withOpacity(isDark ? 0.5 : 0.35)
        : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE4E8F2));
    final Color shadowColor =
        isDark ? Colors.black.withOpacity(0.45) : const Color(0x14172133);
    final Color iconBackgroundColor = isUnread
        ? accent.withOpacity(isDark ? 0.24 : 0.15)
        : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F5FB));
    final Color badgeBackgroundColor =
        accent.withOpacity(isDark ? 0.22 : 0.14);
    final Color badgeTextColor = isDark ? Colors.white : accent;
    final Color timestampBackgroundColor =
        isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF5F7FC);

    final String title = message.title.trim().isNotEmpty
        ? message.title.trim()
        : 'Thông báo';
    final String bodyText = message.body.trim();
    final bool hasBody = bodyText.isNotEmpty;
    final String? timestamp = message.formattedTimestamp;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: outlineColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isUnread)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(isDark ? 0.85 : 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isUnread ? 28 : 20,
                  18,
                  20,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconBackgroundColor,
                            border: Border.all(
                              color: accent.withOpacity(isDark ? 0.5 : 0.25),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 24,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                        color: primaryTextColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        color: badgeBackgroundColor,
                                        border: Border.all(
                                          color: accent.withOpacity(
                                            isDark ? 0.55 : 0.4,
                                          ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        'Mới',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                          color: badgeTextColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (hasBody) ...[
                                const SizedBox(height: 8),
                                Text(
                                  bodyText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: secondaryTextColor,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (timestamp != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: timestampBackgroundColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: secondaryTextColor.withOpacity(
                                    isDark ? 0.85 : 0.7,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timestamp,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                    color: secondaryTextColor.withOpacity(
                                      isDark ? 0.95 : 0.85,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
