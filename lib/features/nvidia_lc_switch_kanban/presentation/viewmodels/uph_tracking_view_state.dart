import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../../domain/entities/kanban_entities.dart';

class UphTrackingRowView {
  UphTrackingRowView({
    required this.station,
    required this.wip,
    required this.totalPass,
    required this.uph,
    required this.passSeries,
    required this.productivitySeries,
  });

  final String station;
  final int wip;
  final int totalPass;
  final double uph;
  final List<double> passSeries;
  final List<double> productivitySeries;

  int get sectionCount => math.min(passSeries.length, productivitySeries.length);
}

class UphTrackingViewState {
  UphTrackingViewState({
    required this.sections,
    required this.rows,
    required this.modelsText,
    required this.lineBalance,
  });

  final List<String> sections;
  final List<UphTrackingRowView> rows;
  final String modelsText;
  final double lineBalance;

  bool get hasData => rows.isNotEmpty && sections.isNotEmpty;

  static UphTrackingViewState fromEntity(UphTrackingEntity entity) {
    final sections = entity.sections
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final rows = entity.groups
        .map(
          (group) => UphTrackingRowView(
            station: group.groupName.trim(),
            wip: group.wip,
            totalPass:
                group.pass.fold<int>(0, (sum, value) => sum + value.round()),
            uph: group.uph,
            passSeries: group.pass,
            productivitySeries: group.pr,
          ),
        )
        .where((row) => row.station.isNotEmpty)
        .toList();

    final modelsText = _buildModelsText(entity.models);
    final lineBalance = _calcLineBalance(rows);

    return UphTrackingViewState(
      sections: sections,
      rows: rows,
      modelsText: modelsText,
      lineBalance: lineBalance,
    );
  }

  static String _buildModelsText(List<String> models) {
    final formatted = models
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .sorted((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (formatted.isEmpty) return '-';
    if (formatted.length == 1) return formatted.first;
    return formatted.join('\n');
  }

  static double _calcLineBalance(List<UphTrackingRowView> rows) {
    if (rows.isEmpty) return 0;
    final passes = rows.map((row) => row.totalPass).toList();
    if (passes.isEmpty) return 0;

    final int maxPass = passes.reduce((a, b) => a > b ? a : b);
    if (maxPass <= 0) return 0;

    final double score = maxPass > 1000 ? (maxPass * 30) / 100 : (maxPass * 20) / 100;
    final List<int> filtered = passes.where((p) => p > score).toList();
    if (filtered.isEmpty) return 0;

    final double total =
        filtered.fold<double>(0, (sum, value) => sum + value.toDouble());
    return ((total / maxPass) * 100) / filtered.length;
  }
}
