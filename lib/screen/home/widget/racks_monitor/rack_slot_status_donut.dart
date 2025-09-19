import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../controller/racks_monitor_controller.dart';

class SlotStatusDonut extends StatelessWidget {
  const SlotStatusDonut({super.key, required this.controller});
  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E2A3A) : Colors.white;

    return Obx(() {
      final data = controller.slotStatusCount;
      final total = data.values.fold<int>(0, (sum, v) => sum + v);

      final List<_Slice> slices = [
        _Slice('Testing', data['Testing'] ?? 0, Colors.blue),
        _Slice('Pass', data['Pass'] ?? 0, Colors.green),
        _Slice('Fail', data['Fail'] ?? 0, Colors.red),
        _Slice('Waiting', data['Waiting'] ?? 0, Colors.orange),
        _Slice('NotUsed', data['NotUsed'] ?? 0, Colors.grey),
      ].where((e) => e.value > 0).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SLOT STATUS', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1.2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                    startDegreeOffset: -90,
                    sections: slices.map((e) {
                      return PieChartSectionData(
                        value: e.value.toDouble(),
                        title: '',
                        color: e.color,
                        radius: 30,
                      );
                    }).toList(),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$total slot',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: slices.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10, height: 10,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(color: e.color, shape: BoxShape.circle),
                  ),
                  Text('${e.label}: ${e.value}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              );
            }).toList(),
          )
        ],
      );
    });
  }
}

class _Slice {
  final String label;
  final int value;
  final Color color;

  _Slice(this.label, this.value, this.color);
}
