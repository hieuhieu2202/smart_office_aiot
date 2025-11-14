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
    return Obx(() {
      controller.highlightedStation.value;
      final StationOverviewDashboardViewState? state = controller.dashboard.value;
      if (state == null || state.stations.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          alignment: Alignment.center,
          child: Text(
            'No station data available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
        );
      }

      final Map<String, Map<String, List<StationSummary>>> grouped = <String, Map<String, List<StationSummary>>>{};
      for (final StationSummary summary in state.stations) {
        final String product = summary.productName.isEmpty ? 'UNKNOWN PRODUCT' : summary.productName;
        grouped.putIfAbsent(product, () => <String, List<StationSummary>>{});
        final Map<String, List<StationSummary>> groups = grouped[product]!;
        groups.putIfAbsent(summary.groupName, () => <StationSummary>[]);
        groups[summary.groupName]!.add(summary);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: grouped.entries.map((MapEntry<String, Map<String, List<StationSummary>>> productEntry) {
          final String product = productEntry.key;
          final Map<String, List<StationSummary>> groups = productEntry.value;
          return _ProductPanel(
            productName: product,
            groups: groups,
            controller: controller,
          );
        }).toList(),
      );
    });
  }
}

class _ProductPanel extends StatelessWidget {
  const _ProductPanel({
    required this.productName,
    required this.groups,
    required this.controller,
  });

  final String productName;
  final Map<String, List<StationSummary>> groups;
  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int totalStations = groups.values.fold<int>(0, (int total, List<StationSummary> list) => total + list.length);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        gradient: LinearGradient(
          colors: <Color>[
            Colors.white.withOpacity(0.07),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF0AA5FF), Color(0xFF176BFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  productName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Text(
                '$totalStations stations',
                style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: groups.entries.map((MapEntry<String, List<StationSummary>> entry) {
              return _GroupRow(
                groupName: entry.key,
                stations: entry.value,
                controller: controller,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.groupName,
    required this.stations,
    required this.controller,
  });

  final String groupName;
  final List<StationSummary> stations;
  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final StationSummary? highlighted = controller.highlightedStation.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            groupName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double maxWidth = constraints.maxWidth;
              final double tileWidth = maxWidth < 680 ? maxWidth : 180;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: stations.map((StationSummary summary) {
                  final bool isSelected = highlighted != null &&
                      highlighted.data.stationName == summary.data.stationName &&
                      highlighted.groupName == summary.groupName;
                  return SizedBox(
                    width: tileWidth < 200 ? tileWidth : 200,
                    child: _StationTile(
                      summary: summary,
                      selected: isSelected,
                      onTap: () => controller.selectStation(summary),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
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
    final ThemeData theme = Theme.of(context);
    final Color statusColor = _statusColor(summary.status);
    final LinearGradient gradient = LinearGradient(
      colors: <Color>[
        statusColor.withOpacity(selected ? 0.95 : 0.85),
        statusColor.withOpacity(selected ? 0.65 : 0.45),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final Color borderColor = selected ? Colors.white : statusColor.withOpacity(0.9);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: gradient,
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    summary.data.stationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _StatusBadge(status: summary.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _MetricText(label: 'Input', value: summary.data.input.toString()),
                _MetricText(label: 'Fail', value: summary.data.failQty.toString()),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _MetricText(
                  label: 'Yield',
                  value: '${(summary.yieldRate * 100).toStringAsFixed(1)}%',
                ),
                _MetricText(
                  label: 'Retest',
                  value: '${(summary.retestRate * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(StationStatus status) {
    switch (status) {
      case StationStatus.error:
        return const Color(0xFFE53935);
      case StationStatus.warning:
        return const Color(0xFFFBC02D);
      case StationStatus.normal:
        return const Color(0xFF43A047);
      case StationStatus.offline:
        return const Color(0xFF546E7A);
    }
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                letterSpacing: 0.9,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final StationStatus status;

  @override
  Widget build(BuildContext context) {
    final String label;
    switch (status) {
      case StationStatus.error:
        label = 'ERROR';
        break;
      case StationStatus.warning:
        label = 'WARN';
        break;
      case StationStatus.normal:
        label = 'PASS';
        break;
      case StationStatus.offline:
        label = 'OFFLINE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withOpacity(0.35),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}
