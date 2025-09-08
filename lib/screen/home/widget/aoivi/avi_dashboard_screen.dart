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
  const AOIVIDashboardScreen({super.key, this.defaultGroupName = 'AOI'});

  final String defaultGroupName;

  @override
  State<AOIVIDashboardScreen> createState() => _AOIVIDashboardScreenState();
}

class _AOIVIDashboardScreenState extends State<AOIVIDashboardScreen>
    with TickerProviderStateMixin {
  late AOIVIDashboardController controller;
  bool filterPanelOpen = false;
  late AnimationController _refreshController;
  bool _backPressed = false;
  Timer? _autoTimer;
  final Rxn<DateTime> _lastUpdateTime = Rxn<DateTime>();

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      AOIVIDashboardController(defaultGroupName: widget.defaultGroupName),
      tag: widget.defaultGroupName,
    );
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Lấy dữ liệu ban đầu
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchDataWithUpdateTime();
    });

    // Set timer tự động refresh 30s/lần (load ngầm)
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
    Get.delete<AOIVIDashboardController>(tag: widget.defaultGroupName);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerGradient = LinearGradient(
      colors: isDark
          ? const [Color(0xFF303F9F), Color(0xFF1A237E)]
          : const [Color(0xFF5C6BC0), Color(0xFF64B5F6)],
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
              child: const Icon(
                Icons.filter_list,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          body: Obx(() {
            final data = controller.monitoringData.value ?? {};
            return Column(
              children: [
                // Header AppBar custom gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 44,
                    bottom: 16,
                    left: 24,
                    right: 12,
                  ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: _backPressed ? 0.9 : 1,
                            duration: const Duration(milliseconds: 120),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () {
                                  Navigator.of(context).maybePop();
                                },
                                onTapDown: (_) => setState(() => _backPressed = true),
                                onTapCancel: () => setState(() => _backPressed = false),
                                onTapUp: (_) => setState(() => _backPressed = false),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() => Text(
                                  '${controller.selectedGroup.value} | ${controller.selectedMachine.value} | ${controller.selectedModel.value}',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )),
                                const SizedBox(height: 2),
                                Obx(() => Text(
                                  controller.selectedRangeDateTime.value,
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                )),
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
                              child: const Icon(
                                Icons.refresh,
                                color: Colors.white,
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
                      ),
                      const SizedBox(height: 10),
                      // Dòng cập nhật thời gian mới nhất
                      Obx(() {
                        final time = _lastUpdateTime.value;
                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: time != null ? 1 : 0,
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.white70, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                time != null
                                    ? 'Đã cập nhật lúc ${DateFormat.Hms().format(time)}'
                                    : '',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // Nội dung dashboard
                Expanded(
                  child: Obx(() {
                    final data = controller.monitoringData.value ?? {};
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        PTHDashboardSummary(data: data, controller: controller),
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
              ],
            );
          }),
        ),
        // ===== FILTER PANEL SLIDE IN/OUT =====
        PTHDashboardFilterPanel(
          show: filterPanelOpen,
          onClose: closeFilter,
          onApply: (filters) async {
            await controller.fetchMonitoring(filters: filters, showLoading: true);
            _lastUpdateTime.value = DateTime.now();
            closeFilter();
          },
          controller: controller,
        ),
        // Loading overlay
        Obx(
              () => controller.isLoading.value
              ? Container(
            color: Colors.black.withOpacity(0.3),
                   child: Center(child: EvaScanner(size: 300)) // hoặc 340 tuỳ layout

                // child: const Center(child: CircularProgressIndicator()),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
