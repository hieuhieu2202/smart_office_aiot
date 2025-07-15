import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/global_color.dart';

class PTHDashboardOutputChart extends StatelessWidget {
  final Map data;
  const PTHDashboardOutputChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final output = data['output'] as List? ?? [];
    if (output.isEmpty) {
      return const Text("Không có dữ liệu output.");
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = output.map((e) => (e['section'] ?? e['SECTION']).toString()).toList();
    return Card(
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          height: 210,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, horizontalInterval: 10),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      return idx < sections.length
                          ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(sections[idx], style: const TextStyle(fontSize: 12)),
                      )
                          : const SizedBox();
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: List.generate(sections.length, (idx) {
                final row = output[idx];
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      width: 12,
                      toY: (row['pass'] ?? row['PASS'] ?? 0).toDouble(),
                      color: const Color(0xFF2196F3), // PASS
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      width: 12,
                      toY: (row['fail'] ?? row['FAIL'] ?? 0).toDouble(),
                      color: const Color(0xFFFF9800), // FAIL
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                  showingTooltipIndicators: [0, 1],
                );
              }),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIdx, rod, rodIdx) {
                    final sec = sections[group.x.toInt()];
                    return BarTooltipItem(
                      "${rodIdx == 0 ? "PASS" : "FAIL"}\nSection $sec: ${rod.toY}",
                      const TextStyle(color: Colors.white, fontSize: 13),
                    );
                  },
                ),
              ),

            ),
          ),
        ),
      ),
    );
  }
}
