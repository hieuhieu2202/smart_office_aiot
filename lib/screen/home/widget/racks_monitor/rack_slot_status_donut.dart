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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final chartSize = maxWidth.clamp(108.0, 148.0).toDouble();
        final titleSpacing = (chartSize * 0.08).clamp(8.0, 12.0).toDouble();
        final legendSpacing = (chartSize * 0.12).clamp(12.0, 18.0).toDouble();

        final legendBaseStyle = textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.2,
              color: (textTheme.bodySmall?.color ?? theme.colorScheme.onSurface)
                  .withOpacity(isDark ? 0.9 : 0.8),
            ) ??
            TextStyle(
              fontSize: 12,
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

          final totalFontSize = (chartSize * 0.19).clamp(14.0, 20.0).toDouble();
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
                    sectionsSpace: chartSize * 0.04,
                    centerSpaceRadius: chartSize * 0.36,
                    startDegreeOffset: -90,
                    sections: slices.isEmpty
                        ? [
                            PieChartSectionData(
                              value: 1,
                              color: theme.colorScheme.onSurface.withOpacity(0.08),
                              radius: chartSize * 0.48,
                              title: '',
                            ),
                          ]
                        : slices
                            .map(
                              (slice) => PieChartSectionData(
                                value: slice.value.toDouble(),
                                title: '',
                                color: slice.color,
                                radius: chartSize * 0.48,
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
              : Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final slice in slices)
                      _LegendChip(
                        color: slice.color,
                        label: slice.label,
                        value: slice.value,
                        textStyle: legendBaseStyle,
                      ),
                  ],
                );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'SLOT STATUS',
                style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: titleSpacing),
              chart,
              SizedBox(height: legendSpacing),
              legend,
            ],
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
    final background = color.withOpacity(isDark ? 0.22 : 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Text('$label: $value', style: textStyle),
        ],
      ),
    );
  }
}
