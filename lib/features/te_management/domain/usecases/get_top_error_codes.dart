import '../entities/te_top_error.dart';
import '../repositories/te_management_repository.dart';

class GetTopErrorCodesUseCase {
  GetTopErrorCodesUseCase(this._repository);

  final TEManagementRepository _repository;

  Future<List<TETopErrorEntity>> call({
    required String modelSerial,
    required String range,
    String type = 'System',
  }) {
    return _repository.fetchTopErrorCodes(
      modelSerial: modelSerial,
      range: range,
      type: type,
    );
  }
}
