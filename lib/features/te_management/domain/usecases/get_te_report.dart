import '../entities/te_report.dart';
import '../repositories/te_management_repository.dart';

class GetTEReportUseCase {
  GetTEReportUseCase(this.repository);

  final TEManagementRepository repository;

  Future<List<TEReportGroupEntity>> call({
    required String modelSerial,
    required String range,
    String model = '',
  }) {
    return repository.fetchReport(
      modelSerial: modelSerial,
      range: range,
      model: model,
    );
  }
}
