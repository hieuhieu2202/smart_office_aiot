import '../entities/lcr_entities.dart';
import '../repositories/lcr_repository.dart';

class GetLcrAnalysisData {
  const GetLcrAnalysisData(this._repository);

  final LcrRepository _repository;

  Future<List<LcrRecord>> call(LcrRequest request) {
    return _repository.fetchAnalysisData(request: request);
  }
}
