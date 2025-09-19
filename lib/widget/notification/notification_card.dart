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
    final primaryTextColor =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? GlobalColors.darkSecondaryText : GlobalColors.lightSecondaryText;
    final baseCardColor =
        isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;
    final accentOverlay = accent.withOpacity(isDark ? 0.22 : 0.12);
    final cardColor = isUnread
        ? Color.lerp(baseCardColor, accentOverlay, 0.45) ?? accentOverlay
        : baseCardColor;
    final borderColor = isUnread
        ? accent.withOpacity(isDark ? 0.55 : 0.45)
        : Colors.transparent;
    final glowColor = accent.withOpacity(
      isUnread ? (isDark ? 0.22 : 0.18) : (isDark ? 0.12 : 0.08),
    );
    final haloOpacity = isUnread ? (isDark ? 0.24 : 0.18) : (isDark ? 0.14 : 0.08);

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
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: isUnread ? 22 : 12,
                spreadRadius: isUnread ? 2.2 : 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withOpacity(haloOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 20, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(isDark ? 0.28 : 0.18),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(isDark ? 0.35 : 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: isDark ? Colors.white : accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
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
                              ),
                              if (isUnread)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(isDark ? 0.3 : 0.2),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Mới',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                      color: isDark ? Colors.white : accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (timestamp != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              timestamp,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
