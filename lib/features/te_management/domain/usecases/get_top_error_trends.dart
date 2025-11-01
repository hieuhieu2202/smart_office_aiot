import '../entities/te_top_error.dart';
import '../repositories/te_management_repository.dart';

class GetTopErrorTrendByErrorCodeUseCase {
  GetTopErrorTrendByErrorCodeUseCase(this._repository);

  final TEManagementRepository _repository;

  Future<List<TETopErrorTrendPointEntity>> call({
    required String modelSerial,
    required String range,
    required String errorCode,
    String type = 'System',
  }) {
    return _repository.fetchTopErrorTrendByErrorCode(
      modelSerial: modelSerial,
      range: range,
      errorCode: errorCode,
      type: type,
    );
  }
}

class GetTopErrorTrendByModelStationUseCase {
  GetTopErrorTrendByModelStationUseCase(this._repository);

  final TEManagementRepository _repository;

  Future<List<TETopErrorTrendPointEntity>> call({
    required String range,
    required String errorCode,
    required String model,
    required String station,
  }) {
    return _repository.fetchTopErrorTrendByModelStation(
      range: range,
      errorCode: errorCode,
      model: model,
      station: station,
    );
  }
}
