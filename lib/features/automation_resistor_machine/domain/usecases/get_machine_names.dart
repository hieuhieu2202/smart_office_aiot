import '../repositories/resistor_machine_repository.dart';

class GetResistorMachineNames {
  const GetResistorMachineNames(this._repository);

  final ResistorMachineRepository _repository;

  Future<List<String>> call() {
    return _repository.getMachineNames();
  }
}
