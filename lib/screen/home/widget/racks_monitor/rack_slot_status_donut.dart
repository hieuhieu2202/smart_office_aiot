import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/racks_monitor_controller.dart';

class SlotStatusDonut extends StatelessWidget {
  const SlotStatusDonut({
    super.key,
    required this.controller,
    this.showHeader = true,
  });

  final GroupMonitorController controller;
  final bool showHeader;

  static const double _minChartSize = 86.0;
  static const double _maxChartSize = 140.0;
  static const double _preferredScale = 0.7;
  static const double _legendMinHeight = 28.0;
  static const double _legendMaxHeight = 96.0;
  static const double _legendMinSpacing = 10.0;
  static const double _legendMaxSpacing = 20.0;

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
    bool includeLegend = true,
    bool includeHeader = true,
    int legendItemCount = 0,
  }) {
    final headerStyle = headerTextStyle(theme);
    final headerHeight = includeHeader
        ? _headerHeight(headerStyle, theme.textTheme)
        : 0.0;
    final geometry = _resolveGeometry(
      width: width,
      headerHeight: headerHeight,
      includeLegend: includeLegend,
      includeHeader: includeHeader,
      legendItemCount: legendItemCount,
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
    return (chartSize * 0.09).clamp(6.0, 14.0);
  }

  static _SlotStatusGeometry _resolveGeometry({
    required double width,
    required double headerHeight,
    double? maxHeight,
    bool includeLegend = true,
    bool includeHeader = true,
    int legendItemCount = 0,
  }) {
    final effectiveWidth = width.isFinite && width > 0
        ? width
        : _minChartSize;

    final maxChart = math.min(effectiveWidth, _maxChartSize);
    final minChart = math.min(_minChartSize, maxChart);

    var chartSize =
        (effectiveWidth * _preferredScale).clamp(minChart, maxChart);
    chartSize = chartSize.clamp(0.0, maxChart);

    final hasLegend = includeLegend && legendItemCount > 0;

    var headerSpacing = includeHeader ? _spacingForChart(chartSize) : 0.0;
    var legendSpacing =
        hasLegend ? _legendSpacingEstimate(chartSize) : 0.0;
    var legendHeight = hasLegend
        ? _legendHeightEstimate(chartSize, legendItemCount)
        : 0.0;
    var tileHeight = chartSize + legendSpacing + legendHeight;
    if (includeHeader) {
      tileHeight += headerHeight + headerSpacing;
    }

    final limit = maxHeight != null && maxHeight.isFinite ? maxHeight : null;
    if (limit != null && limit > 0 && tileHeight > limit + 0.1) {
      var low = 0.0;
      var high = maxChart;
      var best = 0.0;
      for (var i = 0; i < 24; i++) {
        final mid = (low + high) / 2;
        final spacing = includeHeader ? _spacingForChart(mid) : 0.0;
        final legendSpace =
            hasLegend ? _legendSpacingEstimate(mid) : 0.0;
        final legend = hasLegend
            ? _legendHeightEstimate(mid, legendItemCount)
            : 0.0;
        var total = mid + legendSpace + legend;
        if (includeHeader) {
          total += headerHeight + spacing;
        }
        if (total <= limit) {
          best = mid;
          low = mid;
        } else {
          high = mid;
        }
      }
      chartSize = best.clamp(0.0, maxChart);
      headerSpacing = includeHeader ? _spacingForChart(chartSize) : 0.0;
      legendSpacing = hasLegend ? _legendSpacingEstimate(chartSize) : 0.0;
      legendHeight = hasLegend
          ? _legendHeightEstimate(chartSize, legendItemCount)
          : 0.0;
      tileHeight = chartSize + legendSpacing + legendHeight;
      if (includeHeader) {
        tileHeight += headerHeight + headerSpacing;
      }
    }

    return _SlotStatusGeometry(
      chartSize: chartSize,
      headerSpacing: includeHeader ? headerSpacing : 0.0,
      tileHeight: limit == null ? tileHeight : math.min(tileHeight, limit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final headerStyle = headerTextStyle(theme);
    final headerHeight = showHeader
        ? _headerHeight(headerStyle, textTheme)
        : 0.0;

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

          final hasLegend = slices.isNotEmpty;
          final geometry = _resolveGeometry(
            width: maxWidth,
            headerHeight: headerHeight,
            maxHeight: maxHeight,
            includeLegend: hasLegend,
            includeHeader: showHeader,
            legendItemCount: slices.length,
          );
          final chartSize = geometry.chartSize;
          final headerSpacing = geometry.headerSpacing;

          final visualSize =
              chartSize > 0 ? chartSize : math.min(maxWidth, _minChartSize);

          final totalStyle = textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: (visualSize * 0.26).clamp(18.0, 26.0),
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
              ) ??
              TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: (visualSize * 0.28).clamp(20.0, 28.0),
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
              );

          final slotLabel = '$total slot';

          final legendStyle = textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ) ??
              TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
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
                      sectionsSpace:
                          (visualSize * 0.02).clamp(1.5, visualSize * 0.04),
                      centerSpaceRadius: (visualSize * 0.34).clamp(18.0, 46.0),
                      startDegreeOffset: -90,
                      sections: [
                        for (final slice in slices)
                          PieChartSectionData(
                            value: slice.value.toDouble(),
                            color: slice.color,
                            radius: math.max(visualSize * 0.48, visualSize / 2 - 2),
                            title: '',
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

          final legendSpacing = hasLegend
              ? _legendSpacingEstimate(chartSize)
              : 0.0;

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showHeader) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'SLOT STATUS',
                      style: headerStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: headerSpacing),
                ],
                chart,
                if (slices.isNotEmpty) ...[
                  SizedBox(height: legendSpacing),
                  _SlotStatusLegend(
                    slices: slices,
                    textStyle: legendStyle,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          );
        });
      },
    );
  }
}

double _legendHeightEstimate(double chartSize, int itemCount) {
  if (chartSize <= 0 || itemCount <= 0) {
    return 0;
  }

  final itemsPerRow = chartSize < 110 ? 2 : 3;
  final rawRows = (itemCount / itemsPerRow).ceil();
  final rowCount = rawRows < 1
      ? 1
      : (rawRows > 4 ? 4 : rawRows);
  final rowHeight = (chartSize * 0.18).clamp(20.0, 26.0);
  final totalHeight = rowCount * rowHeight +
      (rowCount > 1 ? (rowCount - 1) * 6.0 : 0.0);

  return totalHeight.clamp(
    SlotStatusDonut._legendMinHeight,
    SlotStatusDonut._legendMaxHeight,
  );
}

double _legendSpacingEstimate(double chartSize) {
  if (chartSize <= 0) {
    return 0;
  }
  return (chartSize * 0.12).clamp(
    SlotStatusDonut._legendMinSpacing,
    SlotStatusDonut._legendMaxSpacing,
  );
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

class _SlotStatusLegend extends StatelessWidget {
  const _SlotStatusLegend({
    required this.slices,
    required this.textStyle,
    required this.isDark,
  });

  final List<_Slice> slices;
  final TextStyle textStyle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final baseStyle = textStyle.copyWith(
      color: textStyle.color?.withOpacity(isDark ? 0.88 : 0.9),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth.isFinite && constraints.maxWidth < 160
            ? 12.0
            : 18.0;
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: spacing,
          runSpacing: 6,
          children: [
            for (final slice in slices)
              _LegendEntry(
                slice: slice,
                label: _shortLabel(slice.label),
                textStyle: baseStyle,
              ),
          ],
        );
      },
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.slice,
    required this.label,
    required this.textStyle,
  });

  final _Slice slice;
  final String label;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: slice.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: slice.color.withOpacity(0.32),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text('$label ${slice.value}', style: textStyle),
      ],
    );
  }
}
