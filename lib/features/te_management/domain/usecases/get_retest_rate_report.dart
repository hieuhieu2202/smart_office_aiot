import '../entities/te_retest_rate.dart';
import '../repositories/te_management_repository.dart';

class GetRetestRateReportUseCase {
  const GetRetestRateReportUseCase(this._repository);

  final TEManagementRepository _repository;

  Future<TERetestDetailEntity> call({
    required String modelSerial,
    required String range,
    String model = '',
  }) {
    return _repository.fetchRetestRateReport(
      modelSerial: modelSerial,
      range: range,
      model: model,
    );
  }
}
