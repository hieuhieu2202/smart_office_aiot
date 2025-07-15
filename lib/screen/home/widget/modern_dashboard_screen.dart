import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/global_color.dart';
import '../controller/pth_dashboard_controller.dart';
import 'pth_dashboard_filter_panel.dart';
import 'pth_dashboard_machine_detail.dart';
import 'pth_dashboard_output_chart.dart';
import 'pth_dashboard_runtime_chart.dart';
import 'pth_dashboard_summary.dart';

class ModernDashboardScreen extends StatefulWidget {
  const ModernDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen>
    with TickerProviderStateMixin {
  final PTHDashboardController controller = Get.put(PTHDashboardController());
  bool filterOpen = false;
  late AnimationController _refreshController;
  bool _backPressed = false;

  @override
  void initState() {
    super.initState();
    _refreshController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void openFilter() => setState(() => filterOpen = true);
  void closeFilter() => setState(() => filterOpen = false);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
          floatingActionButton: AnimatedScale(
            scale: filterOpen ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: FloatingActionButton(
              heroTag: 'modernFilterFab',
              onPressed: openFilter,
              backgroundColor: const Color(0xFF4CAF50),
              child: const Icon(Icons.filter_list, color: Colors.white),
            ),
          ),
          body: Obx(() {
            final data = controller.monitoringData;
            return Column(
              children: [
                _buildHeader(context),
                if (controller.isLoading.value)
                  const LinearProgressIndicator(minHeight: 3),
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
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        PTHDashboardFilterPanel(
          show: filterOpen,
          onClose: closeFilter,
          onApply: (filters) async {
            await controller.fetchMonitoring(filters: filters);
            closeFilter();
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 44, left: 16, right: 12, bottom: 16),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Obx(() {
        return Row(
          children: [
            AnimatedScale(
              scale: _backPressed ? 0.9 : 1,
              duration: const Duration(milliseconds: 120),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.of(context).maybePop(),
                  onTapDown: (_) => setState(() => _backPressed = true),
                  onTapCancel: () => setState(() => _backPressed = false),
                  onTapUp: (_) => setState(() => _backPressed = false),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.selectedGroup.value} | ${controller.selectedMachine.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.selectedModel.value,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _buildMachineDropdown(),
                  const SizedBox(height: 4),
                  Text(
                    controller.selectedRangeDateTime.value,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                child: const Icon(Icons.refresh, color: Colors.white),
              ),
              onPressed: () async {
                _refreshController.repeat();
                await controller.fetchMonitoring();
                _refreshController.stop();
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMachineDropdown() {
    return Obx(() {
      final machines = controller.machineNames;
      if (machines.isEmpty) return const SizedBox.shrink();
      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedMachine.value,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items:
              machines.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (val) {
            if (val != null) {
              controller.selectedMachine.value = val;
              controller.fetchMonitoring(machineName: val);
            }
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    });
  }
}
