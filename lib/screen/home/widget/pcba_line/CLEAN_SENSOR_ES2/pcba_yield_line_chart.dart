import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controller/pcba_line_controller.dart';

class PcbaYieldRateLineChart extends StatelessWidget {
  final PcbaLineDashboardController controller;
  const PcbaYieldRateLineChart({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final data = controller.yieldPoints;
    if (data.isEmpty) return const Center(child: Text('No data'));

    final spots = <FlSpot>[];
    final labels = <String>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].yieldRate.toDouble()));
      labels.add(DateFormat('MM/dd').format(data[i].date));
    }

    // padding 2 đầu trục X để không bị cắt dot/line
    final double minX = -0.9;
    final double maxX = (spots.length - 1).toDouble() + 0.9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yield Rate',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black, // ✅ theo theme
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 2.5,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: 0.0,
              maxY: 102.0, // dư đầu trên để không “đè” đường target
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      const eps = 0.001;
                      final isIntTick = (value - value.roundToDouble()).abs() < eps;
                      if (!isIntTick) return const SizedBox.shrink();

                      final idx = value.round();
                      if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels[idx],
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black, // ✅ theo theme
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0x33FFFFFF) : const Color(0x33000000), // ✅ theo theme
                    width: 1,
                  ),
                  right: const BorderSide(color: Colors.transparent),
                  top: const BorderSide(color: Colors.transparent),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: const Color(0xFFB44DFF), // tím
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  // màu nền tooltip theo theme (API mới)
                  getTooltipColor: (_) => isDark ? Colors.black87 : Colors.white,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((s) {
                      final i = s.x.toInt();
                      final date = (i >= 0 && i < labels.length) ? labels[i] : '';
                      return LineTooltipItem(
                        'Date: $date\nYieldRate: ${s.y.toStringAsFixed(2)}%',
                        TextStyle(color: isDark ? Colors.white : Colors.black87), // ✅
                      );
                    }).toList();
                  },
                ),
              ),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: 99.0,
                  color: Colors.greenAccent,
                  strokeWidth: 2,
                  dashArray: const [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (_) => 'Target (99%)',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
