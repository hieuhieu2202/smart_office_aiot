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
    this.onToggleReadState,
    this.onDelete,
  });

  final NotificationMessage message;
  final bool isDark;
  final Color accent;
  final bool isUnread;
  final VoidCallback? onTap;
  final VoidCallback? onToggleReadState;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final primaryTextColor =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    final baseCardColor =
        isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;
    final highlighted = accent.withOpacity(isDark ? 0.28 : 0.16);
    final cardColor = isUnread
        ? Color.lerp(baseCardColor, highlighted, 0.55) ?? highlighted
        : baseCardColor;
    final borderColor = isUnread ? accent.withOpacity(0.6) : Colors.transparent;

    final List<Widget> actionButtons = [];
    if (onToggleReadState != null) {
      final bool currentlyUnread = isUnread;
      final bool willMarkUnread = !currentlyUnread;
      actionButtons.add(
        _NotificationActionButton(
          label: willMarkUnread ? 'Chưa đọc' : 'Đã đọc',
          icon: willMarkUnread ? Icons.markunread : Icons.mark_email_read_outlined,
          color: accent,
          isDark: isDark,
          onPressed: onToggleReadState,
        ),
      );
    }
    if (onDelete != null) {
      actionButtons.add(
        _NotificationActionButton(
          label: 'Xoá',
          icon: Icons.delete_outline,
          color: Colors.redAccent,
          isDark: isDark,
          onPressed: onDelete,
        ),
      );
    }

    final card = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isUnread ? 1.2 : 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.32)
                : Colors.blueGrey.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.22 : 0.15),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.notifications_active_outlined,
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
          ),
          if (actionButtons.isNotEmpty) ...[
            const SizedBox(width: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actionButtons,
            ),
          ],
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
                top: 18,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.4),
                        blurRadius: 6,
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

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color background = isDark
        ? color.withOpacity(0.18)
        : color.withOpacity(0.14);
    final Color foreground = isDark ? color.withOpacity(0.9) : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
