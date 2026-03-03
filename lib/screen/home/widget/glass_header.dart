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

    final List<Color> panelGradient = isDark
        ? <Color>[
            const Color(0xFF1BC7C8).withOpacity(0.16),
            const Color(0xFF2D7FF9).withOpacity(0.16),
          ]
        : <Color>[
            const Color(0xFFB3E5FC).withOpacity(0.92),
            const Color(0xFFE1F5FE).withOpacity(0.90),
          ];

    final List<Color> accentGradient = isDark
        ? <Color>[
            Colors.cyanAccent.withOpacity(0.68),
            const Color(0xFF40C4FF).withOpacity(0.20),
          ]
        : <Color>[
            Colors.blue.withOpacity(0.40),
            Colors.blue.withOpacity(0.16),
          ];

    final Color titleColor = isDark ? Colors.white : Colors.blueGrey.shade900;
    final Color subtitleColor = isDark ? Colors.white70 : Colors.blueGrey.shade600;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 16 : 10,
          sigmaY: isDark ? 16 : 10,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: panelGradient,
            ),
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.88),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.cyanAccent.withOpacity(0.28)
                    : Colors.blue.withOpacity(0.40),
                width: 1,
              ),
            ),
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
                  letterSpacing: 0.2,
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
              const SizedBox(height: 14),
              Container(
                height: 2,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: accentGradient,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
