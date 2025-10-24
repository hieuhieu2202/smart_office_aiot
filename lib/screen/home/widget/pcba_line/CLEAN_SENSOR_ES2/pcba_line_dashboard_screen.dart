import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/responsive_helper.dart';
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

    return Obx(
          () => Scaffold(
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

        // ==============================
        // 🧭 Responsive Body
        // ==============================
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
            : ResponsiveHelper.builder(
          builder: (context, info, isMobile, isTablet, isDesktop) {
            final isWide = isDesktop || isTablet;
            final spacing = 16.0;

            final passChart =
            PcbaPassBarChart3D(controller: controller);
            final failChart =
            PcbaFailBarChart3D(controller: controller);
            final yieldChart =
            PcbaYieldRateLineChart(controller: controller);

            // =======================
            // 🖥️ Desktop / 💻 Tablet
            // =======================
            if (isWide) {
              return SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalHeight = constraints.maxHeight;
                    final spacing = 16.0;
                    final kpiHeight = totalHeight * 0.15;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                        MediaQuery.of(context).size.width * 0.02,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                        children: [
                          // === KPI Header ===
                          SizedBox(
                            height: kpiHeight,
                            child: _buildKpiCard(controller, isDark),
                          ),
                          SizedBox(height: spacing),

                          // === Pass + Fail song song ===
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _buildChartCard(
                                    child: passChart,
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: _buildChartCard(
                                    child: failChart,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: spacing),

                          // === Yield Rate Chart ===
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: _buildChartCard(
                              child: yieldChart,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }

            // =======================
            // 📱 Mobile layout
            // =======================
            return RefreshIndicator(
              onRefresh: () async => controller.refreshAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiCard(controller, isDark),
                    const SizedBox(height: 16),

                    _buildChartCard(
                      isDark: isDark,
                      child: SizedBox(height: 260, child: passChart),
                    ),
                    const SizedBox(height: 16),

                    _buildChartCard(
                      isDark: isDark,
                      child: SizedBox(height: 260, child: failChart),
                    ),
                    const SizedBox(height: 16),

                    _buildChartCard(
                      isDark: isDark,
                      child: SizedBox(height: 260, child: yieldChart),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // 🧮 KPI HEADER CARD (phiên bản có icon + hiệu ứng hover)
  // ============================================================
  Widget _buildKpiCard(PcbaLineDashboardController controller, bool isDark) {
    return Card(
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.blueAccent.withOpacity(.3)
              : Colors.blueAccent.withOpacity(.2),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMiniKpiBox(
              icon: Icons.check_circle_outline,
              title: "Total Pass",
              value: controller.totalPass.value.toString(),
              color: isDark ? Colors.greenAccent : Colors.green,
              isDark: isDark,
            ),
            _buildMiniKpiBox(
              icon: Icons.cancel_outlined,
              title: "Total Fail",
              value: controller.totalFail.value.toString(),
              color: isDark ? Colors.pinkAccent : Colors.purpleAccent,
              isDark: isDark,
            ),
            _buildMiniKpiBox(
              icon: Icons.trending_up,
              title: "Yield Rate",
              value: controller.formattedYieldRate,
              color: isDark ? Colors.lightBlueAccent : Colors.blue,
              isDark: isDark,
            ),
            _buildMiniKpiBox(
              icon: Icons.timer_outlined,
              title: "Avg Cycle",
              value: controller.formattedAvgCycleTime,
              color: isDark ? Colors.cyanAccent : Colors.blueAccent,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🧩 MINI KPI BOX — có hiệu ứng hover/chạm nhẹ
  // ============================================================
  Widget _buildMiniKpiBox({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) {},
        onExit: (_) {},
        child: GestureDetector(
          onTapDown: (_) {},
          onTapUp: (_) {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.blueGrey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              hoverColor: color.withOpacity(0.08),
              splashColor: color.withOpacity(0.12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark
                          ? GlobalColors.secondaryTextDark
                          : GlobalColors.secondaryTextLight,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 📊 Chart Wrapper Card
  // ============================================================
  Widget _buildChartCard({
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? GlobalColors.cardDarkBg
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.blueAccent.withOpacity(0.25)
              : Colors.blueAccent.withOpacity(0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
