import 'dart:ui';

import 'package:flutter/material.dart';

class GlassHeader extends StatelessWidget {
  const GlassHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color surfaceColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.80);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF263238);
    final Color subtitleColor = isDark ? Colors.white70 : const Color(0xFF546E7A);
    final Color accentColor = isDark
        ? Colors.cyanAccent.withOpacity(0.38)
        : const Color(0xFF4FC3F7).withOpacity(0.35);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border(
              bottom: BorderSide(color: accentColor, width: 1.2),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accentColor.withOpacity(isDark ? 0.25 : 0.14),
                blurRadius: 16,
                spreadRadius: 0.6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
