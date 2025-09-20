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

      return LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          const minTileWidth = 120.0;
          const maxTileWidth = 168.0;

          double availableWidth = constraints.maxWidth;
          if (!availableWidth.isFinite) {
            availableWidth =
                metrics.length * maxTileWidth + spacing * (metrics.length - 1);
          }

          final minRequiredWidth =
              metrics.length * minTileWidth + spacing * (metrics.length - 1);

          if (availableWidth < minRequiredWidth) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (int i = 0; i < metrics.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: i == metrics.length - 1 ? 0 : spacing,
                      ),
                      child: SizedBox(
                        width: minTileWidth,
                        child: _SummaryMetricTile(
                          metric: metrics[i],
                          isDark: isDark,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          final tileWidth = ((availableWidth - spacing * (metrics.length - 1)) /
                  metrics.length)
              .clamp(minTileWidth, maxTileWidth);
          final contentWidth =
              tileWidth * metrics.length + spacing * (metrics.length - 1);

          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: contentWidth,
              child: Row(
                children: [
                  for (int i = 0; i < metrics.length; i++) ...[
                    if (i != 0) const SizedBox(width: spacing),
                    SizedBox(
                      width: tileWidth,
                      child: _SummaryMetricTile(
                        metric: metrics[i],
                        isDark: isDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
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
    final captionColor = textColor.withOpacity(isDark ? 0.7 : 0.55);
    final gradient = isDark
        ? [base.withOpacity(0.32), base.withOpacity(0.16)]
        : [base.withOpacity(0.14), Colors.white.withOpacity(0.9)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: base.withOpacity(isDark ? 0.38 : 0.22)),
        boxShadow: [
          BoxShadow(
            color: base.withOpacity(isDark ? 0.22 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(isDark ? 0.25 : 0.18),
                ),
                child: Icon(
                  metric.icon,
                  size: 14,
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
                    letterSpacing: 0.3,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metric.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: captionColor,
            ),
          ),
        ],
      ),
    );
  }
}
