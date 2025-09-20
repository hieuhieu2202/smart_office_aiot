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
    final gradientColors = isDark
        ? const [Color(0xFF10273C), Color(0xFF0B1C2C)]
        : const [Color(0xFFF8FBFF), Color(0xFFE9F1FF)];

    return Obx(() {
      final data = controller.data.value;
      final qs = data?.quantitySummary;

      if (qs == null) {
        return _buildEmpty(theme, gradientColors, isDark);
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

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.35)
                  : Colors.blueGrey.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Wrap(
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
        ),
      );
    });
  }

  Widget _buildEmpty(
    ThemeData theme,
    List<Color> gradientColors,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
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

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: metric.color.withOpacity(isDark ? 0.18 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: metric.color.withOpacity(0.18),
              ),
              child: Icon(metric.icon, color: metric.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
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
                  const SizedBox(height: 2),
                  Text(
                    metric.caption,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
