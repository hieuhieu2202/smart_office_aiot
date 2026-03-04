import 'dart:ui';

import 'package:flutter/material.dart';

class SmallFeatureCard extends StatefulWidget {
  const SmallFeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<SmallFeatureCard> createState() => _SmallFeatureCardState();
}

class _SmallFeatureCardState extends State<SmallFeatureCard> {
  double _scale = 1;

  void _onTapDown(TapDownDetails _) {
    setState(() {
      _scale = 0.96;
    });
  }

  void _onTapEnd([Object? _]) {
    setState(() {
      _scale = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color glassTint = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.52);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.20)
        : Colors.white.withOpacity(0.62);

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: glassTint,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: _onTapDown,
              onTapUp: _onTapEnd,
              onTapCancel: _onTapEnd,
              splashColor: theme.colorScheme.primary.withOpacity(0.20),
              highlightColor: theme.colorScheme.primary.withOpacity(0.08),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.20 : 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
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
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
