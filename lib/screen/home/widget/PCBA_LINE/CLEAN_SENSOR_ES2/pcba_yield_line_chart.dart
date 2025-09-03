import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controller/pcba_line_controller.dart';

class PcbaYieldRateLineChart extends StatelessWidget {
  final PcbaLineDashboardController controller;

  const PcbaYieldRateLineChart({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final data = controller.yieldPoints;
    if (data.isEmpty) return const Center(child: Text('No data'));

    final spots = <FlSpot>[];
    final labels = <String>[];
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      spots.add(FlSpot(i.toDouble(), point.yieldRate));
      labels.add(DateFormat('MM/dd').format(point.date));
    }

    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '≫ Yield Rate',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 2.5,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 48),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          index >= 0 && index < labels.length ? labels[index] : '',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: Colors.purpleAccent,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                ),
              ],
              // Hover (tooltip)
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final date = labels[index];
                      final yieldRate = spot.y.toStringAsFixed(2);
                      return LineTooltipItem(
                        'Date: $date\nYieldRate: $yieldRate%',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),

              // Đường target 99%
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: 99,
                  color: Colors.greenAccent,
                  strokeWidth: 2,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (_) => 'Target (99%)',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                  ),
                ),
              ]),
              minY: 0,
              maxY: 100,
            ),
          ),
        ),
      ],
    );
  }
}
