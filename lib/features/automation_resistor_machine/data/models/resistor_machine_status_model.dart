import '../../domain/entities/resistor_machine_entities.dart';

class ResistorMachineStatusModel extends ResistorMachineStatus {
  ResistorMachineStatusModel({
    required super.id,
    required super.serialNumber,
    required super.machineName,
    required super.inStationTime,
    required super.stationSequence,
  });

  factory ResistorMachineStatusModel.fromJson(Map<String, dynamic> json) {
    return ResistorMachineStatusModel(
      id: (json['id'] ?? json['Id'] ?? 0) as int,
      serialNumber: (json['serialNumber'] ?? json['SerialNumber'] ?? '')
          as String,
      machineName:
          (json['machineName'] ?? json['MachineName'] ?? '') as String,
      inStationTime: DateTime.tryParse(
            (json['inStationTime'] ?? json['InStationTime'] ?? '').toString(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      stationSequence:
          (json['stationSequence'] ?? json['StationSequence'] ?? 0) as int,
    );
  }
}
