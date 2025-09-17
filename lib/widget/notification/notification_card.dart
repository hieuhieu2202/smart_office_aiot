import 'package:flutter/material.dart';

import '../../config/global_color.dart';
import '../../model/notification_message.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.message,
    required this.isDark,
    required this.accent,
    this.onOpenLink,
    this.onOpenAttachment,
  });

  final NotificationMessage message;
  final bool isDark;
  final Color accent;
  final VoidCallback? onOpenLink;
  final VoidCallback? onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final primaryTextColor =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    final secondaryTextColor = isDark
        ? GlobalColors.darkSecondaryText
        : GlobalColors.lightSecondaryText;
    final cardColor =
        isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;

    final actions = <Widget>[];

    final targetVersion = message.targetVersion;
    if (targetVersion != null && targetVersion.isNotEmpty) {
      actions.add(
        Chip(
          backgroundColor: accent.withOpacity(isDark ? 0.18 : 0.12),
          labelStyle: TextStyle(
            color: accent,
            fontWeight: FontWeight.w600,
          ),
          label: Text('Version $targetVersion'),
        ),
      );
    }

    if (message.hasLink) {
      actions.add(
        TextButton.icon(
          onPressed: onOpenLink,
          icon: Icon(Icons.link, color: accent, size: 20),
          label: SizedBox(
            width: 180,
            child: Text(
              message.link!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    if (message.hasAttachment) {
      final fileLabel = message.fileName ?? 'Tập tin đính kèm';
      actions.add(
        TextButton.icon(
          onPressed: onOpenAttachment,
          icon: Icon(Icons.attach_file, color: accent, size: 20),
          label: SizedBox(
            width: 180,
            child: Text(
              fileLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : Colors.blueGrey.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    if (message.formattedTimestamp != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          message.formattedTimestamp!,
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SelectableText(
            message.body,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: primaryTextColor,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}
