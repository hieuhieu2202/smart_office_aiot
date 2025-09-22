import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controller/racks_monitor_controller.dart';

class YieldRateGauge extends StatelessWidget {
  const YieldRateGauge({super.key, required this.controller});

  final GroupMonitorController controller;

  static const double _minGaugeWidth = 96.0;
  static const double _maxGaugeWidth = 204.0;
  static const double _heightFactor = 0.72;

  static TextStyle headerTextStyle(ThemeData theme) {
    final textTheme = theme.textTheme;
    return textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800) ??
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: textTheme.labelLarge?.color ?? theme.colorScheme.onSurface,
        );
  }

  static double estimateContentHeight({
    required double width,
    required ThemeData theme,
  }) {
    final headerStyle = headerTextStyle(theme);
    final headerHeight = _headerHeight(headerStyle, theme.textTheme);
    final geometry = _resolveGeometry(
      width: width,
      headerHeight: headerHeight,
    );
    return geometry.tileHeight;
  }

  static double _headerHeight(TextStyle headerStyle, TextTheme textTheme) {
    final fontSize =
        headerStyle.fontSize ?? textTheme.labelLarge?.fontSize ?? 14.0;
    final lineHeight = headerStyle.height ?? textTheme.labelLarge?.height ?? 1.25;
    return fontSize * lineHeight;
  }

  static double _spacingForWidth(double gaugeWidth) {
    if (gaugeWidth <= 0) return 0;
    return (gaugeWidth * 0.075).clamp(8.0, 14.0);
  }

  static double _solveGaugeWidth({
    required double headerHeight,
    required double maxHeight,
    required double maxGauge,
  }) {
    if (maxHeight <= headerHeight) {
      return 0;
    }
    var low = 0.0;
    var high = maxGauge;
    var best = 0.0;
    for (var i = 0; i < 24; i++) {
      final mid = (low + high) / 2;
      final spacing = _spacingForWidth(mid);
      final total = headerHeight + spacing + mid * _heightFactor;
      if (total <= maxHeight) {
        best = mid;
        low = mid;
      } else {
        high = mid;
      }
    }
    return best;
  }

  static _GaugeGeometry _resolveGeometry({
    required double width,
    required double headerHeight,
    double? maxHeight,
  }) {
    final effectiveWidth = width.isFinite && width > 0
        ? width
        : _minGaugeWidth;

    final maxGauge = math.min(effectiveWidth, _maxGaugeWidth);
    final minGauge = math.min(_minGaugeWidth, maxGauge);
    var gaugeWidth =
        math.min(maxGauge, effectiveWidth * 0.9).clamp(minGauge, maxGauge);

    var headerSpacing = _spacingForWidth(gaugeWidth);
    var gaugeHeight = gaugeWidth * _heightFactor;
    var tileHeight = headerHeight + headerSpacing + gaugeHeight;

    final limit = maxHeight != null && maxHeight.isFinite ? maxHeight : null;
    if (limit != null && limit > 0 && tileHeight > limit + 0.1) {
      final solved = _solveGaugeWidth(
        headerHeight: headerHeight,
        maxHeight: limit,
        maxGauge: maxGauge,
      );
      gaugeWidth = solved.clamp(0.0, maxGauge);
      headerSpacing = _spacingForWidth(gaugeWidth);
      gaugeHeight = gaugeWidth * _heightFactor;
      tileHeight = headerHeight + headerSpacing + gaugeHeight;
    }

    return _GaugeGeometry(
      gaugeWidth: gaugeWidth,
      gaugeHeight: gaugeHeight,
      headerSpacing: headerSpacing,
      tileHeight: limit == null ? tileHeight : math.min(tileHeight, limit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final headerStyle = headerTextStyle(theme);
    final headerHeight = _headerHeight(headerStyle, textTheme);

    final yr = controller.kpiYr.clamp(0, 100).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final maxHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : null;

        final geometry = _resolveGeometry(
          width: maxWidth,
          headerHeight: headerHeight,
          maxHeight: maxHeight,
        );
        final gaugeWidth = geometry.gaugeWidth;
        final gaugeHeight = geometry.gaugeHeight;
        final headerSpacing = geometry.headerSpacing;

        final labelColor = textTheme.bodyMedium?.color ??
            (isDark ? Colors.white70 : Colors.black87);
        final tickStyle = TextStyle(
          fontSize: (gaugeWidth * 0.1).clamp(10.0, 13.0),
          fontWeight: FontWeight.w600,
          color: labelColor.withOpacity(isDark ? 0.9 : 0.75),
        );
        final percentColor = isDark ? Colors.white : theme.colorScheme.onSurface;
        final percentStyle = textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: (gaugeWidth * 0.24).clamp(20.0, 30.0),
              color: percentColor,
              shadows:
                  isDark ? const [Shadow(color: Colors.black45, blurRadius: 4)] : null,
            ) ??
            TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: (gaugeWidth * 0.24).clamp(20.0, 30.0),
              color: percentColor,
              shadows:
                  isDark ? const [Shadow(color: Colors.black45, blurRadius: 4)] : null,
            );

        final thickness = (gaugeWidth * 0.11).clamp(11.0, 18.0);
        final sidePadding = (gaugeWidth * 0.12).clamp(12.0, 24.0);

        final gauge = SizedBox(
          width: gaugeWidth,
          height: gaugeHeight,
          child: CustomPaint(
            painter: _GaugePainter(
              value: yr,
              baseColor: isDark
                  ? Colors.white.withOpacity(0.18)
                  : theme.colorScheme.onSurface.withOpacity(0.12),
              activeColor: const Color(0xFF00E676),
              thickness: thickness,
              sideLabelPadding: sidePadding,
              labelTextStyle: tickStyle,
            ),
            child: Align(
              alignment: const Alignment(0, -0.12),
              child: Text('${yr.toStringAsFixed(2)}%', style: percentStyle),
            ),
          ),
        );

        return SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('YIELD RATE', style: headerStyle, textAlign: TextAlign.center),
              SizedBox(height: headerSpacing),
              gauge,
            ],
          ),
        );
      },
    );
  }
}

class _GaugeGeometry {
  const _GaugeGeometry({
    required this.gaugeWidth,
    required this.gaugeHeight,
    required this.headerSpacing,
    required this.tileHeight,
  });

  final double gaugeWidth;
  final double gaugeHeight;
  final double headerSpacing;
  final double tileHeight;
}

class _GaugePainter extends CustomPainter {
  final double value; // 0..100
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

    canvas.drawArc(rect, math.pi, math.pi, false, base);

    final sweep = (value.clamp(0, 100) / 100) * math.pi;
    canvas.drawArc(rect, math.pi, sweep, false, active);

    final labelTop = arcBottom + sideLabelPadding;
    final left = Offset(rect.left + sideLabelPadding, labelTop);
    final right = Offset(rect.right - sideLabelPadding - tp100.width, labelTop);

    tp0.paint(canvas, left);
    tp100.paint(canvas, right);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.thickness != thickness ||
        oldDelegate.sideLabelPadding != sideLabelPadding ||
        oldDelegate.labelTextStyle != labelTextStyle;
  }
}
