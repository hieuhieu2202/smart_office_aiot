import '../../domain/entities/resistor_machine_entities.dart';

class ResistorMachineSummaryModel extends ResistorMachineSummary {
  ResistorMachineSummaryModel({
    required super.wip,
    required super.pass,
    required super.fail,
    required super.firstFail,
    required super.retest,
    required super.yieldRate,
    required super.retestRate,
  });

  factory ResistorMachineSummaryModel.fromJson(Map<String, dynamic> json) {
    return ResistorMachineSummaryModel(
      wip: (json['WIP'] ?? 0) as int,
      pass: (json['PASS'] ?? 0) as int,
      fail: (json['FAIL'] ?? 0) as int,
      firstFail: (json['FIRST_FAIL'] ?? 0) as int,
      retest: (json['RETEST'] ?? 0) as int,
      yieldRate: _toDouble(json['YR']),
      retestRate: _toDouble(json['RR']),
    );
  }
}

class ResistorMachineOutputModel extends ResistorMachineOutput {
  ResistorMachineOutputModel({
    required super.section,
    required super.workDate,
    required super.pass,
    required super.fail,
    required super.firstFail,
    required super.retest,
    required super.yieldRate,
    required super.retestRate,
  });

  factory ResistorMachineOutputModel.fromJson(Map<String, dynamic> json) {
    return ResistorMachineOutputModel(
      section: json['SECTION'] as int?,
      workDate: json['WORKDATE'] as String?,
      pass: (json['PASS'] ?? 0) as int,
      fail: (json['FAIL'] ?? 0) as int,
      firstFail: (json['FIRST_FAIL'] ?? 0) as int,
      retest: (json['RETEST'] ?? 0) as int,
      yieldRate: _toDouble(json['YR']),
      retestRate: _toDouble(json['RR']),
    );
  }
}

class ResistorMachineInfoModel extends ResistorMachineInfo {
  ResistorMachineInfoModel({
    required super.name,
    required super.pass,
    required super.fail,
    required super.firstFail,
    required super.retest,
    required super.yieldRate,
    required super.retestRate,
  });

  factory ResistorMachineInfoModel.fromJson(Map<String, dynamic> json) {
    return ResistorMachineInfoModel(
      name: (json['NAME'] ?? '') as String,
      pass: (json['PASS'] ?? 0) as int,
      fail: (json['FAIL'] ?? 0) as int,
      firstFail: (json['FIRST_FAIL'] ?? 0) as int,
      retest: (json['RETEST'] ?? 0) as int,
      yieldRate: _toDouble(json['YR']),
      retestRate: _toDouble(json['RR']),
    );
  }
}

class ResistorMachineTrackingDataModel extends ResistorMachineTrackingData {
  ResistorMachineTrackingDataModel({
    required ResistorMachineSummary summary,
    required List<ResistorMachineOutput> outputs,
    required List<ResistorMachineInfo> machines,
  }) : super(summary: summary, outputs: outputs, machines: machines);

  factory ResistorMachineTrackingDataModel.fromJson(Map<String, dynamic> json) {
    final summaryJson = (json['summary'] ?? json['Summary'] ??
        <String, dynamic>{}) as Map<String, dynamic>;
    final summary = ResistorMachineSummaryModel.fromJson(summaryJson);

    final outputsRaw =
        (json['outputs'] ?? json['Outputs'] ?? const <dynamic>[]) as List<dynamic>;
    final outputsList = outputsRaw
        .whereType<Map<String, dynamic>>()
        .map(ResistorMachineOutputModel.fromJson)
        .toList();

    final machinesRaw =
        (json['machines'] ?? json['Machines'] ?? const <dynamic>[]) as List<dynamic>;
    final machines = machinesRaw
        .whereType<Map<String, dynamic>>()
        .map(ResistorMachineInfoModel.fromJson)
        .toList();

    return ResistorMachineTrackingDataModel(
      summary: summary,
      outputs: outputsList,
      machines: machines,
    );
  }
}

double _toDouble(dynamic value) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}
