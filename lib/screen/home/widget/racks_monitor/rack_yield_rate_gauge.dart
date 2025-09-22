import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controller/racks_monitor_controller.dart';
import 'rack_chart_footer.dart';

class YieldRateGauge extends StatelessWidget {
  const YieldRateGauge({
    super.key,
    required this.controller,
    this.showHeader = true,
  });

  final GroupMonitorController controller;
  final bool showHeader;

  static const double _minGaugeWidth = 94.0;
  static const double _maxGaugeWidth = 150.0;
  static const double _heightFactor = 0.6;
  static const double _footerSpacingFactor = 0.9;

  static TextStyle headerTextStyle(ThemeData theme) {
    final textTheme = theme.textTheme;
    final accent = theme.colorScheme.primary;
    return textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: accent,
        ) ??
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: accent,
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

  static double _spacingForWidth(double gaugeWidth) {
    if (gaugeWidth <= 0) return 0;
    return (gaugeWidth * 0.075).clamp(10.0, 18.0);
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
      final spacing = includeHeader ? _spacingForWidth(mid) : 0.0;
      final topSpacing = includeHeader ? math.max(6.0, spacing * 0.3) : 0.0;
      final bottomSpacing = includeHeader
          ? math.max(8.0, spacing * _footerSpacingFactor)
          : 0.0;
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
        math.min(maxGauge, effectiveWidth * 0.72).clamp(minGauge, maxGauge);

    var gaugeHeight = gaugeWidth * _heightFactor;
    var spacing = includeHeader ? _spacingForWidth(gaugeWidth) : 0.0;
    var topSpacing = includeHeader ? math.max(6.0, spacing * 0.3) : 0.0;
    var bottomSpacing = includeHeader
        ? math.max(8.0, spacing * _footerSpacingFactor)
        : 0.0;
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
      spacing = includeHeader ? _spacingForWidth(gaugeWidth) : 0.0;
      topSpacing = includeHeader ? math.max(6.0, spacing * 0.3) : 0.0;
      bottomSpacing = includeHeader
          ? math.max(8.0, spacing * _footerSpacingFactor)
          : 0.0;
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
    return ChartCardHeader.heightForStyle(headerStyle, textTheme);
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
              alignment: const Alignment(0, -0.05),
              child: Text('${yr.toStringAsFixed(2)}%', style: percentStyle),
            ),
          ),
        );

        final headerWidget = showHeader
            ? ChartCardHeader(
                label: 'YIELD RATE',
                textStyle: headerStyle,
              )
            : null;

        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          return SizedBox(
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (headerWidget != null) headerWidget,
                if (headerWidget != null && topSpacing > 0)
                  SizedBox(height: topSpacing),
                Expanded(
                  child: Center(child: gauge),
                ),
                if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
              ],
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (headerWidget != null) headerWidget,
            if (headerWidget != null && topSpacing > 0)
              SizedBox(height: topSpacing),
            Center(child: gauge),
            if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
          ],
        );
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
