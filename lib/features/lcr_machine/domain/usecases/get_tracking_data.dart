import '../entities/lcr_entities.dart';
import '../repositories/lcr_repository.dart';

class GetLcrTrackingData {
  const GetLcrTrackingData(this._repository);

  final LcrRepository _repository;

  Future<List<LcrRecord>> call(LcrRequest request) {
    return _repository.fetchTrackingData(request: request);
  }
}
