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
    final effectiveData = [...data]
      ..sort((a, b) => b.total.compareTo(a.total));
    final topEntries = effectiveData.take(maxItems).toList();

    final maxTotal = topEntries.fold<double>(
      0,
      (previousValue, element) => math.max(previousValue, element.total),
    );
    final barMax = maxTotal == 0 ? 1.0 : maxTotal * 1.1;

    final textColor = theme.brightness == Brightness.dark
        ? const Color(0xFFA0B4C4)
        : const Color(0xFF183B56);

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? _backgroundColor
            : _backgroundColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: barMax,
          barGroups: _buildGroups(topEntries, barMax),
          gridData: const FlGridData(show: false),
          alignment: BarChartAlignment.spaceBetween,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: barMax == 0 ? 1 : barMax / 4,
                getTitlesWidget: (value, meta) {
                  final double rawValue = value;
                  final label = rawValue == 0
                      ? '0'
                      : rawValue >= 1000
                          ? '${(rawValue / 1000).toStringAsFixed(1)}K'
                          : rawValue.toStringAsFixed(0);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ) ??
                          TextStyle(color: textColor, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 80,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= topEntries.length) {
                    return const SizedBox.shrink();
                  }
                  final stat = topEntries[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      stat.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipDecoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              tooltipMargin: 12,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final stat = topEntries[groupIndex];
                return BarTooltipItem(
                  '${stat.name}\n'
                  'PASS: ${stat.pass.toStringAsFixed(0)}\n'
                  'FAIL: ${stat.fail.toStringAsFixed(0)}\n'
                  'TOTAL: ${stat.total.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildGroups(
    List<EmployeeStatistic> entries,
    double maxValue,
  ) {
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final stat = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: stat.total,
            rodStackItems: [
              BarChartRodStackItem(0, stat.fail, _failColor),
              BarChartRodStackItem(stat.fail, stat.total, _passColor),
            ],
            borderRadius: BorderRadius.circular(4),
            width: 24,
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxValue,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ],
      );
    }).toList();
  }
}
