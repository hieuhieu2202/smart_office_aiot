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

enum _RackListFilter { all, online, offline }

class GroupMonitorScreen extends StatefulWidget {
  const GroupMonitorScreen({super.key});

  @override
  State<GroupMonitorScreen> createState() => _GroupMonitorScreenState();
}

class _GroupMonitorScreenState extends State<GroupMonitorScreen> {
  late final GroupMonitorController controller;
  final ValueNotifier<_RackListFilter> _filter =
      ValueNotifier<_RackListFilter>(_RackListFilter.all);

  @override
  void initState() {
    super.initState();
    controller = Get.put(GroupMonitorController());
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              onPressed:
                  controller.isLoading.value ? null : controller.refresh,
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 6),
        ],
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

        final partition = _RackPartition.from(data.rackDetails);

        return Stack(
          children: [
            ValueListenableBuilder<_RackListFilter>(
              valueListenable: _filter,
              builder: (context, filter, _) {
                late final List<RackDetail> selectedRacks;
                switch (filter) {
                  case _RackListFilter.all:
                    selectedRacks = [
                      ...partition.online,
                      ...partition.offline,
                    ];
                    break;
                  case _RackListFilter.online:
                    selectedRacks = partition.online;
                    break;
                  case _RackListFilter.offline:
                    selectedRacks = partition.offline;
                    break;
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;
                    final insights = _RackInsightsColumn(
                      controller: controller,
                      totalRacks: partition.total,
                      onlineCount: partition.online.length,
                      offlineCount: partition.offline.length,
                      activeFilter: filter,
                    );

                    final slivers = <Widget>[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: wide
                              ? const EdgeInsets.fromLTRB(12, 16, 12, 8)
                              : const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: _RackFilterRibbon(
                            filter: filter,
                            total: partition.total,
                            online: partition.online.length,
                            offline: partition.offline.length,
                            onChanged: (value) => _filter.value = value,
                          ),
                        ),
                      ),
                      if (selectedRacks.isEmpty) ...[
                        const SliverToBoxAdapter(
                          child: RackStatusLegendBar(),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyRacksMessage(
                            mode: filter,
                            onRefresh: controller.refresh,
                          ),
                        ),
                      ] else ...[
                        RackLeftPanel(racks: selectedRacks),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ];

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: controller.refresh,
                              child: CustomScrollView(
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                slivers: slivers,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 360,
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 16, 12, 24),
                              physics: const BouncingScrollPhysics(),
                              child: insights,
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
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 16, 12, 12),
                              child: insights,
                            ),
                          ),
                          ...slivers,
                        ],
                      ),
                    );
                  },
                );
              },
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
    );
  }
}

class _RackInsightsColumn extends StatelessWidget {
  const _RackInsightsColumn({
    required this.controller,
    required this.totalRacks,
    required this.onlineCount,
    required this.offlineCount,
    required this.activeFilter,
  });

  final GroupMonitorController controller;
  final int totalRacks;
  final int onlineCount;
  final int offlineCount;
  final _RackListFilter activeFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RackNumbersBox(controller: controller),
        const SizedBox(height: 12),
        _PanelCard(
          margin: EdgeInsets.zero,
          child: _RackPopulationCard(
            total: totalRacks,
            online: onlineCount,
            offline: offlineCount,
            activeFilter: activeFilter,
          ),
        ),
        const SizedBox(height: 12),
        _PanelCard(
          margin: EdgeInsets.zero,
          child: PassByModelBar(controller: controller),
        ),
        const SizedBox(height: 12),
        _PanelCard(
          margin: EdgeInsets.zero,
          child: SlotStatusDonut(controller: controller),
        ),
        const SizedBox(height: 12),
        _PanelCard(
          margin: EdgeInsets.zero,
          child: YieldRateGauge(controller: controller),
        ),
        const SizedBox(height: 12),
        _PanelCard(
          margin: EdgeInsets.zero,
          child: WipPassSummary(controller: controller),
        ),
      ],
    );
  }
}

class _RackFilterRibbon extends StatelessWidget {
  const _RackFilterRibbon({
    required this.filter,
    required this.total,
    required this.online,
    required this.offline,
    required this.onChanged,
  });

  final _RackListFilter filter;
  final int total;
  final int online;
  final int offline;
  final ValueChanged<_RackListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      _RibbonItem(
        filter: _RackListFilter.all,
        label: 'All',
        count: total,
        icon: Icons.apps_rounded,
        color: isDark
            ? const Color(0xFF64B5F6)
            : const Color(0xFF1565C0),
      ),
      _RibbonItem(
        filter: _RackListFilter.online,
        label: 'Online',
        count: online,
        icon: Icons.cloud_done_rounded,
        color: const Color(0xFF20C25D),
      ),
      _RibbonItem(
        filter: _RackListFilter.offline,
        label: 'Offline',
        count: offline,
        icon: Icons.cloud_off_rounded,
        color: const Color(0xFFE53935),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D1F33)
            : const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final item in items)
              _RibbonChip(
                key: ValueKey(item.filter),
                item: item,
                selected: item.filter == filter,
                onTap: () => onChanged(item.filter),
              ),
          ],
        ),
      ),
    );
  }
}

class _RibbonItem {
  const _RibbonItem({
    required this.filter,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final _RackListFilter filter;
  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

class _RibbonChip extends StatelessWidget {
  const _RibbonChip({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _RibbonItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = selected
        ? item.color
        : theme.colorScheme.onSurface.withOpacity(0.65);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: selected
                ? item.color.withOpacity(0.18)
                : theme.colorScheme.surface.withOpacity(
                    theme.brightness == Brightness.dark ? 0.3 : 0.9,
                  ),
            border: Border.all(
              color: selected
                  ? item.color.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(
                      theme.brightness == Brightness.dark ? 0.25 : 0.35,
                    ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              _RibbonBadge(color: accent, count: item.count),
            ],
          ),
        ),
      ),
    );
  }
}

class _RibbonBadge extends StatelessWidget {
  const _RibbonBadge({required this.color, required this.count});

  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(isDark ? 0.18 : 0.12),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
      ),
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

class _RackPopulationCard extends StatelessWidget {
  const _RackPopulationCard({
    required this.total,
    required this.online,
    required this.offline,
    required this.activeFilter,
  });

  final int total;
  final int online;
  final int offline;
  final _RackListFilter activeFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final onlineRatio = total == 0 ? 0.0 : online / total;

    final highlightOnline = activeFilter != _RackListFilter.offline;
    final highlightOffline = activeFilter != _RackListFilter.online;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F2639), Color(0xFF0A1B2A)]
              : const [Color(0xFFF7FAFF), Color(0xFFE8F1FF)],
        ),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : Colors.blueGrey.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rack availability',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'No racks detected for this filter.'
                : 'Total racks: $total',
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AvailabilityStat(
                  label: 'Online',
                  count: online,
                  accent: const Color(0xFF20C25D),
                  highlight: highlightOnline,
                  icon: Icons.cloud_done_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AvailabilityStat(
                  label: 'Offline',
                  count: offline,
                  accent: const Color(0xFFE53935),
                  highlight: highlightOffline,
                  icon: Icons.cloud_off_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: onlineRatio,
              backgroundColor:
                  theme.colorScheme.onSurface.withOpacity(
                isDark ? 0.15 : 0.08,
              ),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF20C25D)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'Adjust the filters to view rack connectivity.'
                : '${(onlineRatio * 100).toStringAsFixed(0)}% of racks are online',
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityStat extends StatelessWidget {
  const _AvailabilityStat({
    required this.label,
    required this.count,
    required this.accent,
    required this.highlight,
    required this.icon,
  });

  final String label;
  final int count;
  final Color accent;
  final bool highlight;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight
        ? accent
        : theme.colorScheme.onSurface.withOpacity(0.65);
    final background = highlight
        ? accent.withOpacity(0.18)
        : theme.colorScheme.onSurface.withOpacity(
            theme.brightness == Brightness.dark ? 0.15 : 0.06,
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: background,
        border: Border.all(
          color: highlight ? accent.withOpacity(0.45) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRacksMessage extends StatelessWidget {
  const _EmptyRacksMessage({
    required this.mode,
    required this.onRefresh,
  });

  final _RackListFilter mode;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    late final Color accent;
    late final IconData icon;
    late final String title;
    late final String subtitle;

    switch (mode) {
      case _RackListFilter.all:
        accent = const Color(0xFF1E88E5);
        icon = Icons.storage_rounded;
        title = 'No racks to show';
        subtitle =
            'Try adjusting the filters or refresh to pull the latest rack status.';
        break;
      case _RackListFilter.online:
        accent = const Color(0xFF20C25D);
        icon = Icons.cloud_done_rounded;
        title = 'No online racks';
        subtitle =
            'All racks that match your filters are currently offline.';
        break;
      case _RackListFilter.offline:
        accent = const Color(0xFFE53935);
        icon = Icons.cloud_off_rounded;
        title = 'No offline racks';
        subtitle =
            'Great! Every rack that matches your filters is online right now.';
        break;
    }

    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withOpacity(0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: accent),
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
        ),
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
      margin: margin ?? EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1E30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.blueGrey.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
