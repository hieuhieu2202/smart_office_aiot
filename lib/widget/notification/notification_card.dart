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
    final baseCardColor =
        isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;
    final accentOverlay = accent.withOpacity(isDark ? 0.22 : 0.12);
    final cardColor = isUnread
        ? Color.lerp(baseCardColor, accentOverlay, 0.5) ?? accentOverlay
        : baseCardColor;
    final borderColor = isUnread
        ? accent.withOpacity(isDark ? 0.65 : 0.55)
        : Colors.transparent;

    final card = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isUnread ? 1.2 : 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.22 : 0.15),
                  shape: BoxShape.circle,
                ),
                width: 44,
                height: 44,
              ),
              Icon(
                Icons.notifications_rounded,
                color: accent,
                size: 24,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: primaryTextColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: isDark ? Colors.white60 : Colors.black38,
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            card,
            if (isUnread)
              Positioned(
                right: 18,
                top: 16,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
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
}
