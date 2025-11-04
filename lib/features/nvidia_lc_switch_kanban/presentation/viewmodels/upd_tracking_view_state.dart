import 'package:collection/collection.dart';

import '../../domain/entities/kanban_entities.dart';

class UpdTrackingRowView {
  UpdTrackingRowView({
    required this.station,
    required this.wip,
    required this.totalPass,
    required this.upd,
    required this.passSeries,
    required this.productivitySeries,
  });

  final String station;
  final int wip;
  final int totalPass;
  final double upd;
  final List<double> passSeries;
  final List<double> productivitySeries;
}

class UpdTrackingViewState {
  UpdTrackingViewState({
    required this.dates,
    required this.rows,
    required this.modelsText,
  });

  final List<String> dates;
  final List<UpdTrackingRowView> rows;
  final String modelsText;

  bool get hasData => rows.isNotEmpty && dates.isNotEmpty;

  static UpdTrackingViewState fromEntity(UpdTrackingEntity entity) {
    final dates = entity.dates
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final rows = entity.groups
        .map(
          (group) => UpdTrackingRowView(
            station: group.groupName.trim(),
            wip: group.wip,
            totalPass:
                group.pass.fold<int>(0, (sum, value) => sum + value.round()),
            upd: group.upd,
            passSeries: group.pass,
            productivitySeries: group.pr,
          ),
        )
        .where((row) => row.station.isNotEmpty)
        .toList();

    final modelsText = _buildModelsText(entity.models);

    return UpdTrackingViewState(
      dates: dates,
      rows: rows,
      modelsText: modelsText,
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
}
