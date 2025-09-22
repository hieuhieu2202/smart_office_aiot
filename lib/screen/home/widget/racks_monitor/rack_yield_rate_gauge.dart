import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controller/racks_monitor_controller.dart';

class YieldRateGauge extends StatelessWidget {
  const YieldRateGauge({
    super.key,
    required this.controller,
    this.showHeader = true,
  });

  final GroupMonitorController controller;
  final bool showHeader;

  static const double _minGaugeWidth = 94.0;
  static const double _maxGaugeWidth = 156.0;
  static const double _heightFactor = 0.6;

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
    bool includeHeader = true,
  }) {
    final geometry = _resolveGeometry(
      width: width,
      includeHeader: includeHeader,
    );
    return geometry.tileHeight;
  }

  static double _spacingForWidth(double gaugeWidth) {
    if (gaugeWidth <= 0) return 0;
    return (gaugeWidth * 0.075).clamp(10.0, 18.0);
  }

  static double _solveGaugeWidth({
    required double maxHeight,
    required double maxGauge,
    bool includeHeader = true,
  }) {
    if (maxHeight <= 0) {
      return 0;
    }
    var low = 0.0;
    var high = maxGauge;
    var best = 0.0;
    for (var i = 0; i < 24; i++) {
      final mid = (low + high) / 2;
      final spacing = includeHeader ? _spacingForWidth(mid) : 0.0;
      final inset = includeHeader ? math.max(6.0, spacing * 0.25) : 0.0;
      final total = mid * _heightFactor + inset;
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
    double? maxHeight,
    bool includeHeader = true,
  }) {
    final effectiveWidth = width.isFinite && width > 0
        ? width
        : _minGaugeWidth;

    final maxGauge = math.min(effectiveWidth, _maxGaugeWidth);
    final minGauge = math.min(_minGaugeWidth, maxGauge);
    var gaugeWidth =
        math.min(maxGauge, effectiveWidth * 0.72).clamp(minGauge, maxGauge);

    var headerSpacing = includeHeader ? _spacingForWidth(gaugeWidth) : 0.0;
    var gaugeHeight = gaugeWidth * _heightFactor;
    var topInset = includeHeader ? math.max(6.0, headerSpacing * 0.25) : 0.0;
    var tileHeight = gaugeHeight + topInset;

    final limit = maxHeight != null && maxHeight.isFinite ? maxHeight : null;
    if (limit != null && limit > 0 && tileHeight > limit + 0.1) {
      final solved = _solveGaugeWidth(
        maxHeight: limit,
        maxGauge: maxGauge,
        includeHeader: includeHeader,
      );
      gaugeWidth = solved.clamp(0.0, maxGauge);
      headerSpacing = includeHeader ? _spacingForWidth(gaugeWidth) : 0.0;
      gaugeHeight = gaugeWidth * _heightFactor;
      topInset = includeHeader ? math.max(6.0, headerSpacing * 0.25) : 0.0;
      tileHeight = gaugeHeight + topInset;
    }

    return _GaugeGeometry(
      gaugeWidth: gaugeWidth,
      gaugeHeight: gaugeHeight,
      topInset: includeHeader ? topInset : 0.0,
      tileHeight: limit == null ? tileHeight : math.min(tileHeight, limit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final headerStyle = headerTextStyle(theme);

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
          maxHeight: maxHeight,
          includeHeader: showHeader,
        );
        final gaugeWidth = geometry.gaugeWidth;
        final gaugeHeight = geometry.gaugeHeight;
        final topInset = geometry.topInset;

        final labelColor = textTheme.bodyMedium?.color ??
            (isDark ? Colors.white70 : Colors.black87);
        final tickStyle = TextStyle(
          fontSize: (gaugeWidth * 0.085).clamp(9.0, 12.0),
          fontWeight: FontWeight.w600,
          color: labelColor.withOpacity(isDark ? 0.9 : 0.75),
        );
        final percentColor = isDark ? Colors.white : theme.colorScheme.onSurface;
        final percentStyle = textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: (gaugeWidth * 0.21).clamp(18.0, 26.0),
              color: percentColor,
              shadows:
                  isDark ? const [Shadow(color: Colors.black45, blurRadius: 4)] : null,
            ) ??
            TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: (gaugeWidth * 0.22).clamp(19.0, 26.0),
              color: percentColor,
              shadows:
                  isDark ? const [Shadow(color: Colors.black45, blurRadius: 4)] : null,
            );

        final headerDisplayStyle = headerStyle.copyWith(
          fontSize: (headerStyle.fontSize ?? 14).clamp(12.0, 14.0),
          letterSpacing: 1.05,
        );

        final thickness = (gaugeWidth * 0.1).clamp(8.0, 15.0);
        final sidePadding = (gaugeWidth * 0.1).clamp(9.0, 20.0);

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
              alignment: const Alignment(0, -0.08),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showHeader)
                    Text(
                      'YIELD RATE',
                      style: headerDisplayStyle,
                      textAlign: TextAlign.center,
                    ),
                  if (showHeader) SizedBox(height: gaugeHeight * 0.06),
                  Text('${yr.toStringAsFixed(2)}%', style: percentStyle),
                ],
              ),
            ),
          ),
        );

        return Center(
          child: Padding(
            padding: EdgeInsets.only(top: showHeader ? topInset : 0.0),
            child: gauge,
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
    required this.topInset,
    required this.tileHeight,
  });

  final double gaugeWidth;
  final double gaugeHeight;
  final double topInset;
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
