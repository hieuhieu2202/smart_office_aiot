import '../../domain/entities/resistor_machine_entities.dart';

class ResistorMachineTestResultModel extends ResistorMachineTestResult {
  ResistorMachineTestResultModel({
    required super.address,
    required super.result,
    required super.imagePath,
    required super.details,
  });

  factory ResistorMachineTestResultModel.fromJson(Map<String, dynamic> json) {
    final details = (json['List_Result'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ResistorMachineResultDetailModel.fromJson)
        .toList();

    return ResistorMachineTestResultModel(
      address: (json['Address'] ?? json['address'] ?? 0) as int,
      result: (json['Result'] ?? json['result'] ?? false) as bool,
      imagePath: (json['ImagePath'] ?? json['imagePath'] ?? '') as String,
      details: details,
    );
  }
}

class ResistorMachineResultDetailModel extends ResistorMachineResultDetail {
  const ResistorMachineResultDetailModel({
    required super.name,
    required super.row,
    required super.column,
    required super.measurementValue,
    required super.lowSampleValue,
    required super.highSampleValue,
    required super.pass,
  });

  factory ResistorMachineResultDetailModel.fromJson(
    Map<String, dynamic> json,
  ) {
    double parseDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return ResistorMachineResultDetailModel(
      name: (json['Name'] ?? json['name'] ?? '') as String,
      row: (json['Row'] ?? json['row'] ?? 0) as int,
      column: (json['Column'] ?? json['column'] ?? 0) as int,
      measurementValue: parseDouble(json['Measurement_Value'] ?? json['measurementValue']),
      lowSampleValue: parseDouble(json['Low_Sample_Value'] ?? json['lowSampleValue']),
      highSampleValue:
          parseDouble(json['High_Sample_Value'] ?? json['highSampleValue']),
      pass: (json['Pass'] ?? json['pass'] ?? false) as bool,
    );
  }
}
