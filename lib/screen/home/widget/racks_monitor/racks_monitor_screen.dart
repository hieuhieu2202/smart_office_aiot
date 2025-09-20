import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../service/lc_switch_rack_api.dart' show RackDetail;
import '../../controller/racks_monitor_controller.dart';
import 'rack_filter_sheet.dart';
import 'rack_kpi_summary.dart';
import 'rack_left_panel.dart';
import 'rack_pass_by_model_chart.dart';
import 'rack_slot_status_donut.dart';
import 'rack_status_utils.dart';
import 'rack_wip_pass_summary.dart';
import 'rack_yield_rate_gauge.dart';

class GroupMonitorScreen extends StatelessWidget {
  const GroupMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GroupMonitorController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() {
            final f = controller.selFactory.value;
            final fl = controller.selFloor.value;
            final g = controller.selGroup.value;
            final m = controller.selModel.value;
            final parts = <String>[
              f,
              if (fl != 'ALL') fl,
              if (g != 'ALL') g,
              if (m != 'ALL') m,
            ];
            return Text(parts.isEmpty ? 'Rack Monitor' : parts.join('  ·  '));
          }),
          actions: [
            RackFilterPanel(controller: controller),
            Obx(
              () => IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.isLoading.value ? null : controller.refresh,
                tooltip: 'Refresh',
              ),
            ),
            const SizedBox(width: 6),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(72),
            child: _RackCategoryTabs(),
          ),
        ),
        body: Obx(() {
          final error = controller.error.value;
          if (error != null) {
            return _ErrorState(
              message: error,
              onRetry: controller.refresh,
            );
          }

          if (controller.isLoading.value && controller.data.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = controller.data.value;
          if (data == null) {
            return const Center(child: Text('No data'));
          }

          final split = _RackPartition.from(data.rackDetails);

          return Stack(
            children: [
              TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _RackMonitorTab(
                    controller: controller,
                    racks: split.online,
                    totalRacks: split.total,
                    onlineCount: split.online.length,
                    offlineCount: split.offline.length,
                    highlightOnline: true,
                  ),
                  _RackMonitorTab(
                    controller: controller,
                    racks: split.offline,
                    totalRacks: split.total,
                    onlineCount: split.online.length,
                    offlineCount: split.offline.length,
                    highlightOnline: false,
                  ),
                ],
              ),
              if (controller.isLoading.value && controller.data.value != null)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _RackCategoryTabs extends StatelessWidget {
  const _RackCategoryTabs();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroupMonitorController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: theme.dividerColor.withOpacity(isDark ? 0.25 : 0.6),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F4F8),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Obx(() {
              final racks = controller.data.value?.rackDetails ?? const <RackDetail>[];
              final split = _RackPartition.from(racks);
              return TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                labelColor: isDark ? Colors.white : const Color(0xFF0F2540),
                unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                indicator: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                tabs: [
                  Tab(text: 'Online (${split.online.length})'),
                  Tab(text: 'Offline (${split.offline.length})'),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _RackPartition {
  _RackPartition({
    required this.online,
    required this.offline,
  });

  factory _RackPartition.from(List<RackDetail> racks) {
    final online = <RackDetail>[];
    final offline = <RackDetail>[];
    for (final rack in racks) {
      if (isRackOffline(rack)) {
        offline.add(rack);
      } else {
        online.add(rack);
      }
    }
    return _RackPartition(online: online, offline: offline);
  }

  final List<RackDetail> online;
  final List<RackDetail> offline;

  int get total => online.length + offline.length;
}

class _RackMonitorTab extends StatelessWidget {
  const _RackMonitorTab({
    required this.controller,
    required this.racks,
    required this.totalRacks,
    required this.onlineCount,
    required this.offlineCount,
    required this.highlightOnline,
  });

  final GroupMonitorController controller;
  final List<RackDetail> racks;
  final int totalRacks;
  final int onlineCount;
  final int offlineCount;
  final bool highlightOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final metrics = [
      _PanelCard(child: PassByModelBar(controller: controller)),
      _PanelCard(child: SlotStatusDonut(controller: controller)),
      _PanelCard(child: YieldRateGauge(controller: controller)),
      _PanelCard(child: WipPassSummary(controller: controller)),
    ];

    Widget buildEmptyState() {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RackStatusLegendBar(),
              const SizedBox(height: 16),
              _EmptyRacksMessage(
                highlightOnline: highlightOnline,
                onRefresh: controller.refresh,
              ),
            ],
          ),
        ),
      );
    }

    final header = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: _RackOverviewHeader(
          controller: controller,
          totalRacks: totalRacks,
          onlineCount: onlineCount,
          offlineCount: offlineCount,
          highlightOnline: highlightOnline,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1100;

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    header,
                    if (racks.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: buildEmptyState(),
                      )
                    else
                      RackLeftPanel(racks: racks),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
              SizedBox(
                width: 360,
                child: ColoredBox(
                  color: isDark
                      ? const Color(0xFF061A2F)
                      : const Color(0xFFF5F7FA),
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    children: metrics,
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              header,
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(children: metrics),
                ),
              ),
              if (racks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: buildEmptyState(),
                )
              else
                RackLeftPanel(racks: racks),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }
}

class _RackOverviewHeader extends StatelessWidget {
  const _RackOverviewHeader({
    required this.controller,
    required this.totalRacks,
    required this.onlineCount,
    required this.offlineCount,
    required this.highlightOnline,
  });

  final GroupMonitorController controller;
  final int totalRacks;
  final int onlineCount;
  final int offlineCount;
  final bool highlightOnline;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 720;
        final summaryCard = _PanelCard(
          margin: EdgeInsets.zero,
          child: RackNumbersBox(controller: controller),
        );
        final availabilityCard = _PanelCard(
          margin: EdgeInsets.zero,
          child: _RackPopulationCard(
            total: totalRacks,
            online: onlineCount,
            offline: offlineCount,
            highlightOnline: highlightOnline,
          ),
        );

        if (horizontal) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: summaryCard),
              const SizedBox(width: 12),
              Expanded(child: availabilityCard),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            summaryCard,
            const SizedBox(height: 12),
            availabilityCard,
          ],
        );
      },
    );
  }
}

class _RackPopulationCard extends StatelessWidget {
  const _RackPopulationCard({
    required this.total,
    required this.online,
    required this.offline,
    required this.highlightOnline,
  });

  final int total;
  final int online;
  final int offline;
  final bool highlightOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final onlineRatio = total == 0 ? 0.0 : online / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rack availability',
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          total == 0 ? 'No racks detected for this filter.' : 'Total racks: $total',
          style: textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AvailabilityStat(
                label: 'Online',
                count: online,
                accent: const Color(0xFF20C25D),
                highlight: highlightOnline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AvailabilityStat(
                label: 'Offline',
                count: offline,
                accent: const Color(0xFFE53935),
                highlight: !highlightOnline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: onlineRatio,
            backgroundColor: theme.colorScheme.onSurface.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF20C25D)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          total == 0
              ? 'Adjust the filters to view rack connectivity.'
              : '${(onlineRatio * 100).toStringAsFixed(0)}% of racks are online',
          style: textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _AvailabilityStat extends StatelessWidget {
  const _AvailabilityStat({
    required this.label,
    required this.count,
    required this.accent,
    required this.highlight,
  });

  final String label;
  final int count;
  final Color accent;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bg = highlight ? accent.withOpacity(0.15) : onSurface.withOpacity(0.05);
    final color = highlight ? accent : onSurface.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ? accent.withOpacity(0.4) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRacksMessage extends StatelessWidget {
  const _EmptyRacksMessage({
    required this.highlightOnline,
    required this.onRefresh,
  });

  final bool highlightOnline;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = highlightOnline ? const Color(0xFF20C25D) : const Color(0xFFE53935);
    final title = highlightOnline ? 'No online racks' : 'No offline racks';
    final subtitle = highlightOnline
        ? 'All racks that match your filters are currently offline.'
        : 'Great! Every rack that matches your filters is online right now.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            highlightOnline ? Icons.cloud_off : Icons.cloud_done,
            size: 48,
            color: accent,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unable to load racks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.child,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: child,
    );
  }
}
