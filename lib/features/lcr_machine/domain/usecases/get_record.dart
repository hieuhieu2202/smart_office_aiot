import '../entities/lcr_entities.dart';
import '../repositories/lcr_repository.dart';

class GetLcrRecord {
  const GetLcrRecord(this._repository);

  final LcrRepository _repository;

  Future<LcrRecord?> call(int id) {
    return _repository.fetchRecord(id: id);
  }
}
