import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/pth_avi_controller.dart';

class PthAviChartSection extends StatelessWidget {
  final PthAviController controller;
  const PthAviChartSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final passList = controller.getPassList();
      final failList = controller.getFailList();
      final yieldList = controller.getYieldRateList();
      final labels = controller.getDateLabels();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text("Pass / Fail Chart", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (passList + failList).fold<double>(0, (max, e) => e > max ? e.toDouble() : max.toDouble()) + 10,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, interval: 10),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) return const SizedBox();
                        return Text(labels[index], style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(passList.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: passList[i].toDouble(), color: Colors.green, width: 7),
                      BarChartRodData(toY: failList[i].toDouble(), color: Colors.red, width: 7),
                    ],
                    showingTooltipIndicators: [0, 1],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Yield Rate Chart", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(yieldList.length, (i) => FlSpot(i.toDouble(), yieldList[i])),
                    isCurved: true,
                    barWidth: 2,
                    color: Colors.blueAccent,
                    dotData: FlDotData(show: true),
                  )
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) return const SizedBox();
                        return Text(labels[index], style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, interval: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
