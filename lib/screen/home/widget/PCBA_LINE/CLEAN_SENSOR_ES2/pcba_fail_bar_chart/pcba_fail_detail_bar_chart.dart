import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PcbaFailDetailBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> machineData;

  const PcbaFailDetailBarChart({super.key, required this.machineData});

  static const double _barWidth     = 44.0;
  static const double _labelFont    = 14.0;
  static const double _labelHeight  = 16.0;
  static const double _labelPad     = 6.0;

  @override
  Widget build(BuildContext context) {
    final groups = <BarChartGroupData>[];
    final labels = <String>[];
    final values = <double>[];

    for (int i = 0; i < machineData.length; i++) {
      final m    = machineData[i];
      final name = (m['MachineName'] ?? 'Unknown').toString();
      final fail = ((m['Fail'] ?? 0) as num).toDouble();

      values.add(fail);
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: fail,
              width: _barWidth,
              color: Colors.purpleAccent,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
      labels.add(name);
    }

    final double maxY = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final double chartMaxY = maxY == 0 ? 1.0 : maxY * 1.2;

    return LayoutBuilder(
      builder: (context, c) {
        final double w = c.maxWidth;
        final double h = c.maxHeight;
        final int n = groups.length;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY,
                  barGroups: groups,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= labels.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              labels[i],
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),

            // Overlay số trên đỉnh cột
            IgnorePointer(
              child: Stack(
                children: List.generate(n, (i) {
                  final double v = values[i];

                  final double centerX = w * (((i + 1) / (n + 1))).toDouble();
                  final double alignX = (centerX / w) * 2.0 - 1.0;

                  final double barTopPx = (1.0 - (v / chartMaxY)) * h;
                  final double labelTop =
                  (barTopPx - _labelHeight - _labelPad).clamp(0.0, h) as double;

                  return Align(
                    alignment: Alignment(alignX, -1.0),
                    child: Padding(
                      padding: EdgeInsets.only(top: labelTop),
                      child: SizedBox(
                        width: _barWidth,
                        height: _labelHeight,
                        child: Center(
                          child: Text(
                            v.toInt().toString(),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: _labelFont,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}
