import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/global_color.dart';

class PTHDashboardRuntimeChart extends StatelessWidget {
  final Map data;
  const PTHDashboardRuntimeChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final runtime = data['runtime'];
    final machines = runtime?['runtimeMachine'] as List? ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? GlobalColors.labelDark : GlobalColors.labelLight;

    if (machines.isEmpty) {
      return const Text("Không có dữ liệu runtime máy.");
    }

    // Lấy tất cả giờ xuất hiện trong data (trục X)
    final allHours = <String>{};
    for (final m in machines) {
      for (final st in m['runtimeMachineData']) {
        for (final r in st['result']) {
          allHours.add(r['time'].toString());
        }
      }
    }
    final hours = allHours.toList()..sort();

    return Card(
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: machines.length,
            itemBuilder: (_, idx) {
              final machine = machines[idx];
              final runData = machine['runtimeMachineData'].firstWhere((d) => d['status'] == 'Run', orElse: () => null);
              final idleData = machine['runtimeMachineData'].firstWhere((d) => d['status'] == 'Idle', orElse: () => null);

              Map<String, dynamic> runMap = {};
              Map<String, dynamic> idleMap = {};

              if (runData != null) {
                for (final r in runData['result']) {
                  runMap[r['time'].toString()] = r['value'] ?? 0;
                }
              }
              if (idleData != null) {
                for (final r in idleData['result']) {
                  idleMap[r['time'].toString()] = r['value'] ?? 0;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Runtime ${machine['machine']}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: true, horizontalInterval: 10),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) => Text(
                                meta.formattedValue,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: labelColor,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                return idx < hours.length
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          hours[idx],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: labelColor,
                                          ),
                                        ),
                                      )
                                    : const SizedBox();
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: List.generate(hours.length, (hIdx) {
                          final hour = hours[hIdx];
                          return BarChartGroupData(
                            x: hIdx,
                            barRods: [
                              BarChartRodData(
                                width: 11,
                                toY: (runMap[hour] ?? 0).toDouble(),
                                color: const Color(0xFF4CAF50), // Run
                                borderRadius: BorderRadius.circular(3),
                              ),
                              BarChartRodData(
                                width: 11,
                                toY: (idleMap[hour] ?? 0).toDouble(),
                                color: const Color(0xFFF44336), // Idle
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                            showingTooltipIndicators: [0, 1],
                          );
                        }),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIdx, rod, rodIdx) {
                              final hour = hours[group.x.toInt()];
                              return BarTooltipItem(
                                "${rodIdx == 0 ? "Run" : "Idle"}\nGiờ $hour: ${rod.toY}",
                                const TextStyle(color: Colors.white, fontSize: 13),
                              );
                            },
                          ),
                        ),

                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
