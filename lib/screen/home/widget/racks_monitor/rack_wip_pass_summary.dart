import 'package:flutter/material.dart';

import '../../controller/racks_monitor_controller.dart';

class WipPassSummary extends StatelessWidget {
  const WipPassSummary({super.key, required this.controller});
  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data.value;
    final qs = data?.quantitySummary;

    if (qs == null) {
      return const SizedBox.shrink();
    }

    final tiles = [
      _TotalMetric(
        label: 'WIP',
        value: '${qs.wip} PCS',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFF26C6DA),
      ),
      _TotalMetric(
        label: 'TOTAL PASS',
        value: '${qs.totalPass} PCS',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFF20C25D),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Totals',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _TotalTile(metric: tiles[0])),
            const SizedBox(width: 12),
            Expanded(child: _TotalTile(metric: tiles[1])),
          ],
        ),
      ],
    );
  }
}

class _TotalMetric {
  const _TotalMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({required this.metric});

  final _TotalMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: metric.color.withOpacity(isDark ? 0.2 : 0.14),
            ),
            child: Icon(metric.icon, color: metric.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metric.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: metric.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
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
