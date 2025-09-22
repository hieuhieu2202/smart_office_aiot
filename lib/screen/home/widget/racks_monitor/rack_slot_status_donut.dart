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

        final canShowSideBySide = rawWidth >= 210;

        double chartCap = canShowSideBySide ? rawWidth * 0.58 : rawWidth;
        if (maxHeight.isFinite) {
          final heightAllowance =
              canShowSideBySide ? math.max(64.0, maxHeight - 48) : math.max(70.0, maxHeight - 92);
          chartCap = math.min(chartCap, heightAllowance);
        }
        final chartSize = chartCap.clamp(66.0, canShowSideBySide ? 104.0 : 112.0).toDouble();
        final sectionRadius = chartSize * 0.46;
        final centerRadius = sectionRadius * 0.58;
        final sectionSpacing = chartSize * 0.024;
        final legendTopGap = canShowSideBySide
            ? (chartSize * 0.04).clamp(4.0, 6.0).toDouble()
            : (chartSize * 0.07).clamp(6.0, 10.0).toDouble();
        final legendSideGap = (chartSize * 0.18).clamp(12.0, 18.0).toDouble();
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

          final chart = SizedBox(
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
          );

          final legendChildren = slices
              .map(
                (e) => _LegendEntry(
                  color: e.color,
                  label: e.label,
                  value: e.value,
                  textStyle: legendStyle,
                  center: !canShowSideBySide,
                ),
              )
              .toList();

          final Widget legend = slices.isEmpty
              ? Align(
                  alignment:
                      canShowSideBySide ? Alignment.centerLeft : Alignment.center,
                  child: Text(
                    'No slot activity recorded',
                    textAlign: canShowSideBySide ? TextAlign.left : TextAlign.center,
                    style: legendStyle.copyWith(
                      color: legendColor.withOpacity(0.75),
                    ),
                  ),
                )
              : Align(
                  alignment:
                      canShowSideBySide ? Alignment.centerLeft : Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: canShowSideBySide
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      for (int i = 0; i < legendChildren.length; i++) ...[
                        legendChildren[i],
                        if (i != legendChildren.length - 1)
                          SizedBox(height: canShowSideBySide ? 4 : 6),
                      ],
                    ],
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

          Widget body;
          if (canShowSideBySide) {
            body = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                chart,
                SizedBox(width: legendSideGap),
                Flexible(child: legend),
              ],
            );
          } else {
            body = Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: chart),
                SizedBox(height: legendTopGap),
                legend,
              ],
            );
          }

          if (hasBoundedHeight) {
            children.add(Expanded(child: body));
          } else {
            children.add(body);
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

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    required this.value,
    required this.textStyle,
    this.center = false,
  });

  final Color color;
  final String label;
  final int value;
  final TextStyle textStyle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          center ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Text('$label: $value', style: textStyle),
      ],
    );
  }
}
