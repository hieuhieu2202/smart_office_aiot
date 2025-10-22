import 'package:collection/collection.dart';

import '../../../../../../service/lc_switch_kanban_api.dart';

class OtViewState {
  OtViewState({
    required this.hours,
    required this.rows,
  });

  final List<String> hours;
  final List<OtRowView> rows;

  bool get hasData => hours.isNotEmpty && rows.isNotEmpty;

  factory OtViewState.fromResponse({
    required List<String> hours,
    required List<KanbanOutputGroup> groups,
    required Map<String, String> modelByStation,
    required List<String> fallbackModels,
  }) {
    final sanitizedHours = hours.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final fallback = _buildFallbackModelText(fallbackModels);
    final seenStations = <String>{};

    final rows = <OtRowView>[];
    for (final group in groups) {
      final station = group.groupName.trim();
      if (station.isEmpty) continue;
      if (!seenStations.add(station)) continue;

      final metrics = _buildMetrics(sanitizedHours.length, group);
      final modelText = _resolveModel(group, station, modelByStation, fallback);

      rows.add(
        OtRowView(
          station: station,
          model: modelText,
          wip: group.wip,
          totalPass: _sum(group.pass),
          totalFail: _sum(group.fail),
          metrics: metrics,
        ),
      );
    }

    return OtViewState(hours: sanitizedHours, rows: rows);
  }

  static List<OtCellMetrics> _buildMetrics(int hourCount, KanbanOutputGroup group) {
    if (hourCount <= 0) return const <OtCellMetrics>[];

    OtCellMetrics buildAt(int index) {
      final pass = index < group.pass.length ? group.pass[index] : 0.0;
      final yr = index < group.yr.length ? group.yr[index] : 0.0;
      final rr = index < group.rr.length ? group.rr[index] : 0.0;
      return OtCellMetrics(pass: pass.toDouble(), yr: yr.toDouble(), rr: rr.toDouble());
    }

    return List<OtCellMetrics>.generate(hourCount, buildAt, growable: false);
  }

  static String _resolveModel(
    KanbanOutputGroup group,
    String station,
    Map<String, String> modelByStation,
    String fallback,
  ) {
    final direct = group.modelName.trim();
    if (direct.isNotEmpty) return direct;

    final mapped = modelByStation[station]?.trim();
    if (mapped != null && mapped.isNotEmpty) return mapped;

    return fallback;
  }

  static int _sum(List<double> values) =>
      values.fold<int>(0, (sum, value) => sum + value.round());

  static String _buildFallbackModelText(List<String> models) {
    final compact = models
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .sorted((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (compact.isEmpty) return '-';
    if (compact.length == 1) return compact.first;
    return compact.join('\n');
  }
}

class OtRowView {
  const OtRowView({
    required this.station,
    required this.model,
    required this.wip,
    required this.totalPass,
    required this.totalFail,
    required this.metrics,
  });

  final String station;
  final String model;
  final int wip;
  final int totalPass;
  final int totalFail;
  final List<OtCellMetrics> metrics;
}

class OtCellMetrics {
  const OtCellMetrics({
    required this.pass,
    required this.yr,
    required this.rr,
  });

  final double pass;
  final double yr;
  final double rr;
}
