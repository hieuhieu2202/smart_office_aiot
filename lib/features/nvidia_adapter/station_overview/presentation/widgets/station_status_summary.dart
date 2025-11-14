import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/station_overview_controller.dart';
import '../viewmodels/station_overview_view_state.dart';

class StationStatusSummary extends StatelessWidget {
  const StationStatusSummary({super.key, required this.controller});

  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final StationOverviewDashboardViewState? state = controller.dashboard.value;
      if (state == null) {
        return const SizedBox.shrink();
      }
      final Map<StationStatus, int> counts = state.statusCounts;
      final List<_StatusInfo> items = <_StatusInfo>[
        _StatusInfo(
          status: StationStatus.error,
          color: theme.colorScheme.error,
          label: 'Error',
        ),
        _StatusInfo(
          status: StationStatus.warning,
          color: Colors.amber.shade600,
          label: 'Warning',
        ),
        _StatusInfo(
          status: StationStatus.normal,
          color: Colors.green.shade600,
          label: 'Normal',
        ),
        _StatusInfo(
          status: StationStatus.offline,
          color: theme.disabledColor,
          label: 'Offline',
        ),
      ];
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 600;
          final children = items
              .map(
                (info) => _StatusCard(
                  info: info,
                  count: counts[info.status] ?? 0,
                  total: state.totalStations,
                  compact: isCompact,
                ),
              )
              .toList();
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: children,
          );
        },
      );
    });
  }
}

class _StatusInfo {
  const _StatusInfo({
    required this.status,
    required this.color,
    required this.label,
  });

  final StationStatus status;
  final Color color;
  final String label;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.info,
    required this.count,
    required this.total,
    required this.compact,
  });

  final _StatusInfo info;
  final int count;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double percentage = total == 0 ? 0 : (count / total) * 100;
    return SizedBox(
      width: compact ? 160 : 200,
      child: Card(
        color: info.color.withOpacity(0.1),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                info.label.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: info.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Text(
                    '$count',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: info.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
