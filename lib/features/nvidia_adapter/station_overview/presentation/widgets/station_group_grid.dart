import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/station_overview_entities.dart';
import '../controllers/station_overview_controller.dart';
import '../viewmodels/station_overview_view_state.dart';
import 'station_analysis_section.dart';
import 'station_detail_section.dart';

class StationGroupGrid extends StatelessWidget {
  const StationGroupGrid({super.key, required this.controller});

  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Ensure the grid reacts to selection and search changes.
      controller.highlightedStation.value;
      controller.stationSearch.value;
      final StationOverviewDashboardViewState? state = controller.dashboard.value;
      if (state == null || state.stations.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 60),
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

      final String query = controller.stationSearch.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: grouped.entries.map((MapEntry<String, Map<String, List<StationSummary>>> productEntry) {
          final String product = productEntry.key;
          final Map<String, List<StationSummary>> groups = productEntry.value;
          return _ProductPanel(
            productName: product,
            groups: groups,
            controller: controller,
            searchQuery: query,
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
    required this.searchQuery,
  });

  final String productName;
  final Map<String, List<StationSummary>> groups;
  final StationOverviewController controller;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int totalStations = groups.values.fold<int>(0, (int total, List<StationSummary> list) => total + list.length);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF081C3C).withOpacity(0.85),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF00E2FF), Color(0xFF0077FF)],
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
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Text(
                '$totalStations STATIONS',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.cyanAccent.withOpacity(0.9),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
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
                searchQuery: searchQuery,
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
    required this.searchQuery,
  });

  final String groupName;
  final List<StationSummary> stations;
  final StationOverviewController controller;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Map<StationStatus, int> counts = <StationStatus, int>{
      StationStatus.normal: 0,
      StationStatus.warning: 0,
      StationStatus.error: 0,
      StationStatus.offline: 0,
    };
    for (final StationSummary summary in stations) {
      counts.update(summary.status, (int value) => value + 1, ifAbsent: () => 1);
    }

    final int total = stations.length;
    final int warning = counts[StationStatus.warning] ?? 0;
    final int error = counts[StationStatus.error] ?? 0;
    final int offline = counts[StationStatus.offline] ?? 0;
    int normal = total - warning - error - offline;
    if (normal < 0) {
      normal = 0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF0E284F).withOpacity(0.85),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stacked = constraints.maxWidth < 900;
          final Widget infoPanel = _GroupInfoPanel(
            productGroup: groupName,
            total: total,
            normal: normal,
            warning: warning,
            error: error,
            offline: offline,
          );
          final Widget stationGrid = _StationGrid(
            controller: controller,
            stations: stations,
            searchQuery: searchQuery,
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _GroupHeader(groupName: groupName, theme: theme),
                const SizedBox(height: 12),
                infoPanel,
                const SizedBox(height: 12),
                stationGrid,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _GroupHeader(groupName: groupName, theme: theme),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 240, child: infoPanel),
                  const SizedBox(width: 16),
                  Expanded(child: stationGrid),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.groupName, required this.theme});

  final String groupName;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      groupName,
      style: theme.textTheme.titleMedium?.copyWith(
        color: Colors.purpleAccent.shade100,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _GroupInfoPanel extends StatelessWidget {
  const _GroupInfoPanel({
    required this.productGroup,
    required this.total,
    required this.normal,
    required this.warning,
    required this.error,
    required this.offline,
  });

  final String productGroup;
  final int total;
  final int normal;
  final int warning;
  final int error;
  final int offline;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.35),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            productGroup,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'TOTAL', value: total, color: Colors.cyanAccent),
          _InfoRow(label: 'NORMAL', value: normal, color: const Color(0xFF00FF99)),
          _InfoRow(label: 'WARNING', value: warning, color: const Color(0xFFFFD54F)),
          _InfoRow(label: 'ERROR', value: error, color: const Color(0xFFFF6E6E)),
          _InfoRow(label: 'OFFLINE', value: offline, color: Colors.blueGrey.shade200),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            '$value',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StationGrid extends StatelessWidget {
  const _StationGrid({
    required this.controller,
    required this.stations,
    required this.searchQuery,
  });

  final StationOverviewController controller;
  final List<StationSummary> stations;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final StationSummary? highlighted = controller.highlightedStation.value;
    final bool hasQuery = searchQuery.isNotEmpty;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double tileWidth = maxWidth < 480
            ? (maxWidth / 6).clamp(64, 90)
            : (maxWidth / 10).clamp(70, 120);
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: stations.map((StationSummary summary) {
            final bool isSelected = highlighted != null &&
                highlighted.data.stationName == summary.data.stationName &&
                highlighted.groupName == summary.groupName;
            final bool matchesQuery = hasQuery &&
                summary.data.stationName.toUpperCase().contains(searchQuery.toUpperCase());
            return SizedBox(
              width: tileWidth,
              child: _StationTile(
                summary: summary,
                selected: isSelected,
                matchesQuery: matchesQuery,
                queryActive: hasQuery,
                onTap: () => _showStationDialog(context, controller, summary),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showStationDialog(
    BuildContext context,
    StationOverviewController controller,
    StationSummary summary,
  ) {
    controller.selectStation(summary);
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF06142E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: _StationInfoContent(summary: summary, controller: controller),
        );
      },
    );
  }
}

class _StationTile extends StatelessWidget {
  const _StationTile({
    required this.summary,
    required this.selected,
    required this.matchesQuery,
    required this.queryActive,
    required this.onTap,
  });

  final StationSummary summary;
  final bool selected;
  final bool matchesQuery;
  final bool queryActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = _statusColor(summary.status);
    final double opacity = !queryActive
        ? 1
        : (matchesQuery || selected ? 1 : 0.25);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? Colors.white : Colors.black.withOpacity(0.3),
                width: selected ? 2 : 1,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _displayName(summary),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(StationStatus status) {
    switch (status) {
      case StationStatus.error:
        return const Color(0xFFB71C1C);
      case StationStatus.warning:
        return const Color(0xFFFBC02D);
      case StationStatus.normal:
        return const Color(0xFF1B5E20);
      case StationStatus.offline:
        return const Color(0xFF37474F);
    }
  }

  String _displayName(StationSummary summary) {
    final RegExp regExp = RegExp(r'\d+');
    final Match? match = regExp.firstMatch(summary.data.stationName);
    if (match == null) {
      return summary.data.stationName;
    }
    final String digits = match.group(0) ?? summary.data.stationName;
    if (summary.groupName.toUpperCase() == 'ICT' && digits.length == 3) {
      return 'TRI$digits';
    }
    return digits;
  }
}

class _StationInfoContent extends StatelessWidget {
  const _StationInfoContent({required this.summary, required this.controller});

  final StationSummary summary;
  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final StationData data = summary.data;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${summary.productName} - ${summary.groupName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          Text(
            summary.data.stationName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'INPUT', value: data.input.toString()),
          _DetailRow(label: 'PASS', value: data.pass.toString()),
          _DetailRow(label: 'FIRST FAIL', value: data.firstFail.toString()),
          _DetailRow(label: 'SECOND FAIL', value: data.secondFail.toString()),
          _DetailRow(label: 'RETEST RATE', value: '${(data.retestRate * 100).toStringAsFixed(2)}%'),
          _DetailRow(label: 'YIELD RATE', value: '${(data.yieldRate * 100).toStringAsFixed(2)}%'),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openAnalysisSheet(context);
                  },
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('VIEW ANALYSIS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyanAccent,
                    side: const BorderSide(color: Colors.cyanAccent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openDetailSheet(context);
                  },
                  icon: const Icon(Icons.table_rows_outlined),
                  label: const Text('TRACKING DATA'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4).withOpacity(0.2),
                    foregroundColor: Colors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAnalysisSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _BottomSheetContainer(
          child: StationAnalysisSection(controller: controller),
        );
      },
    );
  }

  void _openDetailSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _BottomSheetContainer(
          child: StationDetailSection(controller: controller),
        );
      },
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  const _BottomSheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height * 0.75;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF041023),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              letterSpacing: 1.1,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
