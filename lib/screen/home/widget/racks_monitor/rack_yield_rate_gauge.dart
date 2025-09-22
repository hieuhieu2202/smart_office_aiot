import 'dart:math' as math;
import 'dart:ui' show BlurStyle, MaskFilter;

import 'package:flutter/material.dart';

import '../../controller/racks_monitor_controller.dart';

/// A compact semi-circular gauge that mirrors the latest design brief.
///
/// The gauge renders a bright green active arc with a soft white highlight at
/// the leading edge, a centered percentage label, and "0"/"100" tick labels
/// aligned with the arc endpoints.
class YieldRateGauge extends StatelessWidget {
  const YieldRateGauge({
    super.key,
    required this.controller,
    this.showHeader = true,
  });

  final GroupMonitorController controller;
  final bool showHeader;

  static const double _minVisualWidth = 132.0;
  static const double _maxVisualWidth = 220.0;
  static const double _arcHeightFactor = 0.62;
  static const double _tickBandFactor = 0.18;
  static const double _minTickBand = 26.0;
  static const double _headerTopGap = 8.0;
  static const double _headerBottomGap = 12.0;

  /// Estimates the total height consumed by the gauge for layout calculations.
  static double estimateContentHeight({
    required double width,
    ThemeData? theme,
    bool includeHeader = true,
  }) {
    final headerHeight = includeHeader
        ? _headerHeight(theme ?? ThemeData.fallback())
        : 0.0;
    final gaugeWidth = _resolveWidth(width, width);
    final gaugeHeight = _gaugeHeightForWidth(gaugeWidth);
    return headerHeight + gaugeHeight;
  }

  static double _headerHeight(ThemeData theme) {
    final style = headerTextStyle(theme);
    final fontSize = style.fontSize ??
        theme.textTheme.titleSmall?.fontSize ??
        15.0;
    final lineHeight = style.height ??
        theme.textTheme.titleSmall?.height ??
        1.2;
    return fontSize * lineHeight + _headerTopGap + _headerBottomGap;
  }

  static double _gaugeHeightForWidth(double width) {
    final arcRegion = width * _arcHeightFactor;
    final tickBand = math.max(_minTickBand, width * _tickBandFactor);
    return arcRegion + tickBand;
  }

  static double _solveWidthForHeight(double height) {
    final minHeight = _gaugeHeightForWidth(_minVisualWidth);
    final maxHeight = _gaugeHeightForWidth(_maxVisualWidth);
    if (height <= minHeight) {
      return _minVisualWidth;
    }
    if (height >= maxHeight) {
      return _maxVisualWidth;
    }

    var low = _minVisualWidth;
    var high = _maxVisualWidth;
    var best = low;
    for (var i = 0; i < 24; i++) {
      final mid = (low + high) / 2;
      final candidateHeight = _gaugeHeightForWidth(mid);
      if (candidateHeight <= height) {
        best = mid;
        low = mid;
      } else {
        high = mid;
      }
    }
    return best;
  }

  static double _resolveWidth(double proposed, [double? constraint]) {
    final hasConstraint = constraint != null && constraint.isFinite && constraint > 0;
    final upperBound = hasConstraint
        ? math.min(_maxVisualWidth, constraint!)
        : _maxVisualWidth;
    final lowerBound = math.min(_minVisualWidth, upperBound);
    final candidate = proposed.isFinite && proposed > 0 ? proposed : upperBound;
    final clamped = candidate.clamp(lowerBound, upperBound);
    return clamped;
  }

  static TextStyle headerTextStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final fallback = theme.textTheme.titleSmall ?? const TextStyle();
    return fallback.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color: isDark
          ? const Color(0xFFF4F8FF)
          : theme.colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxConstraint = constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0
            ? constraints.maxWidth
            : null;
        final availableWidth = maxConstraint ??
            MediaQuery.of(context).size.width;
        var gaugeWidth = _resolveWidth(availableWidth, maxConstraint ?? availableWidth);

        final headerHeight = showHeader ? _headerHeight(theme) : 0.0;
        final gaugeHeight = _gaugeHeightForWidth(gaugeWidth);
        final requiredHeight = headerHeight + gaugeHeight;

        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          final maxHeight = constraints.maxHeight;
          if (requiredHeight > maxHeight && maxHeight > headerHeight + 1) {
            final targetGaugeHeight =
                (maxHeight - headerHeight).clamp(
              _gaugeHeightForWidth(_minVisualWidth),
              _gaugeHeightForWidth(_maxVisualWidth),
            );
            final solvedWidth = _solveWidthForHeight(targetGaugeHeight);
            gaugeWidth = _resolveWidth(
              solvedWidth,
              maxConstraint ?? availableWidth,
            );
          }
        }

        final activePercent = controller.kpiYr.clamp(0, 100).toDouble();

        final percentStyle = textTheme.headlineSmall?.copyWith(
              fontSize: (gaugeWidth * 0.26).clamp(22, 34),
              fontWeight: FontWeight.w900,
              color: isDark
                  ? const Color(0xFFF6FBFF)
                  : theme.colorScheme.onSurface,
            ) ??
            TextStyle(
              fontSize: (gaugeWidth * 0.26).clamp(22, 34),
              fontWeight: FontWeight.w900,
              color: isDark
                  ? const Color(0xFFF6FBFF)
                  : theme.colorScheme.onSurface,
            );

        final tickStyle = textTheme.bodyMedium?.copyWith(
              fontSize: (gaugeWidth * 0.09).clamp(9, 13),
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFFAEC7E9)
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ) ??
            TextStyle(
              fontSize: (gaugeWidth * 0.09).clamp(9, 13),
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFFAEC7E9)
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            );

        final gaugeSize = Size(
          gaugeWidth,
          _gaugeHeightForWidth(gaugeWidth),
        );

        final gauge = SizedBox(
          width: gaugeSize.width,
          height: gaugeSize.height,
          child: CustomPaint(
            painter: _YieldGaugePainter(
              value: activePercent,
              baseColor: isDark
                  ? const Color(0xFF0D2344)
                  : const Color(0xFFE5EFF9),
              activeColor: const Color(0xFF17FF80),
              pointerColor: Colors.white,
              percentTextStyle: percentStyle,
              tickTextStyle: tickStyle,
            ),
          ),
        );

        final children = <Widget>[
          if (showHeader)
            Padding(
              padding: const EdgeInsets.only(top: _headerTopGap),
              child: Text(
                'YIELD RATE',
                style: headerTextStyle(theme),
                textAlign: TextAlign.center,
              ),
            ),
          if (showHeader) const SizedBox(height: _headerBottomGap),
          gauge,
        ];

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        );

        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          return SizedBox(
            height: constraints.maxHeight,
            child: Align(
              alignment: Alignment.center,
              child: content,
            ),
          );
        }

        return Center(child: content);
      },
    );
  }
}

class _YieldGaugePainter extends CustomPainter {
  _YieldGaugePainter({
    required this.value,
    required this.baseColor,
    required this.activeColor,
    required this.pointerColor,
    required this.percentTextStyle,
    required this.tickTextStyle,
  });

  final double value; // 0..100
  final Color baseColor;
  final Color activeColor;
  final Color pointerColor;
  final TextStyle percentTextStyle;
  final TextStyle tickTextStyle;

  static double _tickBandHeight(double width) {
    return math.max(YieldRateGauge._minTickBand, width * YieldRateGauge._tickBandFactor);
  }

  static double _arcRegionHeight(double width) {
    return width * YieldRateGauge._arcHeightFactor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final tickBandHeight = _tickBandHeight(size.width);
    final arcBottom = _arcRegionHeight(size.width);
    final topInset = math.max(size.width * 0.08, 12.0);

    final tp0 = TextPainter(
      text: TextSpan(text: '0', style: tickTextStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final tp100 = TextPainter(
      text: TextSpan(text: '100', style: tickTextStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final percentText = TextPainter(
      text: TextSpan(text: '${value.clamp(0, 100).toStringAsFixed(2)}%', style: percentTextStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final maxTickHeight = math.max(tp0.height, tp100.height);
    final tickY = arcBottom + (tickBandHeight - maxTickHeight) / 2;

    final thickness = (size.width * 0.24).clamp(16.0, 34.0);
    final sideInset = math.max(thickness * 0.55, 14.0);
    final radius = math.max(
      0.0,
      math.min(
        (arcBottom - topInset) / 2,
        size.width / 2 - sideInset,
      ),
    );

    if (radius <= 0) {
      return;
    }

    final center = Offset(size.width / 2, arcBottom - radius);
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = baseColor;

    final sweep = (value.clamp(0, 100) / 100) * math.pi;

    if (baseColor.opacity > 0) {
      canvas.drawArc(arcRect, math.pi, math.pi, false, basePaint);
    }

    if (sweep > 0) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness * 1.18
        ..strokeCap = StrokeCap.round
        ..color = activeColor.withOpacity(0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, thickness * 0.55);

      canvas.drawArc(arcRect, math.pi, sweep, false, glowPaint);

      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: math.pi,
          endAngle: math.pi + sweep,
          colors: [
            activeColor.withOpacity(0.85),
            activeColor,
          ],
        ).createShader(arcRect);

      canvas.drawArc(arcRect, math.pi, sweep, false, activePaint);

      final pointerSweep = math.min(sweep, math.pi * 0.09);
      if (pointerSweep > 0.0001) {
        final pointerPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness * 0.9
          ..strokeCap = StrokeCap.round
          ..color = pointerColor
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, thickness * 0.32);
        canvas.drawArc(
          arcRect,
          math.pi + sweep - pointerSweep,
          pointerSweep,
          false,
          pointerPaint,
        );
      }
    }

    final percentOffset = Offset(
      center.dx - percentText.width / 2,
      center.dy - percentText.height / 2,
    );
    percentText.paint(canvas, percentOffset);

    final leftLabelOffset = Offset(sideInset, tickY);
    final rightLabelOffset = Offset(
      size.width - sideInset - tp100.width,
      tickY,
    );

    tp0.paint(canvas, leftLabelOffset);
    tp100.paint(canvas, rightLabelOffset);
  }

  @override
  bool shouldRepaint(covariant _YieldGaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.pointerColor != pointerColor ||
        oldDelegate.percentTextStyle != percentTextStyle ||
        oldDelegate.tickTextStyle != tickTextStyle;
  }
}
