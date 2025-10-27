import '../entities/te_report.dart';
import '../repositories/te_management_repository.dart';

class GetErrorDetailUseCase {
  GetErrorDetailUseCase(this.repository);

  final TEManagementRepository repository;

  Future<TEErrorDetailEntity?> call({
    required String range,
    required String model,
    required String group,
  }) {
    return repository.fetchErrorDetail(
      range: range,
      model: model,
      group: group,
    );
  }
}
