import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/station_overview_controller.dart';
import '../viewmodels/station_overview_view_state.dart';
import '../../domain/entities/station_overview_entities.dart';

class StationGroupGrid extends StatelessWidget {
  const StationGroupGrid({super.key, required this.controller});

  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final StationOverviewDashboardViewState? state = controller.dashboard.value;
      if (state == null || state.stations.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No station data available'),
          ),
        );
      }
      final Map<String, Map<String, List<StationSummary>>> grouped = <String, Map<String, List<StationSummary>>>{};
      for (final StationSummary summary in state.stations) {
        final product = summary.productName.isEmpty ? 'UNKNOWN PRODUCT' : summary.productName;
        grouped.putIfAbsent(product, () => <String, List<StationSummary>>{});
        final Map<String, List<StationSummary>> groups = grouped[product]!;
        groups.putIfAbsent(summary.groupName, () => <StationSummary>[]);
        groups[summary.groupName]!.add(summary);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: grouped.entries.map((productEntry) {
          final String product = productEntry.key;
          final Map<String, List<StationSummary>> groups = productEntry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: groups.entries.map((entry) {
                      final String groupName = entry.key;
                      final List<StationSummary> stations = entry.value;
                      return _GroupSection(
                        groupName: groupName,
                        stations: stations,
                        controller: controller,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.groupName,
    required this.stations,
    required this.controller,
  });

  final String groupName;
  final List<StationSummary> stations;
  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final StationSummary? selected = controller.highlightedStation.value;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        title: Text(
          groupName,
          style: theme.textTheme.titleMedium,
        ),
        children: stations
            .map(
              (station) => _StationTile(
                summary: station,
                selected: selected?.data.stationName == station.data.stationName &&
                    selected?.groupName == station.groupName,
                onTap: () => controller.selectStation(station),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StationTile extends StatelessWidget {
  const _StationTile({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final StationSummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color statusColor = _statusColor(summary.status, theme);
    final TextStyle? bodyStyle = theme.textTheme.bodyMedium;
    return Card(
      color: selected ? theme.colorScheme.primary.withOpacity(0.08) : null,
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(
            Icons.memory,
            color: statusColor,
          ),
        ),
        title: Text(
          summary.data.stationName,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: <Widget>[
            Text('Yield ${(summary.yieldRate * 100).toStringAsFixed(1)}%', style: bodyStyle),
            const SizedBox(width: 12),
            Text('Retest ${(summary.retestRate * 100).toStringAsFixed(1)}%', style: bodyStyle),
            const SizedBox(width: 12),
            Text('Fail ${summary.data.failQty}', style: bodyStyle),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: statusColor,
        ),
      ),
    );
  }

  Color _statusColor(StationStatus status, ThemeData theme) {
    switch (status) {
      case StationStatus.error:
        return theme.colorScheme.error;
      case StationStatus.warning:
        return Colors.amber.shade700;
      case StationStatus.normal:
        return Colors.green.shade600;
      case StationStatus.offline:
        return theme.disabledColor;
    }
  }
}
