import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/global_color.dart';
import '../../../../widget/animation/loading/eva_scanner.dart';
import '../../controller/avi_dashboard_controller.dart';
import 'avi_dashboard_filter_panel.dart';
import 'avi_dashboard_machine_detail.dart';
import 'avi_dashboard_output_chart.dart';
import 'avi_dashboard_runtime_chart.dart';
import 'avi_dashboard_summary.dart';

class AOIVIDashboardScreen extends StatefulWidget {
  const AOIVIDashboardScreen({super.key});

  @override
  State<AOIVIDashboardScreen> createState() => _AOIVIDashboardScreenState();
}

class _AOIVIDashboardScreenState extends State<AOIVIDashboardScreen>
    with TickerProviderStateMixin {
  late final AOIVIDashboardController controller;
  bool filterPanelOpen = false;
  late AnimationController _refreshController;
  Timer? _autoTimer;
  final Rxn<DateTime> _lastUpdateTime = Rxn<DateTime>();

  @override
  void initState() {
    super.initState();
    controller = Get.put(AOIVIDashboardController());
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchDataWithUpdateTime();
    });

    _autoTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _fetchDataWithUpdateTime(showLoading: false);
    });
  }

  Future<void> _fetchDataWithUpdateTime({bool showLoading = true}) async {
    await controller.fetchMonitoring(showLoading: showLoading);
    _lastUpdateTime.value = DateTime.now();
  }

  void openFilter() => setState(() => filterPanelOpen = true);
  void closeFilter() => setState(() => filterPanelOpen = false);

  @override
  void dispose() {
    _refreshController.dispose();
    _autoTimer?.cancel();
    Get.delete<AOIVIDashboardController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
          appBar: AppBar(
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() => Text(
                      controller.selectedGroup.value,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                const SizedBox(height: 2),
                Obx(() => Text(
                      '${controller.selectedMachine.value} | ${controller.selectedModel.value} | ${controller.selectedRangeDateTime.value}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
              ],
            ),
            actions: [
              IconButton(
                icon: AnimatedBuilder(
                  animation: _refreshController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _refreshController.value * 6.3,
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.refresh,
                    size: 30,
                  ),
                ),
                onPressed: () async {
                  _refreshController.repeat();
                  await _fetchDataWithUpdateTime();
                  _refreshController.stop();
                },
                tooltip: "Làm mới",
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(24),
              child: Obx(() {
                final time = _lastUpdateTime.value;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: time != null ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          time != null
                              ? 'Đã cập nhật lúc ${DateFormat.Hms().format(time)}'
                              : '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          floatingActionButton: AnimatedScale(
            scale: filterPanelOpen ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: FloatingActionButton(
              heroTag: "fabFilter",
              onPressed: openFilter,
              backgroundColor: const Color(0xFF4CAF50),
              child: const Icon(
                Icons.filter_list,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          body: Obx(() {
            final data = controller.monitoringData.value ?? {};
            return ListView(
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
            );
          }),
        ),
        PTHDashboardFilterPanel(
          show: filterPanelOpen,
          onClose: closeFilter,
          onApply: (filters) async {
            await controller.fetchMonitoring(filters: filters, showLoading: true);
            _lastUpdateTime.value = DateTime.now();
            closeFilter();
          },
        ),
        Obx(
          () => controller.isLoading.value
              ? Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(child: EvaScanner(size: 300)),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
