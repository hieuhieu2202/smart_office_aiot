import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class CircularKpi extends StatefulWidget {
  final String label;
  final String valueText;
  final IconData iconData;

  const CircularKpi({
    super.key,
    required this.label,
    required this.valueText,
    required this.iconData,
  });

  @override
  State<CircularKpi> createState() => _CircularKpiState();
}

class _CircularKpiState extends State<CircularKpi>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _iconScale = Tween(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    if (_spinCtrl.isAnimating) _spinCtrl.stop();
    _spinCtrl.dispose();
    if (_pulseCtrl.isAnimating) _pulseCtrl.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ring = isDark ? Colors.cyanAccent : const Color(0xFF0EA5C6);
    final ringBg = isDark ? Colors.white10 : const Color(0xFFBFE8F5);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF2A4B5D);
    final valueColor = isDark ? Colors.white : const Color(0xFF0B2433);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width * 0.28;

        final baseSize = availableWidth > 0 ? availableWidth : 140.0;
        final circleSize = baseSize.clamp(72.0, 200.0);
        final ringDiameter = circleSize * 0.88;
        final haloDiameter = circleSize * 0.78;
        final iconSize = (haloDiameter * 0.62).clamp(36.0, 84.0);
        final labelSize = (circleSize * 0.12).clamp(13.0, 18.0);
        final valueSize = (circleSize * 0.18).clamp(20.0, 30.0);
        final strokeWidth = (ringDiameter / 18).clamp(4.0, 8.0);
        final gap = (circleSize * 0.075).clamp(10.0, 18.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: circleSize,
              height: circleSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: ringDiameter,
                    height: ringDiameter,
                    child: RotationTransition(
                      turns: _spinCtrl,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: strokeWidth,
                        valueColor: AlwaysStoppedAnimation<Color>(ring),
                        backgroundColor: ringBg,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _spinCtrl,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        final pulseT = _pulseCtrl.value;
                        final glowOpacity = lerpDouble(
                          isDark ? 0.28 : 0.2,
                          isDark ? 0.42 : 0.3,
                          pulseT,
                        )!;
                        final glowShadow = lerpDouble(
                          isDark ? 0.22 : 0.18,
                          isDark ? 0.34 : 0.26,
                          pulseT,
                        )!;
                        final blur = lerpDouble(0.18, 0.28, pulseT)!;
                        final spread = lerpDouble(0.02, 0.05, pulseT)!;

                        return Transform.scale(
                          scale: lerpDouble(0.96, 1.04, pulseT)!,
                          child: Container(
                            width: haloDiameter,
                            height: haloDiameter,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ring.withOpacity(glowOpacity),
                              boxShadow: [
                                BoxShadow(
                                  color: ring.withOpacity(glowShadow),
                                  blurRadius: haloDiameter * blur,
                                  spreadRadius: haloDiameter * spread,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ScaleTransition(
                    scale: _iconScale,
                    child: Icon(widget.iconData, size: iconSize, color: ring),
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),
            Text(widget.label,
                style: TextStyle(color: labelColor, fontSize: labelSize)),
            Text(
              widget.valueText,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontSize: valueSize,
              ),
            ),
          ],
        );
      },
    );
  }
}
