import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../config/global_color.dart';

const _runColor = Color(0xFF4CAF50);
const _idleColor = Color(0xFFF44336);

class PTHDashboardRuntimeChart extends StatelessWidget {
  final Map data;

  const PTHDashboardRuntimeChart({super.key, required this.data});

  String _formatTime(String time) {
    if (data['runtime']?['type'] == 'H') {
      if (time.contains(":")) return time;
      if (time.length >= 2) return time.padLeft(2, '0') + ":00";
      return time;
    } else {
      if (time.length == 8 && !time.contains('-')) {
        return "${time.substring(0, 4)}/${time.substring(4, 6)}/${time.substring(6, 8)}";
      }
      return time;
    }
  }

  int _timeSort(String a, String b) {
    if (data['runtime']?['type'] == 'H') {
      int ah = int.tryParse(a.split(":")[0]) ?? 0;
      int bh = int.tryParse(b.split(":")[0]) ?? 0;
      int am = a.contains(":") ? int.tryParse(a.split(":")[1]) ?? 0 : 0;
      int bm = b.contains(":") ? int.tryParse(b.split(":")[1]) ?? 0 : 0;
      return ah != bh ? ah.compareTo(bh) : am.compareTo(bm);
    } else {
      DateTime ad, bd;
      try {
        ad = DateTime.parse(a.replaceAll("/", "-").substring(0, 10));
      } catch (_) {
        ad = DateTime(2000);
      }
      try {
        bd = DateTime.parse(b.replaceAll("/", "-").substring(0, 10));
      } catch (_) {
        bd = DateTime(2000);
      }
      return ad.compareTo(bd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final runtime = data['runtime'];
    if (runtime == null) return _buildNoDataCard(context);
    final machines = runtime['runtimeMachine'] as List?;
    if (machines == null || machines.isEmpty) return _buildNoDataCard(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? GlobalColors.labelDark : GlobalColors.labelLight;
    final bgColor = isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;

    final machine = machines[0];
    final runData =
        machine['runtimeMachineData'].firstWhere(
          (d) => d['status'] == 'Run',
          orElse: () => null,
        )?['result'] ??
        [];
    final idleData =
        machine['runtimeMachineData'].firstWhere(
          (d) => d['status'] == 'Idle',
          orElse: () => null,
        )?['result'] ??
        [];

    final allTimes = <String>{};
    for (final r in [...runData, ...idleData]) {
      allTimes.add(r['time'].toString());
    }
    final times = allTimes.toList()..sort(_timeSort);

    Map<String, int> runMap = {};
    Map<String, int> idleMap = {};
    for (final r in runData) {
      runMap[r['time'].toString()] = (r['value'] ?? 0).toInt();
    }
    for (final r in idleData) {
      idleMap[r['time'].toString()] = (r['value'] ?? 0).toInt();
    }

    // Tính max Y cho chart
    int maxSum = 0;
    for (var t in times) {
      maxSum = math.max(maxSum, (runMap[t] ?? 0) + (idleMap[t] ?? 0));
    }
    double barMax;
    if (data['runtime']?['type'] == 'H') {
      barMax = 60;
    } else {
      barMax = 19;
    }

    const barWidth = 26.0;
    const barInGroupSpace = 16.0;
    const groupSpace = 36.0;
    final minChartWidth = 340.0;
    final chartWidth = math.max(
      minChartWidth,
      times.length * (barWidth * 2 + barInGroupSpace + groupSpace) + 10,
    );
    final chartHeight = barMax < 30 ? 120.0 : math.min(barMax * 3.1, 240.0);

    // Tạo nhãn Y
    List<int> yLabels = [];
    int yStep = ((barMax / 5).ceil()).clamp(1, 30);
    for (int v = 0; v <= barMax; v += yStep) {
      yLabels.add(v);
    }
    if (yLabels.last != barMax.toInt()) yLabels.add(barMax.toInt());

    return Card(
      color: bgColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề
            Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 6),
              child: Text(
                "Runtime Analysis - ${machine['machine']}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color:
                      isDark
                          ? GlobalColors.darkPrimaryText
                          : GlobalColors.lightPrimaryText,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trục Y cố định
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: chartHeight + 45,
                      width: 36,
                      child: Stack(
                        children:
                            yLabels.map((v) {
                              final top =
                                  chartHeight - (v / barMax) * chartHeight + 18;
                              return Positioned(
                                top: top,
                                left: 0,
                                right: 0,
                                child: Text(
                                  '$v',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: labelColor.withOpacity(
                                      v == 0 ? 0.5 : 1,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Biểu đồ + số đỏ trên đầu + label X
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: chartWidth,
                      child: Column(
                        children: [
                          // Vùng chart (Stack số trên cột)
                          SizedBox(
                            height: chartHeight + 25,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(times.length, (idx) {
                                final time = times[idx];
                                final run = runMap[time] ?? 0;
                                final idle = idleMap[time] ?? 0;

                                final barHeightRun =
                                    chartHeight * (run / barMax);
                                final barHeightIdle =
                                    chartHeight * (idle / barMax);

                                final maxBar = math.max(
                                  barHeightRun,
                                  barHeightIdle,
                                );

                                return SizedBox(
                                  width:
                                      (barWidth * 2) +
                                      barInGroupSpace +
                                      groupSpace,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: barWidth,
                                              height: barHeightRun,
                                              decoration: BoxDecoration(
                                                color: _runColor,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              alignment: Alignment.topCenter,
                                              child:
                                                  run > 0
                                                      ? Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 3,
                                                            ),
                                                        child: Text(
                                                          '$run',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                            shadows: [
                                                              Shadow(
                                                                blurRadius: 2,
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                      : const SizedBox.shrink(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Bar IDLE
                                      Positioned(
                                        bottom: 0,
                                        left: barWidth + barInGroupSpace,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: barWidth,
                                              height: barHeightIdle,
                                              decoration: BoxDecoration(
                                                color: _idleColor,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              alignment: Alignment.topCenter,
                                              child:
                                                  idle > 0
                                                      ? Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 3,
                                                            ),
                                                        child: Text(
                                                          '$idle',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                            shadows: [
                                                              Shadow(
                                                                blurRadius: 2,
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                      : const SizedBox.shrink(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                          // Trục X: label bên dưới mỗi cặp cột
                          SizedBox(
                            height: 28,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(times.length, (idx) {
                                final time = times[idx];
                                return SizedBox(
                                  width:
                                      (barWidth * 2) +
                                      barInGroupSpace +
                                      groupSpace,
                                  child: Center(
                                    child: Text(
                                      _formatTime(time),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: labelColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
            // Legend cố định (luôn ở giữa card, không bị cuộn)
            Padding(
              padding: const EdgeInsets.only(
                top: 12.0,
                left: 18.0,
                right: 18.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(_runColor),
                  const SizedBox(width: 8),
                  Text(
                    "Run",
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 24),
                  _legendDot(_idleColor),
                  const SizedBox(width: 8),
                  Text(
                    "Idle",
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7.5),
      ),
    );
  }

  Widget _buildNoDataCard(BuildContext context) {
    final labelColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: 230,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: labelColor.withOpacity(0.6),
              ),
              const SizedBox(height: 8),
              Text(
                'No runtime data',
                style: TextStyle(color: labelColor, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
