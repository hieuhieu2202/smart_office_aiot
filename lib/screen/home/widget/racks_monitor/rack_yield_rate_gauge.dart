import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controller/racks_monitor_controller.dart';

class YieldRateGauge extends StatelessWidget {
  const YieldRateGauge({super.key, required this.controller});
  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final yr = controller.kpiYr.clamp(0, 100).toDouble();

    final headerStyle = textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ) ??
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: textTheme.labelLarge?.color ??
              (isDark ? Colors.white : theme.colorScheme.onSurface),
        );
    final headerFontSize = headerStyle.fontSize ?? 14;
    final headerLineHeight = headerStyle.height ?? textTheme.labelLarge?.height ?? 1.25;
    final headerHeight = headerFontSize * headerLineHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final maxHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : null;

        const minGaugeWidth = 104.0;
        const maxGaugeWidth = 156.0;

        double gaugeWidth;
        if (maxWidth < minGaugeWidth) {
          gaugeWidth = maxWidth;
        } else {
          final preferred = (maxWidth * 0.82).clamp(minGaugeWidth, maxGaugeWidth);
          gaugeWidth = preferred.toDouble();
        }
        double headerSpacing = (gaugeWidth * 0.07).clamp(6.0, 12.0).toDouble();

        if (maxHeight != null) {
          final availableForGauge = maxHeight - headerHeight - headerSpacing;
          if (availableForGauge.isFinite && availableForGauge > 0) {
            final widthFromHeight = availableForGauge / 0.68;
            if (widthFromHeight.isFinite && widthFromHeight > 0) {
              final targetWidth = widthFromHeight.clamp(minGaugeWidth, maxGaugeWidth);
              gaugeWidth = math.min(gaugeWidth, targetWidth);
              headerSpacing = (gaugeWidth * 0.07).clamp(6.0, 12.0).toDouble();
            }
          }
        }

        gaugeWidth = math.min(gaugeWidth, maxWidth);

        final gaugeHeight = (gaugeWidth * 0.68).toDouble();
        final labelFontSize = (gaugeWidth * 0.1).clamp(9.5, 12.0).toDouble();
        final percentFontSize = (gaugeWidth * 0.24).clamp(18.0, 25.0).toDouble();
        final thickness = (gaugeWidth * 0.115).clamp(9.0, 13.0).toDouble();
        final sidePadding = (gaugeWidth * 0.16).clamp(14.0, 22.0).toDouble();

        final labelColor =
            textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : Colors.black87);
        final tickStyle = TextStyle(
          fontSize: labelFontSize,
          fontWeight: FontWeight.w600,
          color: labelColor.withOpacity(isDark ? 0.9 : 0.75),
        );
        final percentStyle = textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: percentFontSize,
              color: labelColor,
            ) ??
            TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: percentFontSize,
              color: labelColor,
            );

        final gauge = SizedBox(
          width: gaugeWidth,
          height: gaugeHeight,
          child: CustomPaint(
            painter: _GaugePainter(
              value: yr,
              baseColor:
                  isDark ? Colors.white.withOpacity(0.22) : Colors.grey.withOpacity(0.35),
              activeColor: isDark ? const Color(0xFF4FD67F) : const Color(0xFF2E7D32),
              thickness: thickness,
              sideLabelPadding: sidePadding,
              labelTextStyle: tickStyle,
            ),
            child: Align(
              alignment: const Alignment(0, -0.1),
              child: Text('${yr.toStringAsFixed(1)}%', style: percentStyle),
            ),
          ),
        );

        return SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('YIELD RATE', style: headerStyle, textAlign: TextAlign.center),
              SizedBox(height: headerSpacing),
              Expanded(
                child: Center(child: gauge),
              ),
            ],
          ),
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
