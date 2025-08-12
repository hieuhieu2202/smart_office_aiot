import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadarSweepPainter extends CustomPainter {
  RadarSweepPainter({
    required this.angle,           // radians
    required this.color,
    this.sweepDeg = 40,
    this.widthRatio = 0.95,
  });

  final double angle;
  final Color color;
  final double sweepDeg;
  final double widthRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.5 * widthRatio;

    final start = angle - (sweepDeg * math.pi / 180) / 2;
    final end   = angle + (sweepDeg * math.pi / 180) / 2;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: r), start, end - start, false)
      ..close();

    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: end,
        colors: [color.withOpacity(0.0), color, color.withOpacity(0.0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.saveLayer(Rect.fromCircle(center: center, radius: r), Paint());
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawCircle(center, r, paint..blendMode = BlendMode.srcIn);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RadarSweepPainter old) =>
      old.angle != angle || old.color != color || old.sweepDeg != sweepDeg || old.widthRatio != widthRatio;
}
