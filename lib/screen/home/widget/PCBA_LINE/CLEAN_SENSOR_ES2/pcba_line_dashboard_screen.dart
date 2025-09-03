import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/pcba_line_controller.dart';
import 'pcba_pass_bar_chart/pcba_pass_bar_chart.dart';
import 'pcba_fail_bar_chart/pcba_fail_bar_chart.dart';
import 'pcba_yield_line_chart.dart';
import 'pcba_line_filter_panel.dart';

class PcbaLineDashboardScreen extends StatelessWidget {
  const PcbaLineDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PcbaLineDashboardController controller = Get.put(PcbaLineDashboardController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('PCBA Line Clean Sensor Dashboard'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshAll(),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0D1B2A),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value != null) {
          return Center(
            child: Text(
              'Error: ${controller.errorMessage.value}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => controller.refreshAll(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Bộ lọc thời gian ===
                PcbaLineFilterPanel(controller: controller),
                const SizedBox(height: 16),

                // === KPI Header ===
                Card(
                  color: Colors.white12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildKpiBox("Total Pass", controller.totalPass.value.toString(), Colors.green),
                        _buildKpiBox("Total Fail", controller.totalFail.value.toString(), Colors.red),
                        _buildKpiBox("Yield Rate", controller.formattedYieldRate, Colors.amber),
                        _buildKpiBox("Avg Cycle", controller.formattedAvgCycleTime, Colors.blue),
                      ],
                    ),
                  ),
                ),

                // === Pass Chart ===
                PcbaPassBarChart(controller: controller),
                const SizedBox(height: 24),

                // === Fail Chart ===
                PcbaFailBarChart(controller: controller),
                const SizedBox(height: 24),

                // === Yield Line Chart ===
                PcbaYieldRateLineChart(controller: controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKpiBox(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
