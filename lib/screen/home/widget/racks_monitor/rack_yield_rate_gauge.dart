import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../controller/racks_monitor_controller.dart';

class YieldRateGauge extends StatelessWidget {
  const YieldRateGauge({super.key, required this.controller});
  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final yr = controller.kpiYr.clamp(0, 100).toDouble();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // màu theo theme
    final baseColor   = isDark ? const Color(0xFF233140) : Colors.grey.shade300;
    final activeColor = isDark ? const Color(0xFF46B85F) : const Color(0xFF4CAF50);
    final textTheme = Theme.of(context).textTheme;
    final labelColor =
        textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : Colors.black87);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final gaugeWidth = rawWidth.clamp(110.0, 240.0).toDouble();
        final gaugeHeight = (gaugeWidth * 0.65).clamp(80.0, 160.0).toDouble();
        final thickness = (gaugeWidth * 0.095).clamp(8.0, 14.0).toDouble();
        final sidePadding = (gaugeWidth * 0.08).clamp(6.0, 16.0).toDouble();
        final labelFontSize = (gaugeWidth * 0.12).clamp(10.0, 14.0).toDouble();
        final percentFontSize =
            (gaugeWidth * 0.28).clamp(18.0, 26.0).toDouble();

        final labelTextStyle = TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w700,
          fontSize: labelFontSize,
        );
        final percentStyle = textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: percentFontSize,
              color: labelColor,
            ) ??
            TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: percentFontSize,
              color: labelColor,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YIELD RATE',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: gaugeWidth,
                height: gaugeHeight,
                child: CustomPaint(
                  painter: _GaugePainter(
                    value: yr,
                    baseColor: baseColor,
                    activeColor: activeColor,
                    thickness: thickness,
                    sideLabelPadding: sidePadding,
                    labelTextStyle: labelTextStyle,
                  ),
                  child: Align(
                    alignment: const Alignment(0, -0.18),
                    child: Text(
                      '${yr.toStringAsFixed(1)}%',
                      style: percentStyle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;      // 0..100
  final Color baseColor;
  final Color activeColor;
  final double thickness;
  final double sideLabelPadding;
  final TextStyle labelTextStyle;

  _GaugePainter({
    required this.value,
    required this.baseColor,
    required this.activeColor,
    this.thickness = 14,
    this.sideLabelPadding = 8,
    required this.labelTextStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tp0 = TextPainter(
      text: TextSpan(text: '0', style: labelTextStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final tp100 = TextPainter(
      text: TextSpan(text: '100', style: labelTextStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelHeight = math.max(tp0.height, tp100.height);
    final arcBottom = math.max(0.0, size.height - labelHeight - sideLabelPadding);
    final maxRadiusByWidth = math.max(0.0, size.width / 2 - sideLabelPadding);
    final maxRadiusByHeight = math.max(0.0, arcBottom - thickness / 2);
    final radius = math.max(
      0.0,
      math.min(maxRadiusByWidth, maxRadiusByHeight),
    );
    final center = Offset(size.width / 2, arcBottom - radius);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = baseColor;

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = activeColor;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // nền 180°
    canvas.drawArc(rect, math.pi, math.pi, false, base);

    // phần active theo %
    final sweep = (value.clamp(0, 100) / 100) * math.pi;
    canvas.drawArc(rect, math.pi, sweep, false, active);

    final labelTop = arcBottom + sideLabelPadding;
    final left = Offset(rect.left + sideLabelPadding, labelTop);
    final right =
        Offset(rect.right - sideLabelPadding - tp100.width, labelTop);

    tp0.paint(canvas, left);
    tp100.paint(canvas, right);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) {
    return old.value != value ||
        old.baseColor != baseColor ||
        old.activeColor != activeColor ||
        old.thickness != thickness ||
        old.sideLabelPadding != sideLabelPadding ||
        old.labelTextStyle != labelTextStyle;
  }
}
