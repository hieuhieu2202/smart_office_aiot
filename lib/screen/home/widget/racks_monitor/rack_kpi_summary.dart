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
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF20C25D),
        ),
        _SummaryMetric(
          label: 'FAIL',
          value: qs.fail.toString(),
          icon: Icons.cancel_rounded,
          color: const Color(0xFFE53935),
        ),
        _SummaryMetric(
          label: 'YR',
          value: '${qs.yr.toStringAsFixed(2)} %',
          icon: Icons.percent_rounded,
          color: const Color(0xFF1E88E5),
        ),
        _SummaryMetric(
          label: 'FPR',
          value: '${qs.fpr.toStringAsFixed(2)} %',
          icon: Icons.flag_rounded,
          color: const Color(0xFF7E57C2),
        ),
        _SummaryMetric(
          label: 'UT',
          value: '${qs.ut.toStringAsFixed(2)} %',
          icon: Icons.refresh_rounded,
          color: const Color(0xFFFFB300),
        ),
        _SummaryMetric(
          label: 'REPASS',
          value: qs.rePass.toString(),
          icon: Icons.replay_rounded,
          color: const Color(0xFF26C6DA),
        ),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 8.0;
          const minTileWidth = 88.0;
          const maxTileWidth = 128.0;

          double availableWidth = constraints.maxWidth;
          if (!availableWidth.isFinite || availableWidth <= 0) {
            availableWidth =
                metrics.length * maxTileWidth + spacing * (metrics.length - 1);
          }

          if (availableWidth < minTileWidth) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (int i = 0; i < metrics.length; i++) ...[
                    if (i != 0) const SizedBox(width: spacing),
                    SizedBox(
                      width: minTileWidth,
                      child: _SummaryMetricTile(
                        metric: metrics[i],
                        isDark: isDark,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          int columns =
              (availableWidth / (minTileWidth + spacing)).floor();
          if (columns < 1) {
            columns = 1;
          } else if (columns > 3) {
            columns = 3;
          }
          if (columns > metrics.length) {
            columns = metrics.length;
          }
          final tileWidth = ((availableWidth - spacing * (columns - 1)) /
                  columns)
              .clamp(minTileWidth, maxTileWidth);
          final rows = (metrics.length / columns).ceil();

          return Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int row = 0; row < rows; row++) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = row * columns;
                          i < (row + 1) * columns && i < metrics.length;
                          i++) ...[
                        if (i != row * columns) const SizedBox(width: spacing),
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
                  if (row != rows - 1) const SizedBox(height: spacing),
                ],
              ],
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
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
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
    final valueStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: base,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                metric.icon,
                size: 16,
                color: base,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
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
            textAlign: TextAlign.center,
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}
