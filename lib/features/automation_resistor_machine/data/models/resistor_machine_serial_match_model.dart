import '../../domain/entities/resistor_machine_entities.dart';

class ResistorMachineSerialMatchModel extends ResistorMachineSerialMatch {
  ResistorMachineSerialMatchModel({
    required super.id,
    required super.serialNumber,
    required super.sequence,
  });

  factory ResistorMachineSerialMatchModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ResistorMachineSerialMatchModel(
      id: (json['id'] ?? json['Id'] ?? 0) as int,
      serialNumber:
          (json['serialNumber'] ?? json['SerialNumber'] ?? '') as String,
      sequence: (json['sequence'] ?? json['Sequence'] ?? 0) as int,
    );
  }
}
