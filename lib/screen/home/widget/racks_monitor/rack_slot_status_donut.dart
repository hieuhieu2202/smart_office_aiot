import 'dart:math' as math;

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

    final headerStyle =
        textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800) ??
            TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textTheme.labelLarge?.color ?? theme.colorScheme.onSurface,
            );
    final headerFontSize = headerStyle.fontSize ?? 14;
    final headerLineHeight = headerStyle.height ?? textTheme.labelLarge?.height ?? 1.25;
    final headerHeight = headerFontSize * headerLineHeight;

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
          const minChartSize = 120.0;
          const maxChartSize = 220.0;

          final minBound = maxWidth < minChartSize ? math.max(0.0, maxWidth) : minChartSize;
          final maxBound = math.max(minBound, math.min(maxWidth, maxChartSize));

          double chartSize = maxWidth <= 0
              ? minChartSize
              : math.min(math.max(maxWidth, minBound), maxBound);
          double headerSpacing = (chartSize * 0.12).clamp(10.0, 18.0).toDouble();

          if (maxHeight != null && maxHeight.isFinite) {
            final available = maxHeight - headerHeight - headerSpacing;
            if (available > 0) {
              chartSize = math.min(chartSize, available);
              headerSpacing = (chartSize * 0.12).clamp(8.0, 18.0).toDouble();
            }
          }

          chartSize = chartSize.clamp(0.0, maxBound);
          if (maxWidth > 0) {
            chartSize = math.min(chartSize, maxWidth);
          }

          final totalStyle = textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: (chartSize * 0.22).clamp(18.0, 26.0),
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
              ) ??
              TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: (chartSize * 0.22).clamp(18.0, 26.0),
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
              );

          final slotLabel = '$total slot';

          final sectionTitleStyle = textTheme.bodyMedium?.copyWith(
                fontSize: (chartSize * 0.11).clamp(11.0, 14.0),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ) ??
              TextStyle(
                fontSize: (chartSize * 0.11).clamp(11.0, 14.0),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              );

          Widget chart;
          if (total == 0) {
            chart = Container(
              width: chartSize,
              height: chartSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.12),
                  width: 10,
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
              width: chartSize,
              height: chartSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: chartSize * 0.015,
                      centerSpaceRadius: chartSize * 0.38,
                      startDegreeOffset: -90,
                      sections: [
                        for (final slice in slices)
                          PieChartSectionData(
                            value: slice.value.toDouble(),
                            color: slice.color,
                            radius: chartSize * 0.5,
                            title: _titleForSlice(slice, total),
                            titleStyle: sectionTitleStyle,
                            titlePositionPercentageOffset: 0.7,
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

          return SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('SLOT STATUS', style: headerStyle, textAlign: TextAlign.center),
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

class _Slice {
  final String label;
  final int value;
  final Color color;

  _Slice(this.label, this.value, this.color);
}

String _titleForSlice(_Slice slice, int total) {
  if (total <= 0) return '';
  final percent = slice.value / total;
  if (percent < 0.06 && slice.value < 5) {
    return '';
  }
  return '${slice.label}: ${slice.value}';
}
