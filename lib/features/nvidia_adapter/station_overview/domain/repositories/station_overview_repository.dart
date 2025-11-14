import '../entities/station_overview_entities.dart';

abstract class StationOverviewRepository {
  Future<List<StationProduct>> getProducts({required String modelSerial});

  Future<List<StationOverviewData>> getOverview(
    StationOverviewFilter filter,
  );

  Future<List<StationAnalysisData>> getStationAnalysis(
    StationOverviewFilter filter,
  );

  Future<List<StationDetailData>> getStationDetails(
    StationOverviewFilter filter,
  );
}
