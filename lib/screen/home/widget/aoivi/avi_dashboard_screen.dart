import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';
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

    final baseOverlay = theme.colorScheme.onSurface.withOpacity(isDark ? 0.08 : 0.06);
    final Color backgroundColor = highlight
        ? accent.withOpacity(isDark ? 0.2 : 0.14)
        : baseOverlay;
    final Color borderColor = highlight
        ? accent.withOpacity(isDark ? 0.45 : 0.28)
        : theme.dividerColor.withOpacity(isDark ? 0.4 : 0.6);
    final Color iconColor = highlight
        ? accent
        : theme.colorScheme.onSurface.withOpacity(isDark ? 0.9 : 0.8);

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: child ?? Icon(icon, color: iconColor, size: 18),
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
        child: Icon(
          Icons.refresh_rounded,
          color: Theme.of(context).colorScheme.onSurface,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildFilterSummaryRow(BuildContext context) {
    return Obx(() {
      return Align(
        alignment: Alignment.center,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: [
            _buildFilterSummaryChip(
              context,
              label: 'Group',
              value: controller.selectedGroup.value,
              isDefault: _matchesDefault(
                controller.selectedGroup.value,
                controller.defaultGroup,
              ),
            ),
            _buildFilterSummaryChip(
              context,
              label: 'Machine',
              value: controller.selectedMachine.value,
              isDefault: _matchesDefault(
                controller.selectedMachine.value,
                controller.defaultMachine,
              ),
            ),
            _buildFilterSummaryChip(
              context,
              label: 'Model',
              value: controller.selectedModel.value,
              isDefault: _matchesDefault(
                controller.selectedModel.value,
                controller.defaultModel,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterSummaryChip(
    BuildContext context, {
    required String label,
    required String value,
    required bool isDefault,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final baseBackground = isDefault
        ? theme.colorScheme.onSurface.withOpacity(isDark ? 0.04 : 0.05)
        : accent.withOpacity(isDark ? 0.2 : 0.14);
    final borderColor = isDefault
        ? theme.colorScheme.onSurface.withOpacity(isDark ? 0.06 : 0.07)
        : accent.withOpacity(isDark ? 0.45 : 0.28);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.55),
          letterSpacing: 0.4,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.55),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
          color: isDefault
              ? theme.colorScheme.onSurface.withOpacity(0.85)
              : accent,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: isDefault
              ? theme.colorScheme.onSurface.withOpacity(0.85)
              : accent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: baseBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
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
    );
  }

  Widget _buildLastUpdatedRow(BuildContext context) {
    return Obx(() {
      final time = _lastUpdateTime.value;
      if (time == null) {
        return const SizedBox.shrink();
      }
      final theme = Theme.of(context);
      final mutedColor = theme.colorScheme.onSurface.withOpacity(0.55);
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: 1,
        child: Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, color: mutedColor, size: 16),
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
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.4 : 0.7);
    final headerBackground = theme.colorScheme.surface;
    final titleColor = theme.colorScheme.onSurface;
    final subtitleColor = titleColor.withOpacity(0.7);

    final headerContent = Column(
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: titleColor.withOpacity(isDark ? 0.08 : 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: titleColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Text(
                      _resolvePrimaryTitle(),
                      style: theme.textTheme.titleMedium?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ) ??
                          TextStyle(
                            color: titleColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: subtitleColor, size: 14),
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
            const SizedBox(width: 10),
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
            const SizedBox(width: 6),
            _buildRefreshButton(context),
          ],
        ),
        const SizedBox(height: 12),
        _buildFilterSummaryRow(context),
        const SizedBox(height: 10),
        _buildLastUpdatedRow(context),
      ],
    );

    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        final bool isMobile =
            sizingInfo.deviceScreenType == DeviceScreenType.mobile;
        final bool isDesktop =
            sizingInfo.deviceScreenType == DeviceScreenType.desktop;
        final double horizontalPadding = isMobile ? 16 : (isDesktop ? 32 : 24);
        final double maxWidth = isDesktop ? 1320 : 1040;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding + 10,
            horizontalPadding,
            12,
          ),
          decoration: BoxDecoration(
            color: headerBackground,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: borderColor)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(isDark ? 0.25 : 0.08),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: isMobile
              ? headerContent
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: headerContent,
                  ),
                ),
        );
      },
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
    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        if (sizingInfo.deviceScreenType == DeviceScreenType.mobile) {
          return _buildMobileLayout(context);
        }
        return _buildLargeLayout(context, sizingInfo);
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
          body: Column(
            children: [
              _buildHeader(context),
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
        _buildFilterPanel(),
        _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLargeLayout(
      BuildContext context, SizingInformation sizingInfo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = sizingInfo.deviceScreenType;
    final bool isDesktop = deviceType == DeviceScreenType.desktop;

    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Obx(() {
                  final data = controller.monitoringData.value ?? {};
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final double viewportHeight =
                          constraints.hasBoundedHeight ? constraints.maxHeight : 0;
                      final bool expandToViewport = viewportHeight >= 680;
                      final double maxContentWidth = isDesktop ? 1520 : 1280;
                      final EdgeInsets padding = EdgeInsets.fromLTRB(
                        isDesktop ? 26 : 20,
                        isDesktop ? 26 : 22,
                        isDesktop ? 26 : 20,
                        isDesktop ? 30 : 24,
                      );

                      Widget panel = Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxContentWidth),
                          child: Padding(
                            padding: padding,
                            child: _LargeDashboardContent(
                              data: data,
                              isDesktop: isDesktop,
                              expandToViewport: expandToViewport,
                              viewportHeight: viewportHeight,
                            ),
                          ),
                        ),
                      );

                      if (!expandToViewport) {
                        panel = SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            vertical: isDesktop ? 24 : 18,
                          ),
                          child: panel,
                        );
                      }

                      return panel;
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        _buildFilterPanel(),
        _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildFilterPanel() {
    return PTHDashboardFilterPanel(
      show: filterPanelOpen,
      onClose: closeFilter,
      onApply: (filters) async {
        await controller.fetchMonitoring(filters: filters, showLoading: true);
        _lastUpdateTime.value = DateTime.now();
        closeFilter();
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Obx(
      () => controller.isLoading.value
          ? Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: EvaScanner(size: 300),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _LargeDashboardContent extends StatelessWidget {
  final Map data;
  final bool isDesktop;
  final bool expandToViewport;
  final double? viewportHeight;

  const _LargeDashboardContent({
    required this.data,
    required this.isDesktop,
    this.expandToViewport = true,
    this.viewportHeight,
  });

  @override
  Widget build(BuildContext context) {
    final double spacing = isDesktop ? 24.0 : 20.0;
    final double verticalSpacing = isDesktop ? 24.0 : 20.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool sideBySide = width >= (isDesktop ? 1180 : 1040);
        final bool ultraWide = width >= (isDesktop ? 1440 : 1300);
        final int leftFlex = ultraWide ? 13 : 11;
        final int rightFlex = ultraWide ? 4 : 5;
        final int runtimeFlex = ultraWide ? 8 : 7;
        final int outputFlex = ultraWide ? 4 : 3;

        final double effectiveViewportHeight = viewportHeight ??
            (constraints.hasBoundedHeight ? constraints.maxHeight : 0);
        final bool tallEnough = expandToViewport &&
            constraints.hasBoundedHeight &&
            effectiveViewportHeight >= 640;

        if (tallEnough && sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PTHDashboardSummary(data: data),
              SizedBox(height: verticalSpacing),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: leftFlex,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: runtimeFlex,
                            child: _ResponsiveSection(
                              builder: (height) => PTHDashboardRuntimeChart(
                                data: data,
                                height: height,
                              ),
                            ),
                          ),
                          SizedBox(height: verticalSpacing),
                          Expanded(
                            flex: outputFlex,
                            child: _ResponsiveSection(
                              builder: (height) => PTHDashboardOutputChart(
                                data: data,
                                height: height,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      flex: rightFlex,
                      child: _ResponsiveSection(
                        builder: (height) => PTHDashboardMachineDetail(
                          data: data,
                          height: height,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PTHDashboardSummary(data: data),
            SizedBox(height: verticalSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResponsiveSection(
                  builder: (height) => PTHDashboardRuntimeChart(
                    data: data,
                    height: height,
                  ),
                ),
                SizedBox(height: verticalSpacing),
                _ResponsiveSection(
                  builder: (height) => PTHDashboardOutputChart(
                    data: data,
                    height: height,
                  ),
                ),
                SizedBox(height: verticalSpacing),
                _ResponsiveSection(
                  builder: (height) => PTHDashboardMachineDetail(
                    data: data,
                    height: height,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ResponsiveSection extends StatelessWidget {
  final Widget Function(double height) builder;

  const _ResponsiveSection({required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : (constraints.biggest.height.isFinite
                ? constraints.biggest.height
                : 0);
        return builder(availableHeight);
      },
    );
  }
}
