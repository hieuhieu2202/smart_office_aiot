import '../entities/station_overview_entities.dart';
import '../repositories/station_overview_repository.dart';

class GetStationDetails {
  const GetStationDetails(this._repository);

  final StationOverviewRepository _repository;

  Future<List<StationDetailData>> call(StationOverviewFilter filter) {
    return _repository.getStationDetails(filter);
  }
}
