import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/global_color.dart';
import '../controller/pth_dashboard_controller.dart';
import 'pth_dashboard_filter_panel.dart';
import 'pth_dashboard_summary.dart';
import 'pth_dashboard_runtime_chart.dart';
import 'pth_dashboard_output_chart.dart';
import 'pth_dashboard_machine_detail.dart';

class PTHDashboardScreen extends StatefulWidget {
  const PTHDashboardScreen({super.key});

  @override
  State<PTHDashboardScreen> createState() => _PTHDashboardScreenState();
}

class _PTHDashboardScreenState extends State<PTHDashboardScreen> with TickerProviderStateMixin {
  final PTHDashboardController controller = Get.put(PTHDashboardController());
  bool filterPanelOpen = false;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  void openFilter() => setState(() => filterPanelOpen = true);
  void closeFilter() => setState(() => filterPanelOpen = false);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = controller.monitoringData;

    // Header gradient color
    final headerGradient = const LinearGradient(
      colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
          floatingActionButton: AnimatedScale(
            scale: filterPanelOpen ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: FloatingActionButton(
              heroTag: "fabFilter",
              onPressed: openFilter,
              backgroundColor: const Color(0xFF4CAF50),
              child: const Icon(Icons.filter_list, color: Colors.white, size: 28),
            ),
          ),
          body: Obx(() {
            return Column(
              children: [
                // Header AppBar custom gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 44, bottom: 20, left: 24, right: 12),
                  decoration: BoxDecoration(
                    gradient: headerGradient,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${controller.selectedGroup.value} | ${controller.selectedMachine.value} | ${controller.selectedModel.value}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              controller.selectedRangeDateTime.value,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: AnimatedBuilder(
                          animation: _refreshController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _refreshController.value * 6.3,
                              child: child,
                            );
                          },
                          child: const Icon(Icons.refresh, color: Colors.white, size: 30),
                        ),
                        onPressed: () async {
                          _refreshController.repeat();
                          await controller.fetchMonitoring();
                          _refreshController.stop();
                        },
                        tooltip: "Làm mới",
                      ),
                    ],
                  ),
                ),
                // Loading indicator
                if (controller.isLoading.value)
                  const LinearProgressIndicator(minHeight: 3),
                // Nội dung dashboard
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      PTHDashboardSummary(data: data),
                      const SizedBox(height: 14),
                      PTHDashboardRuntimeChart(data: data),
                      const SizedBox(height: 18),
                      PTHDashboardOutputChart(data: data),
                      const SizedBox(height: 18),
                      PTHDashboardMachineDetail(data: data),
                      const SizedBox(height: 38),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        // ===== FILTER PANEL SLIDE IN/OUT =====
        PTHDashboardFilterPanel(
          show: filterPanelOpen,
          onClose: closeFilter,
          onApply: (filters) async {
            await controller.fetchMonitoring(filters: filters);
            closeFilter();
          },
        ),
      ],
    );
  }
}
