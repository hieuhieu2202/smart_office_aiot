import '../entities/te_yield_rate.dart';
import '../repositories/te_management_repository.dart';

class GetYieldRateReportUseCase {
  const GetYieldRateReportUseCase(this._repository);

  final TEManagementRepository _repository;

  Future<TEYieldDetailEntity> call({
    required String modelSerial,
    required String range,
    String model = '',
  }) {
    return _repository.fetchYieldRateReport(
      modelSerial: modelSerial,
      range: range,
      model: model,
    );
  }
}
