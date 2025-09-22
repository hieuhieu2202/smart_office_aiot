import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/racks_monitor_controller.dart';
import 'rack_chart_footer.dart';

class SlotStatusDonut extends StatelessWidget {
  const SlotStatusDonut({
    super.key,
    required this.controller,
    this.showHeader = true,
  });

  final GroupMonitorController controller;
  final bool showHeader;

  static const double _minChartSize = 78.0;
  static const double _maxChartSize = 116.0;
  static const double _preferredScale = 0.54;
  static const double _legendMinHeight = 24.0;
  static const double _legendMaxHeight = 88.0;
  static const double _legendMinSpacing = 12.0;
  static const double _legendMaxSpacing = 22.0;
  static const double _legendHeaderSpacingMin = 10.0;
  static const double _legendHeaderSpacingMax = 18.0;

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
    required ThemeData theme,
    bool includeLegend = true,
    bool includeHeader = true,
    int legendItemCount = 0,
  }) {
    final headerStyle = headerTextStyle(theme);
    final topHeaderHeight = includeHeader
        ? _headerBandHeight(headerStyle, theme.textTheme)
        : 0.0;
    final geometry = _resolveGeometry(
      width: width,
      topHeaderHeight: topHeaderHeight,
      includeLegend: includeLegend,
      includeHeader: includeHeader,
      legendItemCount: legendItemCount,
    );
    return geometry.tileHeight;
  }

  static double _headerBandHeight(
    TextStyle headerStyle,
    TextTheme textTheme,
  ) {
    return ChartCardHeader.heightForStyle(headerStyle, textTheme);
  }

  static double _topSpacingForChart(double chartSize) {
    if (chartSize <= 0) return 0;
    return (chartSize * 0.085).clamp(10.0, 18.0);
  }

  static double _bottomSpacingForChart(double chartSize) {
    if (chartSize <= 0) return 0;
    return (chartSize * 0.07).clamp(10.0, 20.0);
  }

  static double _legendSpacingWithHeader(double chartSize) {
    if (chartSize <= 0) {
      return _legendHeaderSpacingMin;
    }
    return (chartSize * 0.09)
        .clamp(_legendHeaderSpacingMin, _legendHeaderSpacingMax);
  }

  static _SlotStatusGeometry _resolveGeometry({
    required double width,
    required double topHeaderHeight,
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

    var topSpacing = includeHeader ? _topSpacingForChart(chartSize) : 0.0;
    var bottomSpacing = includeHeader ? _bottomSpacingForChart(chartSize) : 0.0;
    var legendHeight = hasLegend
        ? _legendHeightEstimate(chartSize, legendItemCount)
        : 0.0;
    var legendSpacing = hasLegend
        ? (includeHeader
            ? _legendSpacingWithHeader(chartSize)
            : math.max(_legendSpacingEstimate(chartSize), 12.0))
        : 0.0;
    var tileHeight = chartSize + legendHeight + legendSpacing;
    if (includeHeader) {
      tileHeight += topHeaderHeight + topSpacing + bottomSpacing;
    }

    final limit = maxHeight != null && maxHeight.isFinite ? maxHeight : null;
    if (limit != null && limit > 0 && tileHeight > limit + 0.1) {
      var low = 0.0;
      var high = maxChart;
      var best = 0.0;
      for (var i = 0; i < 24; i++) {
        final mid = (low + high) / 2;
        final spacingTop = includeHeader ? _topSpacingForChart(mid) : 0.0;
        final spacingBottom = includeHeader ? _bottomSpacingForChart(mid) : 0.0;
        final legend = hasLegend
            ? _legendHeightEstimate(mid, legendItemCount)
            : 0.0;
        final legendSpace = hasLegend
            ? (includeHeader
                ? _legendSpacingWithHeader(mid)
                : math.max(_legendSpacingEstimate(mid), 12.0))
            : 0.0;
        var total = mid + legend + legendSpace;
        if (includeHeader) {
          total += topHeaderHeight + spacingTop + spacingBottom;
        }
        if (total <= limit) {
          best = mid;
          low = mid;
        } else {
          high = mid;
        }
      }
      chartSize = best.clamp(0.0, maxChart);
      topSpacing = includeHeader ? _topSpacingForChart(chartSize) : 0.0;
      bottomSpacing = includeHeader ? _bottomSpacingForChart(chartSize) : 0.0;
      legendSpacing = hasLegend
          ? (includeHeader
              ? _legendSpacingWithHeader(chartSize)
              : math.max(_legendSpacingEstimate(chartSize), 12.0))
          : 0.0;
      legendHeight = hasLegend
          ? _legendHeightEstimate(chartSize, legendItemCount)
          : 0.0;
      tileHeight = chartSize + legendHeight + legendSpacing;
      if (includeHeader) {
        tileHeight += topHeaderHeight + topSpacing + bottomSpacing;
      }
    }

    return _SlotStatusGeometry(
      chartSize: chartSize,
      topSpacing: includeHeader ? topSpacing : 0.0,
      bottomSpacing: includeHeader ? bottomSpacing : 0.0,
      tileHeight: limit == null ? tileHeight : math.min(tileHeight, limit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final headerStyle = headerTextStyle(theme);
    final topHeaderHeight = showHeader
        ? _headerBandHeight(headerStyle, textTheme)
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

          final rawSlices = <MapEntry<String, int>>[
            MapEntry('Testing', data['Testing'] ?? 0),
            MapEntry('Pass', data['Pass'] ?? 0),
            MapEntry('Fail', data['Fail'] ?? 0),
            MapEntry('Waiting', data['Waiting'] ?? 0),
            MapEntry('NotUsed', data['NotUsed'] ?? 0),
          ].where((entry) => entry.value > 0).toList();

          final slices = [
            for (final entry in rawSlices)
              _Slice(
                entry.key,
                entry.value,
                total == 0 ? 0 : (entry.value / total) * 100,
                _sliceColor(entry.key, theme),
              ),
          ];

          final hasLegend = slices.isNotEmpty;
          final geometry = _resolveGeometry(
            width: maxWidth,
            topHeaderHeight: topHeaderHeight,
            maxHeight: maxHeight,
            includeLegend: hasLegend,
            includeHeader: showHeader,
            legendItemCount: slices.length,
          );
          final chartSize = geometry.chartSize;
          final topSpacing = geometry.topSpacing;
          final bottomSpacing = geometry.bottomSpacing;

          final visualSize =
              chartSize > 0 ? chartSize : math.min(maxWidth, _minChartSize);

          final totalStyle = textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: (visualSize * 0.24).clamp(17.0, 24.0),
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
              ) ??
              TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: (visualSize * 0.25).clamp(18.0, 25.0),
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
          final sliceLabelStyle = TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: (visualSize * 0.14).clamp(10.0, 14.0),
            letterSpacing: -0.2,
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
                          (visualSize * 0.018).clamp(1.0, visualSize * 0.035),
                      centerSpaceRadius: (visualSize * 0.36).clamp(18.0, 42.0),
                      startDegreeOffset: -90,
                      sections: [
                        for (final slice in slices)
                          () {
                            final showTitle = slice.percentage >= 3.5;
                            final label = showTitle ? slice.percentageLabel : '';
                            final useDarkText = slice.color.computeLuminance() > 0.6;
                            final titleColor = useDarkText
                                ? Colors.black.withOpacity(0.78)
                                : Colors.white;
                            final shadowColor = useDarkText
                                ? Colors.white.withOpacity(0.55)
                                : Colors.black.withOpacity(0.45);
                            final positionOffset = slice.percentage >= 25
                                ? 0.52
                                : slice.percentage >= 12
                                    ? 0.62
                                    : 0.74;
                            return PieChartSectionData(
                              value: slice.value.toDouble(),
                              color: slice.color,
                              radius: math.max(
                                visualSize * 0.46,
                                visualSize / 2 - 4,
                              ),
                              title: label,
                              titleStyle: sliceLabelStyle.copyWith(
                                color: titleColor,
                                shadows: [
                                  Shadow(color: shadowColor, blurRadius: 6),
                                ],
                              ),
                              titlePositionPercentageOffset: positionOffset,
                            );
                          }(),
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

          final legendWidget = hasLegend
              ? _SlotStatusLegend(
                  slices: slices,
                  textStyle: legendStyle,
                  isDark: isDark,
                )
              : null;

          final headerWidget = showHeader
              ? ChartCardHeader(
                  label: 'SLOT STATUS',
                  textStyle: headerStyle,
                )
              : null;

          final legendSpacing = hasLegend
              ? (showHeader
                  ? _legendSpacingWithHeader(chartSize)
                  : math.max(_legendSpacingEstimate(chartSize), 12.0))
              : 0.0;

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
                    child: Center(child: chart),
                  ),
                  if (legendWidget != null) ...[
                    if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
                    if (legendSpacing > 0) SizedBox(height: legendSpacing),
                    Center(child: legendWidget),
                  ],
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
              Center(child: chart),
              if (legendWidget != null) ...[
                if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
                if (legendSpacing > 0) SizedBox(height: legendSpacing),
                Center(child: legendWidget),
              ],
            ],
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

  final itemsPerRow = chartSize < 108 ? 2 : 3;
  final rawRows = (itemCount / itemsPerRow).ceil();
  final rowCount = rawRows < 1
      ? 1
      : (rawRows > 4 ? 4 : rawRows);
  final rowHeight = (chartSize * 0.17).clamp(18.0, 24.0);
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
    required this.topSpacing,
    required this.bottomSpacing,
    required this.tileHeight,
  });

  final double chartSize;
  final double topSpacing;
  final double bottomSpacing;
  final double tileHeight;
}

class _Slice {
  final String label;
  final int value;
  final double percentage;
  final Color color;

  _Slice(this.label, this.value, this.percentage, this.color);

  String get percentageLabel {
    if (percentage <= 0) {
      return '0%';
    }
    final display = percentage >= 10
        ? percentage.round().toString()
        : percentage.toStringAsFixed(1);
    return '$display%';
  }
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

Color _sliceColor(String label, ThemeData theme) {
  switch (label) {
    case 'Testing':
      return const Color(0xFF42A5F5);
    case 'Pass':
      return const Color(0xFF4CAF50);
    case 'Fail':
      return const Color(0xFFE53935);
    case 'Waiting':
      return const Color(0xFFFFA726);
    case 'NotUsed':
      return const Color(0xFF90A4AE);
    default:
      return theme.colorScheme.primary;
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
            ? 14.0
            : 20.0;
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: spacing,
          runSpacing: 10,
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
          width: 9,
          height: 9,
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
        const SizedBox(width: 5),
        Text('$label ${slice.value}', style: textStyle),
      ],
    );
  }
}

