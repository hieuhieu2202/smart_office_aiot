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

class _GroupMonitorScreenState extends State<GroupMonitorScreen>
    with SingleTickerProviderStateMixin {
  late final GroupMonitorController controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(GroupMonitorController());
    _tabController = TabController(length: _RackListFilter.values.length, vsync: this)
      ..addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  _RackListFilter get _activeFilter =>
      _RackListFilter.values[_tabController.index];

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

        final filter = _activeFilter;
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

        return Stack(
          children: [
            LayoutBuilder(
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
                  if (!wide)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                        child: insights,
                      ),
                    ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _RackHeaderDelegate(
                      height: 122,
                      child: _RackPinnedHeader(
                        controller: _tabController,
                        total: partition.total,
                        online: partition.online.length,
                        offline: partition.offline.length,
                      ),
                    ),
                  ),
                  if (selectedRacks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyRacksMessage(
                        mode: filter,
                        onRefresh: controller.refresh,
                      ),
                    )
                  else ...[
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
                        width: 320,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
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
                    slivers: slivers,
                  ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final availableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
        final allowGrid = availableWidth >= 640;
        final canPairCharts = availableWidth >= 300;
        final double halfWidth =
            (((availableWidth - gap) / 2).clamp(0.0, availableWidth)).toDouble();

        Widget tile({required Widget child, int span = 1, bool forceHalf = false}) {
          final useHalfWidth =
              span < 2 && (allowGrid || (forceHalf && canPairCharts));
          final width = useHalfWidth ? halfWidth : availableWidth;
          return SizedBox(
            width: width,
            child: _PanelCard(
              margin: EdgeInsets.zero,
              child: child,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RackNumbersBox(controller: controller),
            const SizedBox(height: gap),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              alignment:
                  allowGrid ? WrapAlignment.start : WrapAlignment.center,
              children: [
                tile(
                  span: 2,
                  child: _RackPopulationCard(
                    total: totalRacks,
                    online: onlineCount,
                    offline: offlineCount,
                    activeFilter: activeFilter,
                  ),
                ),
                tile(
                  span: 2,
                  child: PassByModelBar(controller: controller),
                ),
                tile(
                  child: SlotStatusDonut(controller: controller),
                  forceHalf: true,
                ),
                tile(
                  child: YieldRateGauge(controller: controller),
                  forceHalf: true,
                ),
                tile(
                  span: 2,
                  child: WipPassSummary(controller: controller),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _RackHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _RackHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _RackHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _RackPinnedHeader extends StatelessWidget {
  const _RackPinnedHeader({
    required this.controller,
    required this.total,
    required this.online,
    required this.offline,
  });

  final TabController controller;
  final int total;
  final int online;
  final int offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.colorScheme.surface,
      elevation: isDark ? 4 : 2,
      shadowColor: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RackTabSelector(
              controller: controller,
              total: total,
              online: online,
              offline: offline,
            ),
            const SizedBox(height: 10),
            const RackStatusLegendBar(margin: EdgeInsets.zero),
          ],
        ),
      ),
    );
  }
}

class _RackTabSelector extends StatelessWidget {
  const _RackTabSelector({
    required this.controller,
    required this.total,
    required this.online,
    required this.offline,
  });

  final TabController controller;
  final int total;
  final int online;
  final int offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tabs = [
      _RackTabData(
        label: 'All',
        count: total,
        icon: Icons.apps_rounded,
        color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
      ),
      _RackTabData(
        label: 'Online',
        count: online,
        icon: Icons.cloud_done_rounded,
        color: const Color(0xFF20C25D),
      ),
      _RackTabData(
        label: 'Offline',
        count: offline,
        icon: Icons.cloud_off_rounded,
        color: const Color(0xFFE53935),
      ),
    ];

    final activeIndex = controller.index;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2233) : const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              _RackTabChip(
                data: tabs[i],
                selected: activeIndex == i,
                onTap: () => controller.animateTo(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _RackTabData {
  const _RackTabData({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

class _RackTabChip extends StatelessWidget {
  const _RackTabChip({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _RackTabData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = selected
        ? data.color
        : theme.colorScheme.onSurface.withOpacity(0.65);
    final bgColor = selected
        ? data.color.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.16)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? data.color.withOpacity(0.45)
                  : theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                data.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(selected ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${data.count}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: onlineRatio,
              backgroundColor:
                  theme.colorScheme.onSurface.withOpacity(
                isDark ? 0.15 : 0.08,
              ),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF20C25D)),
            ),
          ),
          const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: background,
        border: Border.all(
          color: highlight ? accent.withOpacity(0.45) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: 18),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
