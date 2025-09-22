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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : double.infinity;
        double chartCap = rawWidth;
        if (maxHeight.isFinite) {
          chartCap = math.min(chartCap, math.max(70.0, maxHeight - 90));
        }
        final chartSize = chartCap.clamp(70.0, 116.0).toDouble();
        final sectionRadius = chartSize * 0.36;
        final centerRadius = chartSize * 0.32;
        final sectionSpacing = chartSize * 0.02;
        final legendSpacing = chartSize < 108 ? 4.0 : 6.0;
        final legendTopGap = chartSize < 100 ? 4.0 : 6.0;
        final titleSpacing = (chartSize * 0.07).clamp(6.0, 11.0).toDouble();
        final hasBoundedHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0;

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

          final baseLegendStyle =
              Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.15);
          final legendColor =
              baseLegendStyle?.color ?? (isDark ? Colors.white70 : Colors.black54);
          final legendStyle = baseLegendStyle ??
              TextStyle(
                fontSize: 11,
                height: 1.15,
                color: legendColor,
              );

          final totalFontSize = (chartSize * 0.19).clamp(13.0, 18.0).toDouble();
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

          final chart = Center(
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
                                color: isDark ? Colors.white10 : Colors.black12,
                                radius: sectionRadius,
                              ),
                            ]
                          : slices
                              .map((e) => PieChartSectionData(
                                    value: e.value.toDouble(),
                                    title: '',
                                    color: e.color,
                                    radius: sectionRadius,
                                  ))
                              .toList(),
                    ),
                  ),
                  Text('$total slot', style: totalStyle),
                ],
              ),
            ),
          );

          final Widget legend = slices.isEmpty
              ? Align(
                  alignment: Alignment.center,
                  child: Text(
                    'No slot activity recorded',
                    textAlign: TextAlign.center,
                    style: legendStyle.copyWith(
                      color: legendColor.withOpacity(0.75),
                    ),
                  ),
                )
              : Align(
                  alignment: Alignment.center,
                  child: Wrap(
                    spacing: legendSpacing,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: slices.map((e) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: e.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text('${e.label}: ${e.value}', style: legendStyle),
                        ],
                      );
                    }).toList(),
                  ),
                );

          final titleStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              );

          final children = <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: titleSpacing),
              child: Text('SLOT STATUS', style: titleStyle, textAlign: TextAlign.center),
            ),
          ];

          if (hasBoundedHeight) {
            children.add(
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    chart,
                    SizedBox(height: legendTopGap),
                    legend,
                  ],
                ),
              ),
            );
          } else {
            children
              ..add(chart)
              ..add(SizedBox(height: legendTopGap))
              ..add(legend);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
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
