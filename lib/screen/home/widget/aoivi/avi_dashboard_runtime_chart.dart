import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../config/global_color.dart';

const _runColor = Color(0xFF4CAF50);
const _idleColor = Color(0xFFF44336);

class PTHDashboardRuntimeChart extends StatelessWidget {
  final Map data;
  final double? height;

  const PTHDashboardRuntimeChart({
    super.key,
    required this.data,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final runtime = data['runtime'];
    final machines = runtime?['runtimeMachine'] as List? ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;

    if (machines.isEmpty) return _buildNoDataCard(context);

    final double? forcedHeight =
        (height != null && height! > 0) ? height : null;
    final double mobileChartHeight = 240;

    return DefaultTabController(
      length: machines.length,
      child: Card(
        color: bgColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _RuntimeCardBody(
            machines: machines,
            runtime: runtime,
            isDark: isDark,
            forcedHeight: forcedHeight,
            mobileChartHeight: mobileChartHeight,
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color) => _runtimeLegendDot(color);

  Widget _buildNoDataCard(BuildContext context) {
    final labelColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final double resolvedHeight =
        (height != null && height! > 0) ? height! : 230;

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: resolvedHeight,
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

class _RuntimeCardBody extends StatelessWidget {
  final List machines;
  final Map runtime;
  final bool isDark;
  final double? forcedHeight;
  final double mobileChartHeight;

  const _RuntimeCardBody({
    required this.machines,
    required this.runtime,
    required this.isDark,
    required this.mobileChartHeight,
    this.forcedHeight,
  });

  @override
  Widget build(BuildContext context) {
    final Widget tabView = TabBarView(
      children: machines.map((machine) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double availableHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : mobileChartHeight;
            return _RuntimeChartForMachine(
              machine: machine,
              runtime: runtime,
              isDark: isDark,
              maxContentHeight: availableHeight,
            );
          },
        );
      }).toList(),
    );

    final children = <Widget>[
      // Tiêu đề & Tab
      Row(
        children: [
          Expanded(
            child: Text(
              "Runtime Analysis",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: isDark
                    ? GlobalColors.darkPrimaryText
                    : GlobalColors.lightPrimaryText,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      TabBar(
        isScrollable: true,
        labelColor: Colors.blue[700],
        unselectedLabelColor: isDark ? Colors.white60 : Colors.grey[600],
        indicator: BoxDecoration(
          color: isDark
              ? Colors.blue.withOpacity(0.17)
              : Colors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        tabs: machines
            .map<Widget>(
              (m) => Tab(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    m['machine'].toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 7),
      if (forcedHeight != null)
        Expanded(child: tabView)
      else
        SizedBox(height: mobileChartHeight, child: tabView),
      Padding(
        padding: const EdgeInsets.only(
          top: 12.0,
          left: 18.0,
          right: 18.0,
          bottom: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _runtimeLegendDot(_runColor),
            const SizedBox(width: 8),
            Text(
              "Run",
              style: TextStyle(
                color: isDark ? GlobalColors.labelDark : GlobalColors.labelLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 24),
            _runtimeLegendDot(_idleColor),
            const SizedBox(width: 8),
            Text(
              "Idle",
              style: TextStyle(
                color: isDark ? GlobalColors.labelDark : GlobalColors.labelLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ];

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: forcedHeight != null ? MainAxisSize.max : MainAxisSize.min,
      children: children,
    );

    if (forcedHeight != null) {
      return SizedBox(height: forcedHeight, child: column);
    }
    return column;
  }
}

Widget _runtimeLegendDot(Color color) {
  return Container(
    width: 15,
    height: 15,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(7.5),
    ),
  );
}

// Widget vẽ runtime cho 1 máy
class _RuntimeChartForMachine extends StatelessWidget {
  final Map machine;
  final Map runtime;
  final bool isDark;
  final double? maxContentHeight;

  const _RuntimeChartForMachine({
    required this.machine,
    required this.runtime,
    required this.isDark,
    this.maxContentHeight,
  });

  String _formatTime(String time) {
    if (runtime['type'] == 'H') {
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
    if (runtime['type'] == 'H') {
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
    final labelColor = isDark ? GlobalColors.labelDark : GlobalColors.labelLight;

    final double? viewportHeight =
        (maxContentHeight != null && maxContentHeight! > 0)
            ? maxContentHeight
            : null;

    final runData = machine['runtimeMachineData'].firstWhere(
          (d) => d['status'] == 'Run',
      orElse: () => null,
    )?['result'] ?? [];
    final idleData = machine['runtimeMachineData'].firstWhere(
          (d) => d['status'] == 'Idle',
      orElse: () => null,
    )?['result'] ?? [];

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
    double barMax = runtime['type'] == 'H' ? 60 : math.max(10, maxSum.toDouble());

    const barWidth = 26.0;
    const barInGroupSpace = 16.0;
    const groupSpace = 36.0;
    final minChartWidth = 340.0;
    final chartWidth = math.max(
      minChartWidth,
      times.length * (barWidth * 2 + barInGroupSpace + groupSpace) + 10,
    );
    double chartHeight =
        barMax < 30 ? 120.0 : math.min(barMax * 3.1, 240.0);

    if (viewportHeight != null && viewportHeight.isFinite) {
      final double maxAllowed = viewportHeight - 96;
      if (maxAllowed > 0) {
        if (maxAllowed < 80) {
          chartHeight =
              chartHeight.clamp(0.0, maxAllowed).toDouble();
          chartHeight = math.max(
            chartHeight,
            math.min(maxAllowed, 60.0),
          );
        } else {
          chartHeight =
              chartHeight.clamp(80.0, maxAllowed).toDouble();
        }
      } else {
        final double safeUpper = math.max(0.0, viewportHeight - 48);
        chartHeight = math.min(chartHeight, safeUpper);
        if (safeUpper > 0) {
          chartHeight = math.max(
            chartHeight,
            math.min(safeUpper, 40.0),
          );
        }
      }
    }

    // Tạo nhãn Y
    List<int> yLabels = [];
    int yStep = ((barMax / 5).ceil()).clamp(1, 30);
    for (int v = 0; v <= barMax; v += yStep) {
      yLabels.add(v);
    }
    if (yLabels.last != barMax.toInt()) yLabels.add(barMax.toInt());

    return Row(
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
                children: yLabels.map((v) {
                  final top = chartHeight - (v / barMax) * chartHeight + 18;
                  return Positioned(
                    top: top,
                    left: 0,
                    right: 0,
                    child: Text(
                      '$v',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: labelColor.withOpacity(v == 0 ? 0.5 : 1),
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
                      mainAxisAlignment:MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(times.length, (idx) {
                        final time = times[idx];
                        final run = runMap[time] ?? 0;
                        final idle = idleMap[time] ?? 0;

                        final barHeightRun = chartHeight * (run / barMax);
                        final barHeightIdle = chartHeight * (idle / barMax);

                        return SizedBox(
                          width: (barWidth * 2) + barInGroupSpace + groupSpace,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Bar Run
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
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      alignment: Alignment.topCenter,
                                      child: run > 0
                                          ? Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 3),
                                        child: Text(
                                          '$run',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 2,
                                                color: Colors.black,
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
                              // Bar Idle
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
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      alignment: Alignment.topCenter,
                                      child: idle > 0
                                          ? Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 3),
                                        child: Text(
                                          '$idle',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 2,
                                                color: Colors.black,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(times.length, (idx) {
                        final time = times[idx];
                        return SizedBox(
                          width:
                          (barWidth * 2) + barInGroupSpace + groupSpace,
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
    );
  }
}
