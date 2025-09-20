import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../controller/racks_monitor_controller.dart';

class SlotStatusDonut extends StatelessWidget {
  const SlotStatusDonut({super.key, required this.controller});
  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final chartSize = rawWidth.clamp(120.0, 220.0).toDouble();
        final sectionRadius = chartSize * 0.38;
        final centerRadius = chartSize * 0.32;
        final sectionSpacing = chartSize * 0.02;
        final legendSpacing = chartSize < 170 ? 8.0 : 12.0;
        final legendTopGap = chartSize < 170 ? 8.0 : 10.0;

        return Obx(() {
          final data = controller.slotStatusCount;
          final total = data.values.fold<int>(0, (sum, v) => sum + v);

          final List<_Slice> slices = [
            _Slice('Testing', data['Testing'] ?? 0, Colors.blue),
            _Slice('Pass', data['Pass'] ?? 0, Colors.green),
            _Slice('Fail', data['Fail'] ?? 0, Colors.red),
            _Slice('Waiting', data['Waiting'] ?? 0, Colors.orange),
            _Slice('NotUsed', data['NotUsed'] ?? 0, Colors.grey),
          ].where((e) => e.value > 0).toList();

          final legendStyle = Theme.of(context).textTheme.bodySmall;
          final legendColor =
              legendStyle?.color ?? (isDark ? Colors.white70 : Colors.black54);

          final totalFontSize =
              (chartSize * 0.18).clamp(14.0, 22.0).toDouble();
          final totalStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: totalFontSize,
                color: isDark ? Colors.white : Colors.black,
              ) ??
              TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: totalFontSize,
                color: isDark ? Colors.white : Colors.black,
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SLOT STATUS', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: chartSize,
                  height: chartSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: sectionSpacing,
                          centerSpaceRadius: centerRadius,
                          startDegreeOffset: -90,
                          sections: slices.isEmpty
                              ? [
                                  PieChartSectionData(
                                    value: 1,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                    radius: sectionRadius,
                                  ),
                                ]
                              : slices.map((e) {
                                  return PieChartSectionData(
                                    value: e.value.toDouble(),
                                    title: '',
                                    color: e.color,
                                    radius: sectionRadius,
                                  );
                                }).toList(),
                        ),
                      ),
                      Text('$total slot', style: totalStyle),
                    ],
                  ),
                ),
              ),
              SizedBox(height: legendTopGap),
              if (slices.isEmpty)
                Text(
                  'No slot activity recorded',
                  style: (legendStyle ?? const TextStyle(fontSize: 12)).copyWith(
                    color: legendColor.withOpacity(0.75),
                  ),
                )
              else
                Wrap(
                  spacing: legendSpacing,
                  runSpacing: 4,
                  children: slices.map((e) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 4),
                          decoration:
                              BoxDecoration(color: e.color, shape: BoxShape.circle),
                        ),
                        Text('${e.label}: ${e.value}', style: legendStyle),
                      ],
                    );
                  }).toList(),
                ),
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
