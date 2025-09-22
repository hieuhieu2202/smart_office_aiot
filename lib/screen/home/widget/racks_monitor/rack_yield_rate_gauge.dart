import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../controller/racks_monitor_controller.dart';

class YieldRateGauge extends StatelessWidget {
  const YieldRateGauge({super.key, required this.controller});

  final GroupMonitorController controller;

  static const double _gaugeHeight = 150;
  static const double _headerSpacing = 8;

  /// Provides a simple height estimate to keep layout helpers compatible with
  /// the legacy gauge design. The [width] parameter is accepted for API
  /// compatibility but ignored because the classic gauge renders at a fixed
  /// visual size.
  static double estimateContentHeight({
    double? width,
    ThemeData? theme,
    bool includeHeader = true,
  }) {
    final resolvedTheme = theme ?? ThemeData.fallback();
    final headerStyle = resolvedTheme.textTheme.labelLarge ??
        resolvedTheme.textTheme.titleSmall ??
        const TextStyle(fontSize: 14, height: 1.2);
    final fontSize = headerStyle.fontSize ?? 14;
    final lineHeight = headerStyle.height ?? 1.2;
    final headerHeight =
        includeHeader ? fontSize * lineHeight + _headerSpacing : 0;
    return _gaugeHeight + headerHeight;
  }

  @override
  Widget build(BuildContext context) {
    final yr = controller.kpiYr.clamp(0, 100).toDouble();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF233140) : Colors.grey.shade300;
    final activeColor = isDark ? const Color(0xFF46B85F) : const Color(0xFF4CAF50);
    final labelColor = theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.white : Colors.black87);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YIELD RATE',
          style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: _headerSpacing),
        Center(
          child: SizedBox(
            width: 240,
            height: _gaugeHeight,
            child: CustomPaint(
              painter: _GaugePainter(
                value: yr,
                baseColor: baseColor,
                activeColor: activeColor,
                labelColor: labelColor,
                thickness: 14,
                sideLabelPadding: 8,
              ),
              child: LayoutBuilder(
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: const Alignment(0, -0.2),
                    child: Text(
                      '${yr.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.value,
    required this.baseColor,
    required this.activeColor,
    required this.labelColor,
    this.thickness = 14,
    this.sideLabelPadding = 8,
  });

  final double value;
  final Color baseColor;
  final Color activeColor;
  final Color labelColor;
  final double thickness;
  final double sideLabelPadding;

  @override
  void paint(Canvas canvas, Size size) {
    const double horizontalInset = 18;
    const double topInset = 16;
    const double bottomInset = 24;

    final center = Offset(size.width / 2, size.height - bottomInset);
    final maxRadius = math.max(0.0, center.dy - topInset);
    final radius = math.max(
      0.0,
      math.min(size.width / 2 - horizontalInset, maxRadius),
    );

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

    canvas.drawArc(rect, math.pi, math.pi, false, base);

    final sweep = (value.clamp(0, 100) / 100) * math.pi;
    canvas.drawArc(rect, math.pi, sweep, false, active);

    final tp0 = TextPainter(
      text: TextSpan(
        text: '0',
        style: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tp100 = TextPainter(
      text: TextSpan(
        text: '100',
        style: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final baseline = center.dy + thickness / 2 + sideLabelPadding;
    final y = math.min(baseline, size.height - tp0.height / 2);
    final left = Offset(rect.left + sideLabelPadding, y - tp0.height / 2);
    final right =
        Offset(rect.right - sideLabelPadding - tp100.width, y - tp100.height / 2);

    tp0.paint(canvas, left);
    tp100.paint(canvas, right);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) {
    return old.value != value ||
        old.baseColor != baseColor ||
        old.activeColor != activeColor ||
        old.labelColor != labelColor ||
        old.thickness != thickness ||
        old.sideLabelPadding != sideLabelPadding;
  }
}
