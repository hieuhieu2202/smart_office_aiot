import 'dart:ui';

import 'package:flutter/material.dart';

class FeatureCard extends StatefulWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  double _scale = 1;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _scale = 0.97);
  }

  void _handleTapFinish([Object? _]) {
    setState(() => _scale = 1);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color surfaceColor = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.62);
    final Color borderColor = isDark
        ? Colors.cyanAccent.withOpacity(0.25)
        : const Color(0xFF81D4FA).withOpacity(0.55);
    final Color glowColor = isDark
        ? Colors.cyanAccent.withOpacity(0.18)
        : const Color(0xFF4FC3F7).withOpacity(0.14);

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: surfaceColor,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: _handleTapDown,
              onTapUp: _handleTapFinish,
              onTapCancel: _handleTapFinish,
              splashColor: theme.colorScheme.primary.withOpacity(0.20),
              highlightColor: theme.colorScheme.primary.withOpacity(0.08),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.1),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: glowColor,
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        widget.icon,
                        size: 30,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
