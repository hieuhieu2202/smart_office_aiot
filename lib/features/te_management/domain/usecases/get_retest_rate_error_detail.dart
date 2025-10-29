import '../entities/te_report.dart';
import '../repositories/te_management_repository.dart';

class GetRetestRateErrorDetailUseCase {
  GetRetestRateErrorDetailUseCase(this._repository);

  final TEManagementRepository _repository;

  Future<TEErrorDetailEntity?> call({
    required String date,
    required String shift,
    required String model,
    required String group,
  }) {
    return _repository.fetchRetestRateErrorDetail(
      date: date,
      shift: shift,
      model: model,
      group: group,
    );
  }
}
