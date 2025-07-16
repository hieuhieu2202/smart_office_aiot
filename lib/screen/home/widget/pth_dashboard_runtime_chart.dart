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
    final labelColor = isDark ? GlobalColors.labelDark : GlobalColors.labelLight;
    final bgColor = isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;

    if (machines.isEmpty) {
      return Card(
        color: bgColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const SizedBox(
          height: 230,
          child: Center(child: Text('No data available')),
        ),
      );
    }

    // Chỉ hiển thị 1 máy
    final machine = machines[0];
    final runData = machine['runtimeMachineData'].firstWhere((d) => d['status'] == 'Run', orElse: () => null);
    final idleData = machine['runtimeMachineData'].firstWhere((d) => d['status'] == 'Idle', orElse: () => null);

    // Lấy danh sách giờ (x-axis)
    final allHours = <String>{};
    if (runData != null) {
      for (final r in runData['result']) {
        allHours.add(r['time'].toString().padLeft(2, '0') + ":00");
      }
    }
    if (idleData != null) {
      for (final r in idleData['result']) {
        allHours.add(r['time'].toString().padLeft(2, '0') + ":00");
      }
    }
    final hours = allHours.toList()..sort();

    Map<String, int> runMap = {};
    Map<String, int> idleMap = {};
    if (runData != null) {
      for (final r in runData['result']) {
        runMap[r['time'].toString().padLeft(2, '0') + ":00"] = (r['value'] ?? 0).toInt();
      }
    }
    if (idleData != null) {
      for (final r in idleData['result']) {
        idleMap[r['time'].toString().padLeft(2, '0') + ":00"] = (r['value'] ?? 0).toInt();
      }
    }

    // Chuẩn hóa: tổng luôn là 60 (hoặc 0 nếu không có dữ liệu)
    final barMax = 60.0;

    return Card(
      color: bgColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Runtime Analysis - ${machine['machine']}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 10),

            // Hiển thị số phút trên đầu từng cột
            SizedBox(
              height: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(hours.length, (i) {
                  final hour = hours[i];
                  final run = runMap[hour] ?? 0;
                  final idle = idleMap[hour] ?? 0;
                  if ((run + idle) == 0) {
                    return const SizedBox(width: 34); // Không có data, để trống
                  }
                  return Column(
                    children: [
                      if (run > 0)
                        Text(
                          "$run",
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (idle > 0)
                        Text(
                          "$idle",
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFFF44336),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),

            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: barMax,
                  minY: 0,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 10,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: labelColor.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value == value.toInt() ? value.toInt().toString() : '',
                          style: TextStyle(fontSize: 11, color: labelColor),
                        ),
                        interval: 10,
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          return idx < hours.length
                              ? Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              hours[idx],
                              style: TextStyle(fontSize: 14, color: labelColor, fontWeight: FontWeight.w500),
                            ),
                          )
                              : const SizedBox();
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(hours.length, (hIdx) {
                    final hour = hours[hIdx];
                    final run = runMap[hour] ?? 0;
                    final idle = idleMap[hour] ?? 0;
                    if ((run + idle) == 0) {
                      return BarChartGroupData(x: hIdx, barRods: [
                        BarChartRodData(
                          toY: 0,
                          width: 26,
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        )
                      ]);
                    }
                    return BarChartGroupData(
                      x: hIdx,
                      barRods: [
                        BarChartRodData(
                          toY: barMax,
                          width: 26,
                          rodStackItems: [
                            BarChartRodStackItem(0, run.toDouble(), const Color(0xFF4CAF50)),
                            BarChartRodStackItem(run.toDouble(), barMax, const Color(0xFFF44336)),
                          ],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    );
                  }),
                  groupsSpace: 18,
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: BarTouchTooltipData(

                      tooltipRoundedRadius: 10,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      tooltipMargin: 8,
                      fitInsideVertically: true,
                      fitInsideHorizontally: true,
                      getTooltipItem: (group, groupIdx, rod, rodIdx) {
                        final hour = hours[group.x.toInt()];
                        final run = runMap[hour] ?? 0;
                        final idle = idleMap[hour] ?? 0;
                        if ((run + idle) == 0) return null;
                        return BarTooltipItem(
                          "Run: $run\nIdle: $idle",
                          const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(color: const Color(0xFF4CAF50)),
                const SizedBox(width: 5),
                Text("Run", style: TextStyle(color: labelColor, fontSize: 14)),
                const SizedBox(width: 20),
                _legendDot(color: const Color(0xFFF44336)),
                const SizedBox(width: 5),
                Text("Idle", style: TextStyle(color: labelColor, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _legendDot({required Color color}) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7.5),
      ),
    );
  }
}
