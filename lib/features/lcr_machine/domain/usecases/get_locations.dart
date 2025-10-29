import '../entities/lcr_entities.dart';
import '../repositories/lcr_repository.dart';

class GetLcrLocations {
  const GetLcrLocations(this._repository);

  final LcrRepository _repository;

  Future<List<LcrFactory>> call() {
    return _repository.fetchLocations();
  }
}
