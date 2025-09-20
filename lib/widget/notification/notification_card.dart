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

    final Color baseCardColor =
        isDark ? const Color(0xFF10192B) : Colors.white;
    final Color unreadTint = accent.withOpacity(isDark ? 0.28 : 0.18);
    final Color cardColor = isUnread
        ? Color.lerp(baseCardColor, unreadTint, 0.6) ?? baseCardColor
        : baseCardColor;
    final Color outlineColor = isUnread
        ? accent.withOpacity(isDark ? 0.65 : 0.4)
        : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE4E8F2));

    final List<BoxShadow> shadows = [
      BoxShadow(
        color:
            isDark ? Colors.black.withOpacity(0.55) : Colors.black.withOpacity(0.08),
        blurRadius: 28,
        offset: const Offset(0, 18),
      ),
      if (isUnread)
        BoxShadow(
          color: accent.withOpacity(isDark ? 0.4 : 0.26),
          blurRadius: 36,
          spreadRadius: 1,
          offset: const Offset(0, 20),
        ),
    ];

    final String title = message.title.trim().isNotEmpty
        ? message.title.trim()
        : 'Thông báo';
    final String bodyText = message.body.trim();
    final bool hasBody = bodyText.isNotEmpty;
    final String? timestamp = message.formattedTimestamp;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: outlineColor,
              width: isUnread ? 1.4 : 1,
            ),
            boxShadow: shadows,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withOpacity(isDark ? 0.28 : 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withOpacity(isDark ? 0.45 : 0.35),
                                accent.withOpacity(isDark ? 0.22 : 0.18),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(isDark ? 0.4 : 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        height: 1.25,
                                        color: primaryTextColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      margin: const EdgeInsets.only(left: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        color: accent.withOpacity(
                                            isDark ? 0.28 : 0.18),
                                        border: Border.all(
                                          color:
                                              accent.withOpacity(isDark ? 0.65 : 0.45),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.fiber_manual_record,
                                            size: 10,
                                            color: isDark ? Colors.white : accent,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Mới',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.3,
                                              color:
                                                  isDark ? Colors.white : accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              if (hasBody) ...[
                                const SizedBox(height: 10),
                                Text(
                                  bodyText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
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
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : const Color(0xFFEFF3FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: secondaryTextColor
                                  .withOpacity(isDark ? 0.8 : 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              timestamp,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                color:
                                    secondaryTextColor.withOpacity(isDark ? 0.95 : 0.9),
                              ),
                            ),
                          ],
                        ),
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
