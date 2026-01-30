import '../entities/resistor_machine_entities.dart';
import '../repositories/resistor_machine_repository.dart';

class GetResistorMachineTrackingData {
  const GetResistorMachineTrackingData(this._repository);

  final ResistorMachineRepository _repository;

  Future<ResistorMachineTrackingData> call(ResistorMachineRequest request) {
    return _repository.getTrackingData(request);
  }
}
