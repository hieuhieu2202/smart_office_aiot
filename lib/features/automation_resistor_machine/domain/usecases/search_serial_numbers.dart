import '../entities/resistor_machine_entities.dart';
import '../repositories/resistor_machine_repository.dart';

class SearchResistorMachineSerialNumbers {
  const SearchResistorMachineSerialNumbers(this._repository);

  final ResistorMachineRepository _repository;

  Future<List<ResistorMachineSerialMatch>> call(
    String query, {
    int take = 12,
  }) {
    return _repository.searchSerialNumbers(query, take: take);
  }
}
