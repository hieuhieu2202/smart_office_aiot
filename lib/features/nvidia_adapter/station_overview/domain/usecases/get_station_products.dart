import '../entities/station_overview_entities.dart';
import '../repositories/station_overview_repository.dart';

class GetStationProducts {
  const GetStationProducts(this._repository);

  final StationOverviewRepository _repository;

  Future<List<StationProduct>> call(String modelSerial) {
    return _repository.getProducts(modelSerial: modelSerial);
  }
}
