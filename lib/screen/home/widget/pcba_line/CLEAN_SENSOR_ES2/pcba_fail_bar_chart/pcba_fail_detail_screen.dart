import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controller/pcba_line_controller.dart';
import '../pcba_fail_bar_chart/pcba_fail_detail_bar_chart.dart';

class PcbaFailDetailScreen extends StatelessWidget {
  final PcbaLineDashboardController controller;
  final DateTime selectedDate;

  const PcbaFailDetailScreen({
    super.key,
    required this.controller,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final data = controller.machineChartData
        .where((e) => e['Date'] == null)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text('Fail Quantity Detail'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '≫ Fail Quantity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: data.isEmpty
                  ? const Center(
                child: Text('No data', style: TextStyle(color: Colors.white)),
              )
                  : PcbaFailDetailBarChart(machineData: data),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
