import 'dart:math' as math;
import 'dart:ui' show BlurStyle, MaskFilter;

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

  static const double _minGaugeWidth = 108.0;
  static const double _maxGaugeWidth = 180.0;
  static const double _heightFactor = 0.64;
  static const double _headerTopPadding = 8.0;
  static const double _headerBottomPadding = 12.0;
  static const Color _activeArcColor = Color(0xFF17FF92);
  static const double _pointerSweepPortion = 0.1;

  static TextStyle headerTextStyle(ThemeData theme) {
    final textTheme = theme.textTheme;
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark ? const Color(0xFFF4F8FF) : accent;
    return textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: headerColor,
        ) ??
        TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: headerColor,
        );
  }

  static double estimateContentHeight({
    required double width,
    ThemeData? theme,
    bool includeHeader = true,
  }) {
    final themeData = theme ?? ThemeData.fallback();
    final headerStyle = headerTextStyle(themeData);
    final topHeaderHeight = includeHeader
        ? _headerBandHeight(headerStyle, themeData.textTheme)
        : 0.0;
    final geometry = _resolveGeometry(
      width: width,
      includeHeader: includeHeader,
      topHeaderHeight: topHeaderHeight,
    );
    return geometry.tileHeight;
  }

  static double _topSpacingFor(double gaugeWidth, bool includeHeader) {
    if (gaugeWidth <= 0) return 0;
    if (includeHeader) return 0;
    return math.max(8.0, gaugeWidth * 0.05);
  }

  static double _bottomSpacingFor(double gaugeWidth, bool includeHeader) {
    if (gaugeWidth <= 0) return 0;
    final base = includeHeader ? 18.0 : 12.0;
    return math.max(base, gaugeWidth * 0.18);
  }

  static double _solveGaugeWidth({
    required double maxHeight,
    required double maxGauge,
    bool includeHeader = true,
    double topHeaderHeight = 0.0,
  }) {
    if (maxHeight <= 0) {
      return 0;
    }
    var low = 0.0;
    var high = maxGauge;
    var best = 0.0;
    for (var i = 0; i < 24; i++) {
      final mid = (low + high) / 2;
      final topSpacing = _topSpacingFor(mid, includeHeader);
      final bottomSpacing = _bottomSpacingFor(mid, includeHeader);
      var total = mid * _heightFactor + topSpacing + bottomSpacing;
      if (includeHeader) {
        total += topHeaderHeight;
      }
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
    required double topHeaderHeight,
    bool includeHeader = true,
  }) {
    final effectiveWidth = width.isFinite && width > 0
        ? width
        : _minGaugeWidth;

    final maxGauge = math.min(effectiveWidth, _maxGaugeWidth);
    final minGauge = math.min(_minGaugeWidth, maxGauge);
    var gaugeWidth =
        math.min(maxGauge, effectiveWidth * 0.64).clamp(minGauge, maxGauge);

    var gaugeHeight = gaugeWidth * _heightFactor;
    var topSpacing = _topSpacingFor(gaugeWidth, includeHeader);
    var bottomSpacing = _bottomSpacingFor(gaugeWidth, includeHeader);
    var tileHeight = gaugeHeight + topSpacing + bottomSpacing;
    if (includeHeader) {
      tileHeight += topHeaderHeight;
    }

    final limit = maxHeight != null && maxHeight.isFinite ? maxHeight : null;
    if (limit != null && limit > 0 && tileHeight > limit + 0.1) {
      final solved = _solveGaugeWidth(
        maxHeight: limit,
        maxGauge: maxGauge,
        includeHeader: includeHeader,
        topHeaderHeight: topHeaderHeight,
      );
      gaugeWidth = solved.clamp(0.0, maxGauge);
      gaugeHeight = gaugeWidth * _heightFactor;
      topSpacing = _topSpacingFor(gaugeWidth, includeHeader);
      bottomSpacing = _bottomSpacingFor(gaugeWidth, includeHeader);
      tileHeight = gaugeHeight + topSpacing + bottomSpacing;
      if (includeHeader) {
        tileHeight += topHeaderHeight;
      }
    }

    return _GaugeGeometry(
      gaugeWidth: gaugeWidth,
      gaugeHeight: gaugeHeight,
      topSpacing: includeHeader ? topSpacing : 0.0,
      bottomSpacing: includeHeader ? bottomSpacing : 0.0,
      tileHeight: limit == null ? tileHeight : math.min(tileHeight, limit),
    );
  }

  static double _headerBandHeight(TextStyle headerStyle, TextTheme textTheme) {
    final fallbackFontSize = textTheme.titleSmall?.fontSize ?? 15.0;
    final fallbackHeight = textTheme.titleSmall?.height ?? 1.2;
    final fontSize = headerStyle.fontSize ?? fallbackFontSize;
    final lineHeight = headerStyle.height ?? fallbackHeight;
    return fontSize * lineHeight +
        _headerTopPadding +
        _headerBottomPadding;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final headerStyle = headerTextStyle(theme);
    final topHeaderHeight =
        showHeader ? _headerBandHeight(headerStyle, theme.textTheme) : 0.0;

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
          topHeaderHeight: topHeaderHeight,
          includeHeader: showHeader,
        );
        final gaugeWidth = geometry.gaugeWidth;
        final gaugeHeight = geometry.gaugeHeight;
        final topSpacing = geometry.topSpacing;
        final bottomSpacing = geometry.bottomSpacing;

        final labelColor = textTheme.bodyMedium?.color ??
            (isDark ? Colors.white70 : Colors.black87);
        final tickColor = isDark
            ? const Color(0xFF9FB5D4)
            : labelColor.withOpacity(0.75);
        final tickStyle = TextStyle(
          fontSize: (gaugeWidth * 0.072).clamp(8.0, 12.0),
          fontWeight: FontWeight.w600,
          color: tickColor,
        );
        final percentColor =
            isDark ? const Color(0xFFF6FBFF) : theme.colorScheme.onSurface;
        final percentStyle = textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: (gaugeWidth * 0.26).clamp(22.0, 34.0),
              color: percentColor,
            ) ??
            TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: (gaugeWidth * 0.26).clamp(22.0, 34.0),
              color: percentColor,
            );

        final thickness = (gaugeWidth * 0.26).clamp(14.0, 30.0);
        final sidePadding = (gaugeWidth * 0.08).clamp(8.0, 16.0);
        final percentageLabel = '${yr.toStringAsFixed(2)}%';

        final baseArcColor = isDark
            ? const Color(0xFF102840)
            : theme.colorScheme.onSurface.withOpacity(0.12);

        final gauge = SizedBox(
          width: gaugeWidth,
          height: gaugeHeight,
          child: CustomPaint(
            painter: _GaugePainter(
              value: yr,
              baseColor: baseArcColor,
              activeColor: _activeArcColor,
              thickness: thickness,
              sideLabelPadding: sidePadding,
              labelTextStyle: tickStyle,
            ),
            child: Center(
              child: Text(percentageLabel, style: percentStyle),
            ),
          ),
        );

        final headerWidth = math.min(
          gaugeWidth,
          maxWidth.isFinite ? maxWidth : gaugeWidth,
        );

        final headerWidget = showHeader
            ? SizedBox(
                width: headerWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: _headerTopPadding),
                    Text(
                      'YIELD RATE',
                      style: headerStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: _headerBottomPadding),
                  ],
                ),
              )
            : null;

        final children = <Widget>[
          if (headerWidget != null) headerWidget,
          if (topSpacing > 0) SizedBox(height: topSpacing),
          gauge,
          if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
        ];

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final child in children)
              child is SizedBox
                  ? child
                  : Align(alignment: Alignment.center, child: child),
          ],
        );

        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          return SizedBox(
            height: constraints.maxHeight,
            child: Center(child: content),
          );
        }

        return Center(child: content);
      },
    );
  }
}

class _GaugeGeometry {
  const _GaugeGeometry({
    required this.gaugeWidth,
    required this.gaugeHeight,
    required this.topSpacing,
    required this.bottomSpacing,
    required this.tileHeight,
  });

  final double gaugeWidth;
  final double gaugeHeight;
  final double topSpacing;
  final double bottomSpacing;
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
      ..color = baseColor.withOpacity(baseColor.opacity.clamp(0.0, 1.0));

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = activeColor;

    final rect = Rect.fromCircle(center: center, radius: radius);

    if (baseColor.opacity > 0) {
      canvas.drawArc(rect, math.pi, math.pi, false, base);
    }

    final sweep = (value.clamp(0, 100) / 100) * math.pi;
    if (sweep > 0) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness * 1.18
        ..strokeCap = StrokeCap.round
        ..color = activeColor.withOpacity(0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, thickness * 0.55);
      canvas.drawArc(rect, math.pi, sweep, false, glowPaint);

      canvas.drawArc(rect, math.pi, sweep, false, active);

      final pointerSweep = math.min(
        sweep,
        math.pi * YieldRateGauge._pointerSweepPortion,
      );
      if (pointerSweep > 0.0001) {
        final pointerPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness * 0.94
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withOpacity(0.96)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, thickness * 0.22);
        final pointerStart = math.pi + sweep - pointerSweep;
        canvas.drawArc(rect, pointerStart, pointerSweep, false, pointerPaint);
      }
    }

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
