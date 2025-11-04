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
}

class UphTrackingViewState {
  UphTrackingViewState({
    required this.sections,
    required this.models,
    required this.rows,
  });

  final List<String> sections;
  final List<String> models;
  final List<UphTrackingRowView> rows;

  int get totalWip => rows.fold<int>(0, (sum, row) => sum + row.wip);
  int get totalPass => rows.fold<int>(0, (sum, row) => sum + row.totalPass);
  double get avgProductivity {
    final values = rows.expand((row) => row.productivitySeries).toList();
    if (values.isEmpty) return 0;
    final double total =
        values.fold<double>(0, (sum, value) => sum + (value.isNaN ? 0 : value));
    return total / values.length;
  }

  static UphTrackingViewState fromEntity(UphTrackingEntity entity) {
    final rows = entity.groups
        .map(
          (group) => UphTrackingRowView(
            station: group.groupName,
            wip: group.wip,
            totalPass:
                group.pass.fold<int>(0, (sum, value) => sum + value.round()),
            uph: group.uph,
            passSeries: group.pass,
            productivitySeries: group.pr,
          ),
        )
        .toList();

    return UphTrackingViewState(
      sections: entity.sections,
      models: entity.models,
      rows: rows,
    );
  }
}
