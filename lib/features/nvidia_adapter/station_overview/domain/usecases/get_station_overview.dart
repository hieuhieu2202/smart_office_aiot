import '../entities/station_overview_entities.dart';
import '../repositories/station_overview_repository.dart';

class GetStationOverview {
  const GetStationOverview(this._repository);

  final StationOverviewRepository _repository;

  Future<List<StationOverviewData>> call(StationOverviewFilter filter) {
    return _repository.getOverview(filter);
  }
}
