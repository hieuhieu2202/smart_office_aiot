import '../entities/resistor_machine_entities.dart';
import '../repositories/resistor_machine_repository.dart';

class GetResistorMachineRecordBySerial {
  const GetResistorMachineRecordBySerial(this._repository);

  final ResistorMachineRepository _repository;

  Future<ResistorMachineRecord?> call(String serialNumber) {
    return _repository.getRecordBySerial(serialNumber);
  }
}
