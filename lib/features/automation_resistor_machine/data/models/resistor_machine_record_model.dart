import '../../domain/entities/resistor_machine_entities.dart';

class ResistorMachineRecordModel extends ResistorMachineRecord {
  ResistorMachineRecordModel({
    required super.id,
    required super.workDate,
    required super.workSection,
    required super.classDate,
    required super.className,
    required super.factory,
    required super.machineName,
    required super.serialNumber,
    required super.moNumber,
    required super.modelName,
    required super.groupName,
    required super.goodQty,
    required super.passQty,
    required super.failQty,
    required super.stationSequence,
    required super.inStationTime,
    required super.employeeId,
    required super.cycleTime,
    required super.carrierCode,
    required super.errorCode,
    required super.dataSummary,
    required super.dataDetails,
    required super.packageRevision,
    required super.errorDescription,
  });

  factory ResistorMachineRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return ResistorMachineRecordModel(
      id: (json['id'] ?? json['Id'] ?? 0) as int,
      workDate: (json['workDate'] ?? json['WorkDate'] ?? '') as String,
      workSection: (json['workSection'] ?? json['WorkSection'] ?? 0) as int,
      classDate: (json['classDate'] ?? json['ClassDate'] ?? '') as String,
      className: (json['class'] ?? json['Class'] ?? '') as String,
      factory: (json['factory'] ?? json['Factory'] ?? '') as String,
      machineName:
          (json['machineName'] ?? json['MachineName'] ?? '') as String,
      serialNumber: json['serialNumber'] as String? ?? json['SerialNumber'] as String?,
      moNumber: json['moNumber'] as String? ?? json['MoNumber'] as String?,
      modelName: json['modelName'] as String? ?? json['ModelName'] as String?,
      groupName: json['groupName'] as String? ?? json['GroupName'] as String?,
      goodQty: (json['goodQty'] ?? json['GoodQty'] ?? 0) as int,
      passQty: (json['passQty'] ?? json['PassQty'] ?? 0) as int,
      failQty: (json['failQty'] ?? json['FailQty'] ?? 0) as int,
      stationSequence:
          (json['stationSequence'] ?? json['StationSequence'] ?? 0) as int,
      inStationTime: parseDateTime(
        json['inStationTime'] ?? json['InStationTime'],
      ),
      employeeId: json['employeeId'] as String? ?? json['EmployeeId'] as String?,
      cycleTime: parseDouble(json['cycleTime'] ?? json['CycleTime']),
      carrierCode:
          json['carrierCode'] as String? ?? json['CarrierCode'] as String?,
      errorCode: json['errorCode'] as String? ?? json['ErrorCode'] as String?,
      dataSummary:
          json['dataSummary'] as String? ?? json['DataSummary'] as String?,
      dataDetails:
          json['dataDetails'] as String? ?? json['DataDetails'] as String?,
      packageRevision: json['packageRevision'] as String? ??
          json['PackageRevision'] as String?,
      errorDescription: json['errorDescription'] as String? ??
          json['ErrorDescription'] as String?,
    );
  }
}
