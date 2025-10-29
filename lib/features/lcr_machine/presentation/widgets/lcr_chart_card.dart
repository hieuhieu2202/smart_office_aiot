import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LcrChartCard extends StatelessWidget {
  const LcrChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height,
  });

  final String title;
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF041C3B).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66031A35),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class EmployeeStatistic {
  const EmployeeStatistic({
    required this.name,
    required this.pass,
    required this.fail,
  });

  factory EmployeeStatistic.fromMap(Map<String, dynamic> map) {
    return EmployeeStatistic(
      name: (map['name'] ?? map['Name'] ?? '').toString(),
      pass: ((map['pass'] ?? map['Pass'] ?? 0) as num).toDouble(),
      fail: ((map['fail'] ?? map['Fail'] ?? 0) as num).toDouble(),
    );
  }

  final String name;
  final double pass;
  final double fail;
  double get total => pass + fail;
}

class EmployeeStatisticsChart extends StatelessWidget {
  const EmployeeStatisticsChart({
    super.key,
    required this.data,
    this.maxItems = 7,
  });

  final List<EmployeeStatistic> data;
  final int maxItems;

  static const _failColor = Color(0xFFFF4B91);
  static const _passColor = Color(0xFF00FFFF);
  static const _backgroundColor = Color(0xFF061B28);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedData = [...data]..sort((a, b) => b.total.compareTo(a.total));
    final topEntries = sortedData.take(maxItems).toList();

    final maxValue = topEntries.fold<double>(
      0,
          (prev, e) => math.max(prev, e.total),
    );

    final textColor = theme.brightness == Brightness.dark
        ? const Color(0xFFA0B4C4)
        : const Color(0xFF183B56);

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxValue * 1.1,
          minY: 0,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 90,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= topEntries.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      topEntries[i].name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: _buildHorizontalBars(topEntries),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(10),
              tooltipMargin: 12,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final stat = topEntries[group.x.toInt()];
                return BarTooltipItem(
                  '${stat.name}\n'
                      'PASS: ${stat.pass.toStringAsFixed(0)}\n'
                      'FAIL: ${stat.fail.toStringAsFixed(0)}\n'
                      'TOTAL: ${stat.total.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  List<BarChartGroupData> _buildHorizontalBars(List<EmployeeStatistic> entries) {
    return entries.asMap().entries.map((entry) {
      final i = entry.key;
      final stat = entry.value;
      return BarChartGroupData(
        x: i,
        groupVertically: false, // <— quan trọng: hiển thị ngang
        barRods: [
          BarChartRodData(
            toY: stat.fail,
            color: _failColor,
            width: 10,
            borderRadius: BorderRadius.circular(2),
          ),
          BarChartRodData(
            toY: stat.pass,
            color: _passColor,
            width: 10,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
        barsSpace: 6,
      );
    }).toList();
  }
}
