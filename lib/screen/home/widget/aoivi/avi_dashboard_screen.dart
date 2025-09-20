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

  Widget _buildToolbarButton(
    BuildContext context, {
    IconData? icon,
    required VoidCallback onTap,
    String? tooltip,
    bool highlight = false,
    Widget? child,
  }) {
    assert(icon != null || child != null, 'Either icon or child must be provided');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    final Color backgroundColor = highlight
        ? accent.withOpacity(isDark ? 0.22 : 0.16)
        : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05));
    final Color borderColor = highlight
        ? accent.withOpacity(isDark ? 0.55 : 0.35)
        : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06));
    final Color iconColor = highlight
        ? accent
        : (isDark ? Colors.white : Colors.black87);

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: child ?? Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  Widget _buildRefreshButton(BuildContext context) {
    return _buildToolbarButton(
      context,
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
        child: Icon(Icons.refresh_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            size: 20),
      ),
    );
  }

  Widget _buildFilterSummaryRow(BuildContext context) {
    return Obx(() {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildFilterSummaryChip(
            context,
            icon: Icons.account_tree_outlined,
            label: 'Group',
            value: controller.selectedGroup.value,
            isDefault: _matchesDefault(
              controller.selectedGroup.value,
              controller.defaultGroup,
            ),
          ),
          _buildFilterSummaryChip(
            context,
            icon: Icons.precision_manufacturing,
            label: 'Machine',
            value: controller.selectedMachine.value,
            isDefault: _matchesDefault(
              controller.selectedMachine.value,
              controller.defaultMachine,
            ),
          ),
          _buildFilterSummaryChip(
            context,
            icon: Icons.view_in_ar,
            label: 'Model',
            value: controller.selectedModel.value,
            isDefault: _matchesDefault(
              controller.selectedModel.value,
              controller.defaultModel,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFilterSummaryChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDefault,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final baseBackground = isDefault
        ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04))
        : accent.withOpacity(isDark ? 0.22 : 0.16);
    final borderColor = isDefault
        ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05))
        : accent.withOpacity(isDark ? 0.55 : 0.32);
    final iconColor = isDefault
        ? theme.colorScheme.onSurface.withOpacity(0.65)
        : accent;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
          color: isDefault ? theme.colorScheme.onSurface : accent,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: isDefault ? theme.colorScheme.onSurface : accent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: baseBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: labelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isNotEmpty ? value : '—',
                    style: valueStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdatedRow(BuildContext context) {
    return Obx(() {
      final time = _lastUpdateTime.value;
      if (time == null) {
        return const SizedBox.shrink();
      }
      final theme = Theme.of(context);
      final mutedColor = theme.colorScheme.onSurface.withOpacity(0.6);
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: 1,
        child: Row(
          children: [
            Icon(Icons.history_toggle_off, color: mutedColor, size: 18),
            const SizedBox(width: 6),
            Text(
              'Đã cập nhật lúc ${DateFormat.Hms().format(time)}',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ) ??
                  TextStyle(
                    color: mutedColor,
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.colorScheme.surface;
    final surfaceTint = theme.colorScheme.surfaceTint;
    final borderColor = theme.colorScheme.onSurface.withOpacity(isDark ? 0.12 : 0.08);
    final headerBackground = Color.alphaBlend(
      surfaceTint.withOpacity(isDark ? 0.12 : 0.05),
      surfaceColor,
    );
    final titleColor = theme.colorScheme.onSurface;
    final subtitleColor = titleColor.withOpacity(0.7);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 16),
      decoration: BoxDecoration(
        color: headerBackground,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(isDark ? 0.35 : 0.12),
            offset: const Offset(0, 8),
            blurRadius: 24,
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
                scale: _backPressed ? 0.94 : 1,
                duration: const Duration(milliseconds: 120),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).maybePop();
                    },
                    onTapDown: (_) => setState(() => _backPressed = true),
                    onTapCancel: () => setState(() => _backPressed = false),
                    onTapUp: (_) => setState(() => _backPressed = false),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: titleColor.withOpacity(isDark ? 0.08 : 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: titleColor,
                        size: 20,
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
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ) ??
                            TextStyle(
                              color: titleColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
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
                          Icon(Icons.calendar_today_rounded,
                              color: subtitleColor, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              controller.selectedRangeDateTime.value,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ) ??
                                  TextStyle(
                                    color: subtitleColor,
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
              const SizedBox(width: 12),
              Obx(
                () => _buildToolbarButton(
                  context,
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
              const SizedBox(width: 8),
              _buildRefreshButton(context),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterSummaryRow(context),
          const SizedBox(height: 12),
          _buildLastUpdatedRow(context),
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

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
          body: Column(
            children: [
              _buildHeader(context),
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
