import '../entities/resistor_machine_entities.dart';
import '../repositories/resistor_machine_repository.dart';

class GetResistorMachineStatusData {
  const GetResistorMachineStatusData(this._repository);

  final ResistorMachineRepository _repository;

  Future<List<ResistorMachineStatus>> call(
    ResistorMachineRequest request,
  ) {
    return _repository.getStatusData(request);
  }
}
