import 'package:collection/collection.dart';

import '../../domain/entities/kanban_entities.dart';

class OtViewState {
  OtViewState({
    required this.hours,
    required this.rows,
    required this.modelsText,
  });

  final List<String> hours;
  final List<OtRowView> rows;
  final String modelsText;

  bool get hasData => hours.isNotEmpty && rows.isNotEmpty;

  factory OtViewState.fromResponse({
    required List<String> hours,
    required List<OutputGroupEntity> groups,
    required Map<String, String> modelByStation,
    required List<String> fallbackModels,
  }) {
    final sanitizedHours =
        hours.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final fallback = _buildFallbackModelText(fallbackModels);
    final seenStations = <String>{};

    final rows = <OtRowView>[];
    for (final OutputGroupEntity group in groups) {
      final String station = group.groupName.trim();
      if (station.isEmpty) continue;
      if (!seenStations.add(station)) continue;

      final List<OtCellMetrics> metrics =
          _buildMetrics(sanitizedHours.length, group);
      final String modelText =
          _resolveModel(group, station, modelByStation, fallback);

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

    return OtViewState(
      hours: sanitizedHours,
      rows: rows,
      modelsText: fallback,
    );
  }

  static List<OtCellMetrics> _buildMetrics(
    int hourCount,
    OutputGroupEntity group,
  ) {
    if (hourCount <= 0) return const <OtCellMetrics>[];

    OtCellMetrics buildAt(int index) {
      final double pass =
          index < group.pass.length ? group.pass[index] : 0.0;
      final double yr = index < group.yr.length ? group.yr[index] : 0.0;
      final double rr = index < group.rr.length ? group.rr[index] : 0.0;
      return OtCellMetrics(pass: pass, yr: yr, rr: rr);
    }

    return List<OtCellMetrics>.generate(hourCount, buildAt, growable: false);
  }

  static String _resolveModel(
    OutputGroupEntity group,
    String station,
    Map<String, String> modelByStation,
    String fallback,
  ) {
    final String direct = group.modelName.trim();
    if (direct.isNotEmpty) return direct;

    final String? mapped = modelByStation[station]?.trim();
    if (mapped != null && mapped.isNotEmpty) return mapped;

    return fallback;
  }

  static int _sum(List<double> values) =>
      values.fold<int>(0, (int sum, double value) => sum + value.round());

  static String _buildFallbackModelText(List<String> models) {
    final Iterable<String> compact = models
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toSet()
        .sorted((String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));

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
