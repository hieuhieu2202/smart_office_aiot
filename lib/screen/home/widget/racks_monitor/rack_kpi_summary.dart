import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/racks_monitor_controller.dart';

class RackNumbersBox extends StatelessWidget {
  const RackNumbersBox({super.key, required this.controller});

  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final data = controller.data.value;
      final qs = data?.quantitySummary;

      if (qs == null) {
        return _buildEmpty(theme, isDark);
      }

      final metrics = [
        _SummaryMetric(
          label: 'PASS',
          value: qs.pass.toString(),
          caption: 'PCS',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF20C25D),
        ),
        _SummaryMetric(
          label: 'FAIL',
          value: qs.fail.toString(),
          caption: 'PCS',
          icon: Icons.cancel_rounded,
          color: const Color(0xFFE53935),
        ),
        _SummaryMetric(
          label: 'YR',
          value: '${qs.yr.toStringAsFixed(2)} %',
          caption: 'Yield rate',
          icon: Icons.percent_rounded,
          color: const Color(0xFF1E88E5),
        ),
        _SummaryMetric(
          label: 'FPR',
          value: '${qs.fpr.toStringAsFixed(2)} %',
          caption: 'First pass rate',
          icon: Icons.flag_rounded,
          color: const Color(0xFF7E57C2),
        ),
        _SummaryMetric(
          label: 'UT',
          value: '${qs.ut.toStringAsFixed(2)} %',
          caption: 'Utilization',
          icon: Icons.refresh_rounded,
          color: const Color(0xFFFFB300),
        ),
        _SummaryMetric(
          label: 'WIP',
          value: qs.wip.toString(),
          caption: 'In process',
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF26C6DA),
        ),
      ];

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: metrics
            .map(
              (metric) => _SummaryMetricTile(
                metric: metric,
                isDark: isDark,
              ),
            )
            .toList(),
      );
    });
  }

  Widget _buildEmpty(
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : theme.colorScheme.surfaceVariant.withOpacity(0.8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'No summary available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _SummaryMetric {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
}

class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({
    required this.metric,
    required this.isDark,
  });

  final _SummaryMetric metric;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = metric.color;
    final textColor = isDark ? Colors.white : const Color(0xFF0A1F33);
    final captionColor = textColor.withOpacity(isDark ? 0.7 : 0.6);
    final gradient = isDark
        ? [base.withOpacity(0.42), base.withOpacity(0.24)]
        : [base.withOpacity(0.18), base.withOpacity(0.08)];

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(color: base.withOpacity(isDark ? 0.4 : 0.25)),
          boxShadow: [
            BoxShadow(
              color: base.withOpacity(isDark ? 0.25 : 0.16),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(isDark ? 0.22 : 0.2),
                  ),
                  child: Icon(
                    metric.icon,
                    size: 16,
                    color: isDark ? Colors.white : base,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              metric.value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: captionColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
