import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/racks_monitor_controller.dart';

class SlotStatusDonut extends StatelessWidget {
  const SlotStatusDonut({super.key, required this.controller});

  final GroupMonitorController controller;

  static const double _minChartSize = 64.0;
  static const double _maxChartSize = 140.0;
  static const double _preferredScale = 0.48;

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

  static double _spacingForChart(double chartSize) {
    if (chartSize <= 0) return 0;
    return (chartSize * 0.1).clamp(8.0, 14.0);
  }

  static double _solveChartSize({
    required double headerHeight,
    required double maxHeight,
    required double maxChart,
  }) {
    if (maxHeight <= headerHeight) {
      return 0;
    }
    var low = 0.0;
    var high = maxChart;
    var best = 0.0;
    for (var i = 0; i < 24; i++) {
      final mid = (low + high) / 2;
      final spacing = _spacingForChart(mid);
      final total = headerHeight + spacing + mid;
      if (total <= maxHeight) {
        best = mid;
        low = mid;
      } else {
        high = mid;
      }
    }
    return best;
  }

  static _SlotStatusGeometry _resolveGeometry({
    required double width,
    required double headerHeight,
    double? maxHeight,
  }) {
    final effectiveWidth = width.isFinite && width > 0
        ? width
        : _minChartSize;

    final maxChart = math.min(effectiveWidth, _maxChartSize);
    final minChart = math.min(
      math.max(_minChartSize, effectiveWidth * 0.44),
      maxChart,
    );

    var chartSize =
        (effectiveWidth * _preferredScale).clamp(minChart, maxChart);
    chartSize = chartSize.clamp(0.0, maxChart);

    var headerSpacing = _spacingForChart(chartSize);
    var tileHeight = headerHeight + headerSpacing + chartSize;

    final limit = maxHeight != null && maxHeight.isFinite ? maxHeight : null;
    if (limit != null && limit > 0 && tileHeight > limit + 0.1) {
      final solved = _solveChartSize(
        headerHeight: headerHeight,
        maxHeight: limit,
        maxChart: maxChart,
      );
      chartSize = solved.clamp(0.0, maxChart);
      headerSpacing = _spacingForChart(chartSize);
      tileHeight = headerHeight + headerSpacing + chartSize;
    }

    return _SlotStatusGeometry(
      chartSize: chartSize,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final maxHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : null;

        return Obx(() {
          final data = controller.slotStatusCount;
          final total = data.values.fold<int>(0, (sum, v) => sum + v);

          final slices = <_Slice>[
            _Slice('Testing', data['Testing'] ?? 0, const Color(0xFF42A5F5)),
            _Slice('Pass', data['Pass'] ?? 0, const Color(0xFF4CAF50)),
            _Slice('Fail', data['Fail'] ?? 0, const Color(0xFFE53935)),
            _Slice('Waiting', data['Waiting'] ?? 0, const Color(0xFFFFA726)),
            _Slice('NotUsed', data['NotUsed'] ?? 0, const Color(0xFF90A4AE)),
          ].where((slice) => slice.value > 0).toList();

          final geometry = _resolveGeometry(
            width: maxWidth,
            headerHeight: headerHeight,
            maxHeight: maxHeight,
          );
          final chartSize = geometry.chartSize;
          final headerSpacing = geometry.headerSpacing;

          final visualSize =
              chartSize > 0 ? chartSize * 0.88 : math.min(maxWidth, _minChartSize);

          final totalStyle = textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: (visualSize * 0.24).clamp(16.0, 22.0),
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
              ) ??
              TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: (visualSize * 0.26).clamp(18.0, 24.0),
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
              );

          final slotLabel = '$total slot';

          final sectionTitleStyle = textTheme.bodyMedium?.copyWith(
                fontSize: (visualSize * 0.11).clamp(9.5, 12.0),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ) ??
              TextStyle(
                fontSize: (visualSize * 0.125).clamp(10.0, 13.0),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              );

          Widget chart;
          if (total == 0) {
            chart = Container(
              width: visualSize,
              height: visualSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.12),
                  width: 9,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'No data',
                style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ) ??
                    TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            );
          } else {
            chart = SizedBox(
              width: visualSize,
              height: visualSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: visualSize * 0.02,
                      centerSpaceRadius: visualSize * 0.36,
                      startDegreeOffset: -90,
                      sections: [
                        for (final slice in slices)
                          PieChartSectionData(
                            value: slice.value.toDouble(),
                            color: slice.color,
                            radius: visualSize * 0.44,
                            title: _titleForSlice(slice, total),
                            titleStyle: sectionTitleStyle,
                            titlePositionPercentageOffset: 0.55,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    slotLabel,
                    style: totalStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'SLOT STATUS',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: headerSpacing),
                chart,
              ],
            ),
          );
        });
      },
    );
  }
}

class _SlotStatusGeometry {
  const _SlotStatusGeometry({
    required this.chartSize,
    required this.headerSpacing,
    required this.tileHeight,
  });

  final double chartSize;
  final double headerSpacing;
  final double tileHeight;
}

class _Slice {
  final String label;
  final int value;
  final Color color;

  _Slice(this.label, this.value, this.color);
}

String _titleForSlice(_Slice slice, int total) {
  if (total <= 0) return '';
  final percent = slice.value / total;
  if (percent < 0.07 && slice.value < 5) {
    return '';
  }
  final label = _shortLabel(slice.label);
  return '$label ${slice.value}';
}

String _shortLabel(String label) {
  switch (label) {
    case 'Testing':
      return 'Test';
    case 'Waiting':
      return 'Wait';
    case 'NotUsed':
      return 'Idle';
    default:
      return label;
  }
}
