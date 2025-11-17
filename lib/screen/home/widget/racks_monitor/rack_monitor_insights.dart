import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controller/racks_monitor_controller.dart';
import 'rack_kpi_summary.dart';
import 'rack_list_filter.dart';
import 'rack_panel_card.dart';
import 'rack_pass_by_model_chart.dart';
import 'rack_slot_status_donut.dart';
import 'rack_wip_pass_summary.dart';
import 'rack_yield_rate_gauge.dart';

class RackInsightsColumn extends StatelessWidget {
  const RackInsightsColumn({
    required this.controller,
    required this.totalRacks,
    required this.onlineCount,
    required this.offlineCount,
    required this.activeFilter,
    super.key,
  });

  final GroupMonitorController controller;
  final int totalRacks;
  final int onlineCount;
  final int offlineCount;
  final RackListFilter activeFilter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        const gap = 12.0;
        final availableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
        final allowGrid = availableWidth >= 640;
        final canPairCharts = availableWidth >= 300;
        final double halfWidth =
            (((availableWidth - gap) / 2).clamp(0.0, availableWidth)).toDouble();
        final slotCardWidth =
            (allowGrid || canPairCharts) ? halfWidth : availableWidth;
        final chartContentWidth = math.max(
          0.0,
          slotCardWidth - RackPanelCard.horizontalPadding,
        );
        final slotCounts = controller.slotStatusCount;
        final legendStatuses = const [
          'Testing',
          'Pass',
          'Fail',
          'Waiting',
          'NotUsed',
        ];
        final slotLegendCount = legendStatuses
            .where((key) => (slotCounts[key] ?? 0) > 0)
            .length;
        final hasSlotLegend = slotLegendCount > 0;

        const double donutExtraSpace = 18.0;
        const double gaugeExtraSpace = 18.0;

        final slotChartHeight = chartContentWidth <= 0
            ? 0.0
            : SlotStatusDonut.estimateContentHeight(
                  width: chartContentWidth,
                  theme: theme,
                  includeLegend: hasSlotLegend,
                  includeHeader: true,
                  legendItemCount: slotLegendCount,
                ) +
                donutExtraSpace;
        final gaugeChartHeight = chartContentWidth <= 0
            ? 0.0
            : YieldRateGauge.estimateContentHeight(
                  width: chartContentWidth,
                  theme: theme,
                  includeHeader: true,
                ) +
                gaugeExtraSpace;
        const double chartMinHeight = 196.0;
        final double chartTileHeight = math.max(
          chartMinHeight,
          math.max(slotChartHeight, gaugeChartHeight),
        );

        Widget tile({
          required Widget child,
          int span = 1,
          bool forceHalf = false,
          double? fixedHeight,
        }) {
          final useHalfWidth =
              span < 2 && (allowGrid || (forceHalf && canPairCharts));
          final width = useHalfWidth ? halfWidth : availableWidth;
          final Widget cardChild = fixedHeight != null
              ? SizedBox(height: fixedHeight, child: child)
              : child;
          return SizedBox(
            width: width,
            child: RackPanelCard(
              margin: EdgeInsets.zero,
              child: cardChild,
            ),
          );
        }

        Widget chartTile({
          required Widget child,
          double? fixedHeight,
        }) {
          final useHalfWidth = allowGrid || canPairCharts;
          final width = useHalfWidth ? halfWidth : availableWidth;
          final Widget cardChild = fixedHeight != null
              ? SizedBox(height: fixedHeight, child: child)
              : child;
          return SizedBox(
            width: width,
            child: RackPanelCard(
              margin: EdgeInsets.zero,
              child: cardChild,
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
              alignment: WrapAlignment.center,
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
                chartTile(
                  fixedHeight: chartTileHeight,
                  child: SlotStatusDonut(
                    controller: controller,
                    showHeader: true,
                  ),
                ),
                chartTile(
                  fixedHeight: chartTileHeight,
                  child: YieldRateGauge(
                    controller: controller,
                  ),
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
  final RackListFilter activeFilter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;
        final isDark = theme.brightness == Brightness.dark;
        final onlineRatio = total == 0 ? 0.0 : online / total;

        final highlightOnline = activeFilter != RackListFilter.offline;
        final highlightOffline = activeFilter != RackListFilter.online;

        final double maxCardWidth = constraints.maxWidth > 520
            ? 440
            : constraints.maxWidth;

        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxCardWidth,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF0F2639), Color(0xFF0A1B2A)]
                      : const [Color(0xFFF7FAFF), Color(0xFFE8F1FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.28)
                        : Colors.blueGrey.withOpacity(0.1),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Rack availability',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          total == 0
                              ? 'No racks detected for this filter.'
                              : 'Total racks: $total',
                          style: textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.65),
                          ),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                      const SizedBox(width: 10),
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
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: onlineRatio,
                      backgroundColor:
                          theme.colorScheme.onSurface.withOpacity(
                        isDark ? 0.15 : 0.08,
                      ),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Color(0xFF20C25D)),
                    ),
                  ),
                  const SizedBox(height: 4),
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
            ),
          ),
        );
      },
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

    final foreground = highlight
        ? accent
        : theme.colorScheme.onSurface.withOpacity(0.45);

    final textStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: foreground,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(highlight ? 0.12 : 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(highlight ? 0.35 : 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textStyle),
                const SizedBox(height: 2),
                Text(
                  '$count racks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground.withOpacity(0.8),
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
