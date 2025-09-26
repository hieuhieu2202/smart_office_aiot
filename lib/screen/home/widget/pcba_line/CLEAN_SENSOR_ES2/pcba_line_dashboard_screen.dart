import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/global_color.dart';

import '../../../controller/pcba_line_controller.dart';
import '../../../../../widget/animation/loading/eva_loading_view.dart';
import 'pcba_pass_bar_chart/pcba_pass_bar_chart.dart';
import 'pcba_fail_bar_chart/pcba_fail_bar_chart.dart';
import 'pcba_yield_line_chart.dart';
import 'pcba_line_filter_panel.dart';

class PcbaLineDashboardScreen extends StatelessWidget {
  const PcbaLineDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PcbaLineDashboardController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.updateDefaultDateRange(force: true);
      controller.fetchAll();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() => Scaffold(
      backgroundColor:
      isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
      appBar: AppBar(
        title: const Text('PCBA Line Clean Sensor Dashboard'),
        centerTitle: true,
        backgroundColor:
        isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
        iconTheme: IconThemeData(
          color: isDark
              ? GlobalColors.appBarDarkText
              : GlobalColors.appBarLightText,
        ),
        actions: [
          PcbaLineFilterPanel(controller: controller),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshAll(),
          ),
        ],
      ),
      body: controller.loading.value
          ? const EvaLoadingView(size: 280)
          : controller.errorMessage.value != null
          ? Center(
        child: Text(
          'Error: ${controller.errorMessage.value}',
          style: TextStyle(
            color: isDark ? Colors.redAccent : Colors.red,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: () async => controller.refreshAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === KPI Header ===
              Card(
                color: isDark
                    ? GlobalColors.cardDarkBg
                    : GlobalColors.cardLightBg,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark
                        ? Colors.blueAccent.withOpacity(.4)
                        : Colors.blueAccent.withOpacity(.25),
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                    children: [
                      _buildKpiBox(
                        "Total Pass",
                        controller.totalPass.value.toString(),
                        isDark ? Colors.greenAccent : Colors.green,
                        isDark,
                      ),
                      _buildKpiBox(
                        "Total Fail",
                        controller.totalFail.value.toString(),
                        isDark
                            ? Colors.pinkAccent
                            : Colors.purpleAccent,
                        isDark,
                      ),
                      _buildKpiBox(
                        "Yield Rate",
                        controller.formattedYieldRate,
                        isDark
                            ? GlobalColors.labelDark
                            : GlobalColors.labelLight,
                        isDark,
                      ),
                      _buildKpiBox(
                        "Avg Cycle",
                        controller.formattedAvgCycleTime,
                        isDark
                            ? Colors.lightBlueAccent
                            : Colors.blue,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),

              // === Charts ===
              PcbaPassBarChart(controller: controller),
              const SizedBox(height: 24),
              PcbaFailBarChart(controller: controller),
              const SizedBox(height: 24),
              PcbaYieldRateLineChart(controller: controller),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildKpiBox(
      String title, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark
                ? GlobalColors.secondaryTextDark
                : GlobalColors.secondaryTextLight,
            fontSize: 14,
          ),
        ),
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
