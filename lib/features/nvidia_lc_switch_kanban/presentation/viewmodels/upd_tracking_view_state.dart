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
    required this.models,
    required this.rows,
  });

  final List<String> dates;
  final List<String> models;
  final List<UpdTrackingRowView> rows;

  int get totalWip => rows.fold<int>(0, (sum, row) => sum + row.wip);
  int get totalPass => rows.fold<int>(0, (sum, row) => sum + row.totalPass);
  double get avgProductivity {
    final values = rows.expand((row) => row.productivitySeries).toList();
    if (values.isEmpty) return 0;
    final double total =
        values.fold<double>(0, (sum, value) => sum + (value.isNaN ? 0 : value));
    return values.isEmpty ? 0 : total / values.length;
  }

  static UpdTrackingViewState fromEntity(UpdTrackingEntity entity) {
    final rows = entity.groups
        .map(
          (group) => UpdTrackingRowView(
            station: group.groupName,
            wip: group.wip,
            totalPass:
                group.pass.fold<int>(0, (sum, value) => sum + value.round()),
            upd: group.upd,
            passSeries: group.pass,
            productivitySeries: group.pr,
          ),
        )
        .toList();

    return UpdTrackingViewState(
      dates: entity.dates,
      models: entity.models,
      rows: rows,
    );
  }
}
