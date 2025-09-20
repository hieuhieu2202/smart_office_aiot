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
  final AOIVIDashboardController controller = Get.put(AOIVIDashboardController());
  bool filterPanelOpen = false;
  late AnimationController _refreshController;
  bool _backPressed = false;
  Timer? _autoTimer;
  final Rxn<DateTime> _lastUpdateTime = Rxn<DateTime>();

  @override
  void initState() {
    super.initState();
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

  bool _matchesDefault(String value, String defaultValue) {
    return value.trim().toLowerCase() == defaultValue.trim().toLowerCase();
  }

  bool get _hasActiveFilters {
    return !_matchesDefault(controller.selectedGroup.value, controller.defaultGroup) ||
        !_matchesDefault(controller.selectedMachine.value, controller.defaultMachine) ||
        !_matchesDefault(controller.selectedModel.value, controller.defaultModel);
  }

  String _resolvePrimaryTitle() {
    final model = controller.selectedModel.value.trim();
    final machine = controller.selectedMachine.value.trim();
    final group = controller.selectedGroup.value.trim();

    if (model.isNotEmpty && !_matchesDefault(model, controller.defaultModel)) {
      return model;
    }
    if (machine.isNotEmpty && !_matchesDefault(machine, controller.defaultMachine)) {
      return machine;
    }
    if (group.isNotEmpty && !_matchesDefault(group, controller.defaultGroup)) {
      return group;
    }
    return 'AOI Visual Inspection';
  }

  Widget _buildToolbarButton({
    IconData? icon,
    required VoidCallback onTap,
    String? tooltip,
    bool highlight = false,
    Widget? child,
  }) {
    assert(icon != null || child != null, 'Either icon or child must be provided');
    final color = Colors.white.withOpacity(highlight ? 0.22 : 0.12);
    final borderColor = Colors.white.withOpacity(highlight ? 0.45 : 0.18);

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: child ?? Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  Widget _buildRefreshButton() {
    return _buildToolbarButton(
      tooltip: 'Làm mới',
      onTap: () async {
        _refreshController.repeat();
        await _fetchDataWithUpdateTime();
        _refreshController.stop();
      },
      child: AnimatedBuilder(
        animation: _refreshController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _refreshController.value * 6.3,
            child: child,
          );
        },
        child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildFilterSummaryRow(BuildContext context, double maxWidth) {
    return Obx(
          () => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildFilterSummaryPill(
                context,
                icon: Icons.account_tree_outlined,
                label: 'Group',
                value: controller.selectedGroup.value,
                maxWidth: maxWidth,
                isDefault: _matchesDefault(controller.selectedGroup.value, controller.defaultGroup),
              ),
              _buildFilterSummaryPill(
                context,
                icon: Icons.precision_manufacturing,
                label: 'Machine',
                value: controller.selectedMachine.value,
                maxWidth: maxWidth,
                isDefault:
                    _matchesDefault(controller.selectedMachine.value, controller.defaultMachine),
              ),
              _buildFilterSummaryPill(
                context,
                icon: Icons.view_in_ar,
                label: 'Model',
                value: controller.selectedModel.value,
            maxWidth: maxWidth,
            isDefault: _matchesDefault(controller.selectedModel.value, controller.defaultModel),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSummaryPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required double maxWidth,
    required bool isDefault,
  }) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
          color: Colors.white.withOpacity(0.82),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ) ??
        const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          fontSize: 11,
        );

    final valueStyle = theme.textTheme.labelLarge?.copyWith(
          color: isDefault ? Colors.white70 : Colors.white,
          fontWeight: FontWeight.w700,
        ) ??
        TextStyle(
          color: isDefault ? Colors.white70 : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        minWidth: 110,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isDefault ? 0.12 : 0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(isDefault ? 0.22 : 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.85), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '${label.toUpperCase()}: ',
                  style: labelStyle,
                  children: [
                    TextSpan(
                      text: value.isNotEmpty ? value : '—',
                      style: valueStyle,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdatedRow() {
    return Obx(() {
      final time = _lastUpdateTime.value;
      if (time == null) {
        return const SizedBox.shrink();
      }
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: 1,
        child: Row(
          children: [
            const Icon(Icons.history_toggle_off, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(
              'Đã cập nhật lúc ${DateFormat.Hms().format(time)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context, LinearGradient headerGradient) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final availableWidth = mediaQuery.size.width;
    final double maxWidth = availableWidth > 0
        ? (availableWidth - 160).clamp(140.0, availableWidth).toDouble()
        : 140.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 20),
      decoration: BoxDecoration(
        gradient: headerGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        _resolvePrimaryTitle(),
                        style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Obx(
                      () => Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              controller.selectedRangeDateTime.value,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ) ??
                                  const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Obx(
                () => _buildToolbarButton(
                  icon: Icons.filter_list_rounded,
                  tooltip: 'Bộ lọc',
                  highlight: filterPanelOpen || _hasActiveFilters,
                  onTap: () {
                    if (filterPanelOpen) {
                      closeFilter();
                    } else {
                      openFilter();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              _buildRefreshButton(),
            ],
          ),
          const SizedBox(height: 18),
          _buildFilterSummaryRow(context, maxWidth),
          const SizedBox(height: 14),
          _buildLastUpdatedRow(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _autoTimer?.cancel();
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
          body: Column(
            children: [
              _buildHeader(context, headerGradient),
              // Nội dung dashboard
              Expanded(
                child: Obx(() {
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
            ],
          ),
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
        ),
        // Loading overlay
        Obx(
          () => controller.isLoading.value
              ? Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: EvaScanner(size: 300), // hoặc 340 tuỳ layout
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
