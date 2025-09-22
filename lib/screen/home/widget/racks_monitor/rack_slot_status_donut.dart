import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/racks_monitor_controller.dart';

class SlotStatusDonut extends StatelessWidget {
  const SlotStatusDonut({super.key, required this.controller});
  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final baseHeaderStyle =
        textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700) ??
            TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textTheme.labelLarge?.color ?? theme.colorScheme.onSurface,
            );
    final headerFontSize = baseHeaderStyle.fontSize ?? 14;
    final headerHeight =
        headerFontSize * (baseHeaderStyle.height ?? textTheme.labelLarge?.height ?? 1.25);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final maxHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : null;

        final legendBaseStyle = textTheme.bodySmall?.copyWith(
              fontSize: 11,
              height: 1.2,
              color: (textTheme.bodySmall?.color ?? theme.colorScheme.onSurface)
                  .withOpacity(isDark ? 0.9 : 0.8),
            ) ??
            TextStyle(
              fontSize: 11,
              height: 1.2,
              color: theme.colorScheme.onSurface.withOpacity(isDark ? 0.9 : 0.8),
            );

        final totalColor = isDark ? Colors.white : Colors.black;

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

          int columnsForWidth(double width, int itemCount) {
            if (itemCount <= 1) return 1;
            if (width >= 280 && itemCount >= 3) return 3;
            if (width >= 110 && itemCount >= 2) return 2;
            return 1;
          }

          final legendColumns = columnsForWidth(maxWidth, slices.length);
          final legendRows = slices.isEmpty
              ? 1
              : ((slices.length + legendColumns - 1) ~/ legendColumns);

          const minChartSize = 70.0;
          final maxChartByWidth =
              (maxWidth * 0.62).clamp(minChartSize, 96.0).toDouble();
          double chartSize = maxChartByWidth;
          double titleSpacing = (chartSize * 0.08).clamp(8.0, 12.0).toDouble();
          double legendSpacing = (chartSize * 0.12).clamp(10.0, 16.0).toDouble();

          if (maxHeight != null) {
            final baseLineHeight =
                (legendBaseStyle.fontSize ?? 11) * (legendBaseStyle.height ?? 1.2);
            final rowHeight = baseLineHeight + 10;
            final legendHeightEstimate = legendRows <= 0
                ? 0
                : (legendRows * rowHeight) + ((legendRows - 1) * 8);
            final reservedHeight = headerHeight +
                titleSpacing +
                legendSpacing +
                legendHeightEstimate;
            final availableForChart = maxHeight - reservedHeight;
            chartSize = availableForChart.clamp(minChartSize, maxChartByWidth);
            titleSpacing = (chartSize * 0.08).clamp(8.0, 12.0).toDouble();
            legendSpacing = (chartSize * 0.12).clamp(10.0, 16.0).toDouble();
          }

          final totalFontSize = (chartSize * 0.2).clamp(13.0, 18.0).toDouble();
          final totalStyle = textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: totalFontSize,
                color: totalColor,
              ) ??
              TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: totalFontSize,
                color: totalColor,
              );

          final chart = SizedBox(
            width: chartSize,
            height: chartSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: chartSize * 0.035,
                    centerSpaceRadius: chartSize * 0.38,
                    startDegreeOffset: -90,
                    sections: slices.isEmpty
                        ? [
                            PieChartSectionData(
                              value: 1,
                              color: theme.colorScheme.onSurface.withOpacity(0.08),
                              radius: chartSize * 0.46,
                              title: '',
                            ),
                          ]
                        : slices
                            .map(
                              (slice) => PieChartSectionData(
                                value: slice.value.toDouble(),
                                title: '',
                                color: slice.color,
                                radius: chartSize * 0.46,
                              ),
                            )
                            .toList(),
                  ),
                ),
                Text(
                  total == 1 ? '1 slot' : '$total slots',
                  style: totalStyle,
                ),
              ],
            ),
          );

          final legend = slices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'No slot activity recorded',
                    textAlign: TextAlign.center,
                    style: legendBaseStyle.copyWith(
                      color: legendBaseStyle.color?.withOpacity(0.7),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, legendConstraints) {
                    final width = legendConstraints.maxWidth.isFinite &&
                            legendConstraints.maxWidth > 0
                        ? legendConstraints.maxWidth
                        : maxWidth;
                    final columns = columnsForWidth(width, slices.length);
                    const spacing = 10.0;
                    const runSpacing = 8.0;
                    final itemWidth = columns <= 1
                        ? width
                        : (width - ((columns - 1) * spacing)) / columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: runSpacing,
                      alignment:
                          columns <= 1 ? WrapAlignment.center : WrapAlignment.start,
                      runAlignment: WrapAlignment.center,
                      children: [
                        for (final slice in slices)
                          SizedBox(
                            width: itemWidth,
                            child: _LegendChip(
                              color: slice.color,
                              label: slice.label,
                              value: slice.value,
                              textStyle: legendBaseStyle,
                            ),
                          ),
                      ],
                    );
                  },
                );

          return SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'SLOT STATUS',
                  style: baseHeaderStyle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: titleSpacing),
                chart,
                SizedBox(height: legendSpacing),
                legend,
              ],
            ),
          );
        });
      },
    );
  }
}

class _Slice {
  final String label;
  final int value;
  final Color color;

  _Slice(this.label, this.value, this.color);
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.value,
    required this.textStyle,
  });

  final Color color;
  final String label;
  final int value;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = color.withOpacity(isDark ? 0.55 : 0.4);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: textStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
