import '../repositories/te_management_repository.dart';

class GetModelNamesUseCase {
  GetModelNamesUseCase(this.repository);

  final TEManagementRepository repository;

  Future<List<String>> call({required String modelSerial}) {
    return repository.fetchModelNames(modelSerial: modelSerial);
  }
}
