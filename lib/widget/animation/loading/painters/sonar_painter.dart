import 'dart:math' as math;
import 'package:flutter/material.dart';

class SonarPainter extends CustomPainter {
  SonarPainter({
    required this.t,
    required this.rings,
    required this.baseColor,
  });

  final double t;      // 0..1
  final int rings;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide * 0.62;

    final gridPaint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (double r = maxR * 0.15; r < maxR; r += maxR * 0.15) {
      canvas.drawCircle(center, r, gridPaint);
    }

    for (int i = 0; i < rings; i++) {
      final phase = ((t + i / rings) % 1.0);
      final r = phase * maxR;
      final fade = (1.0 - phase).clamp(0.0, 1.0);
      final pulse = 0.5 + 0.5 * math.sin((phase * 2 * math.pi) - math.pi / 2);
      final alpha = (fade * 0.9 + 0.1 * pulse) * 0.85;

      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (0.5 + 0.5 * fade)
        ..color = baseColor.withOpacity(alpha);

      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.strokeWidth + 6
        ..color = baseColor.withOpacity(alpha * 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      if (r > 4) {
        canvas.drawCircle(center, r, glow);
        canvas.drawCircle(center, r, ring);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SonarPainter old) =>
      old.t != t || old.baseColor != baseColor || old.rings != rings;
}
