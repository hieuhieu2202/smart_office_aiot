import '../entities/resistor_machine_entities.dart';
import '../repositories/resistor_machine_repository.dart';

class GetResistorMachineRecordById {
  const GetResistorMachineRecordById(this._repository);

  final ResistorMachineRepository _repository;

  Future<ResistorMachineRecord?> call(int id) {
    return _repository.getRecordById(id);
  }
}
