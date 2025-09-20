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
          const spacing = 6.0;
          const minTileWidth = 96.0;
          const maxTileWidth = 132.0;

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
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: base,
    );
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: base,
    );
    final captionStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: base.withOpacity(0.85),
    );

    final backgroundColor = isDark
        ? const Color(0xFF0F172A)
        : theme.colorScheme.surfaceVariant.withOpacity(0.65);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.04)
        : theme.colorScheme.outline.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                metric.icon,
                size: 18,
                color: base,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
          const SizedBox(height: 2),
          Text(
            metric.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: captionStyle,
          ),
        ],
      ),
    );
  }
}
