import '../entities/resistor_machine_entities.dart';
import '../repositories/resistor_machine_repository.dart';

class GetResistorMachineTestResults {
  const GetResistorMachineTestResults(this._repository);

  final ResistorMachineRepository _repository;

  Future<List<ResistorMachineTestResult>> call(int id) {
    return _repository.getTestResults(id);
  }
}
