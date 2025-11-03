import 'package:equatable/equatable.dart';

class ResistorMachineRequest extends Equatable {
  const ResistorMachineRequest({
    required this.dateRange,
    required this.shift,
    required this.machineName,
    required this.status,
  });

  final String dateRange;
  final String shift;
  final String machineName;
  final String status;

  ResistorMachineRequest copyWith({
    String? dateRange,
    String? shift,
    String? machineName,
    String? status,
  }) {
    return ResistorMachineRequest(
      dateRange: dateRange ?? this.dateRange,
      shift: shift ?? this.shift,
      machineName: machineName ?? this.machineName,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toBody() {
    return <String, dynamic>{
      'DateRange': dateRange,
      'Shift': shift,
      'MachineName': machineName,
      'Status': status,
    };
  }

  @override
  List<Object?> get props => <Object?>[dateRange, shift, machineName, status];
}

class ResistorMachineSummary extends Equatable {
  const ResistorMachineSummary({
    required this.wip,
    required this.pass,
    required this.fail,
    required this.firstFail,
    required this.retest,
    required this.yieldRate,
    required this.retestRate,
  });

  final int wip;
  final int pass;
  final int fail;
  final int firstFail;
  final int retest;
  final double yieldRate;
  final double retestRate;

  int get total => pass + fail;

  @override
  List<Object?> get props => <Object?>[
        wip,
        pass,
        fail,
        firstFail,
        retest,
        yieldRate,
        retestRate,
      ];
}

class ResistorMachineOutput extends Equatable {
  const ResistorMachineOutput({
    required this.section,
    required this.workDate,
    required this.pass,
    required this.fail,
    required this.firstFail,
    required this.retest,
    required this.yieldRate,
    required this.retestRate,
  });

  final int? section;
  final String? workDate;
  final int pass;
  final int fail;
  final int firstFail;
  final int retest;
  final double yieldRate;
  final double retestRate;

  String get displayLabel {
    if (section != null) {
      return 'S${section!}';
    }
    return workDate ?? '';
  }

  @override
  List<Object?> get props => <Object?>[
        section,
        workDate,
        pass,
        fail,
        firstFail,
        retest,
        yieldRate,
        retestRate,
      ];
}

class ResistorMachineInfo extends Equatable {
  const ResistorMachineInfo({
    required this.name,
    required this.pass,
    required this.fail,
    required this.firstFail,
    required this.retest,
    required this.yieldRate,
    required this.retestRate,
  });

  final String name;
  final int pass;
  final int fail;
  final int firstFail;
  final int retest;
  final double yieldRate;
  final double retestRate;

  int get total => pass + fail;

  @override
  List<Object?> get props => <Object?>[
        name,
        pass,
        fail,
        firstFail,
        retest,
        yieldRate,
        retestRate,
      ];
}

class ResistorMachineTrackingData extends Equatable {
  const ResistorMachineTrackingData({
    required this.summary,
    required this.outputs,
    required this.machines,
  });

  final ResistorMachineSummary summary;
  final List<ResistorMachineOutput> outputs;
  final List<ResistorMachineInfo> machines;
  // Factory dữ liệu trống để fallback khi API lỗi hoặc không có dữ liệu
  factory ResistorMachineTrackingData.empty() {
    return const ResistorMachineTrackingData(
      summary: ResistorMachineSummary(
        wip: 0,
        pass: 0,
        fail: 0,
        firstFail: 0,
        retest: 0,
        yieldRate: 0.0,
        retestRate: 0.0,
      ),
      outputs: [],
      machines: [],
    );
  }
  @override
  List<Object?> get props => <Object?>[summary, outputs, machines];
}

class ResistorMachineStatus extends Equatable {
  const ResistorMachineStatus({
    required this.id,
    required this.serialNumber,
    required this.machineName,
    required this.inStationTime,
    required this.stationSequence,
  });

  final int id;
  final String serialNumber;
  final String machineName;
  final DateTime inStationTime;
  final int stationSequence;

  @override
  List<Object?> get props => <Object?>[
        id,
        serialNumber,
        machineName,
        inStationTime,
        stationSequence,
      ];
}

class ResistorMachineRecord extends Equatable {
  const ResistorMachineRecord({
    required this.id,
    required this.workDate,
    required this.workSection,
    required this.classDate,
    required this.className,
    required this.factory,
    required this.machineName,
    required this.serialNumber,
    required this.moNumber,
    required this.modelName,
    required this.groupName,
    required this.goodQty,
    required this.passQty,
    required this.failQty,
    required this.stationSequence,
    required this.inStationTime,
    required this.employeeId,
    required this.cycleTime,
    required this.carrierCode,
    required this.errorCode,
    required this.dataSummary,
    required this.dataDetails,
    required this.packageRevision,
    required this.errorDescription,
  });

  final int id;
  final String workDate;
  final int workSection;
  final String classDate;
  final String className;
  final String factory;
  final String machineName;
  final String? serialNumber;
  final String? moNumber;
  final String? modelName;
  final String? groupName;
  final int goodQty;
  final int passQty;
  final int failQty;
  final int stationSequence;
  final DateTime inStationTime;
  final String? employeeId;
  final double? cycleTime;
  final String? carrierCode;
  final String? errorCode;
  final String? dataSummary;
  final String? dataDetails;
  final String? packageRevision;
  final String? errorDescription;

  bool get isPass => failQty == 0;

  @override
  List<Object?> get props => <Object?>[
        id,
        workDate,
        workSection,
        classDate,
        className,
        factory,
        machineName,
        serialNumber,
        moNumber,
        modelName,
        groupName,
        goodQty,
        passQty,
        failQty,
        stationSequence,
        inStationTime,
        employeeId,
        cycleTime,
        carrierCode,
        errorCode,
        dataSummary,
        dataDetails,
        packageRevision,
        errorDescription,
      ];
}

class ResistorMachineTestResult extends Equatable {
  const ResistorMachineTestResult({
    required this.address,
    required this.result,
    required this.imagePath,
    required this.details,
  });

  final int address;
  final bool result;
  final String imagePath;
  final List<ResistorMachineResultDetail> details;

  @override
  List<Object?> get props => <Object?>[address, result, imagePath, details];
}

class ResistorMachineResultDetail extends Equatable {
  const ResistorMachineResultDetail({
    required this.name,
    required this.row,
    required this.column,
    required this.measurementValue,
    required this.lowSampleValue,
    required this.highSampleValue,
    required this.pass,
  });

  final String name;
  final int row;
  final int column;
  final double measurementValue;
  final double lowSampleValue;
  final double highSampleValue;
  final bool pass;

  @override
  List<Object?> get props => <Object?>[
        name,
        row,
        column,
        measurementValue,
        lowSampleValue,
        highSampleValue,
        pass,
      ];
}

class ResistorMachineSerialMatch extends Equatable {
  const ResistorMachineSerialMatch({
    required this.id,
    required this.serialNumber,
    required this.sequence,
  });

  final int id;
  final String serialNumber;
  final int sequence;

  @override
  List<Object?> get props => <Object?>[id, serialNumber, sequence];
}
