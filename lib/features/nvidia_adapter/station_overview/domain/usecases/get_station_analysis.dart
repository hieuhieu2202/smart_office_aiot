import '../entities/station_overview_entities.dart';
import '../repositories/station_overview_repository.dart';

class GetStationAnalysis {
  const GetStationAnalysis(this._repository);

  final StationOverviewRepository _repository;

  Future<List<StationAnalysisData>> call(StationOverviewFilter filter) {
    return _repository.getStationAnalysis(filter);
  }
}
