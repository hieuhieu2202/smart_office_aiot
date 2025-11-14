import 'package:equatable/equatable.dart';

class StationOverviewFilter extends Equatable {
  const StationOverviewFilter({
    required this.modelSerial,
    this.dateRange,
    this.productName,
    this.modelName,
    this.groupNames = const <String>[],
    this.stationName,
    this.detailType,
  });

  final String modelSerial;
  final String? dateRange;
  final String? productName;
  final String? modelName;
  final List<String> groupNames;
  final String? stationName;
  final StationDetailType? detailType;

  StationOverviewFilter copyWith({
    String? modelSerial,
    String? dateRange,
    String? productName,
    String? modelName,
    List<String>? groupNames,
    String? stationName,
    StationDetailType? detailType,
  }) {
    return StationOverviewFilter(
      modelSerial: modelSerial ?? this.modelSerial,
      dateRange: dateRange ?? this.dateRange,
      productName: productName ?? this.productName,
      modelName: modelName ?? this.modelName,
      groupNames: groupNames ?? this.groupNames,
      stationName: stationName ?? this.stationName,
      detailType: detailType ?? this.detailType,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        modelSerial,
        dateRange,
        productName,
        modelName,
        groupNames,
        stationName,
        detailType,
      ];
}

class StationProduct extends Equatable {
  const StationProduct({
    required this.productName,
    required this.modelNames,
  });

  final String productName;
  final List<String> modelNames;

  @override
  List<Object?> get props => <Object?>[productName, modelNames];
}

class StationOverviewData extends Equatable {
  const StationOverviewData({
    required this.productName,
    required this.groupDatas,
  });

  final String productName;
  final List<StationGroupData> groupDatas;

  StationGroupData? findGroup(String name) {
    return groupDatas.firstWhere(
      (group) => group.groupName == name,
      orElse: () => const StationGroupData(groupName: '', stationDatas: <StationData>[]),
    );
  }

  @override
  List<Object?> get props => <Object?>[productName, groupDatas];
}

class StationGroupData extends Equatable {
  const StationGroupData({
    required this.groupName,
    required this.stationDatas,
  });

  final String groupName;
  final List<StationData> stationDatas;

  @override
  List<Object?> get props => <Object?>[groupName, stationDatas];
}

class StationData extends Equatable {
  const StationData({
    required this.stationName,
    required this.input,
    required this.firstFail,
    required this.repairQty,
    required this.firstPass,
    required this.pass,
    required this.secondPass,
  });

  final String stationName;
  final int input;
  final int firstFail;
  final int repairQty;
  final int firstPass;
  final int pass;
  final int secondPass;

  double get yieldRate {
    if (input <= 0) return 0;
    final rate = pass / input;
    return rate > 1 ? 1 : rate;
  }

  double get retestRate {
    if (input <= 0) return 0;
    final rate = secondPass / input;
    return rate > 1 ? 1 : rate;
  }

  int get failQty => firstFail;

  @override
  List<Object?> get props => <Object?>[
        stationName,
        input,
        firstFail,
        repairQty,
        firstPass,
        pass,
        secondPass,
      ];
}

class StationAnalysisData extends Equatable {
  const StationAnalysisData({
    required this.classDate,
    required this.errorCode,
    required this.failCount,
  });

  final String classDate;
  final String errorCode;
  final int failCount;

  @override
  List<Object?> get props => <Object?>[classDate, errorCode, failCount];
}

class StationDetailData extends Equatable {
  const StationDetailData({
    required this.empNo,
    required this.moNumber,
    required this.modelName,
    required this.serialNumber,
    required this.lineName,
    required this.groupName,
    required this.stationName,
    required this.errorCode,
    required this.description,
    required this.cycleTime,
    required this.inStationTime,
  });

  final String empNo;
  final String moNumber;
  final String modelName;
  final String serialNumber;
  final String lineName;
  final String groupName;
  final String stationName;
  final String errorCode;
  final String description;
  final String cycleTime;
  final DateTime? inStationTime;

  @override
  List<Object?> get props => <Object?>[
        empNo,
        moNumber,
        modelName,
        serialNumber,
        lineName,
        groupName,
        stationName,
        errorCode,
        description,
        cycleTime,
        inStationTime,
      ];
}

class StationRateConfig extends Equatable {
  const StationRateConfig({
    required this.yieldRateLower,
    required this.yieldRateUpper,
    required this.retestRateLower,
    required this.retestRateUpper,
  });

  const StationRateConfig.defaults()
      : yieldRateLower = 0.95,
        yieldRateUpper = 0.98,
        retestRateLower = 0.05,
        retestRateUpper = 0.10;

  final double yieldRateLower;
  final double yieldRateUpper;
  final double retestRateLower;
  final double retestRateUpper;

  @override
  List<Object?> get props => <Object?>[
        yieldRateLower,
        yieldRateUpper,
        retestRateLower,
        retestRateUpper,
      ];
}

enum StationStatus { error, warning, normal, offline }

enum StationDetailType {
  input('INPUT'),
  pass('PASS'),
  firstFail('FIRST_FAIL'),
  secondFail('SECOND_FAIL'),
  retestRate('RETEST_RATE'),
  yieldRate('YIELD_RATE');

  const StationDetailType(this.apiKey);
  final String apiKey;
}

extension StationStatusX on StationStatus {
  String get label {
    switch (this) {
      case StationStatus.error:
        return 'ERROR';
      case StationStatus.warning:
        return 'WARNING';
      case StationStatus.normal:
        return 'NORMAL';
      case StationStatus.offline:
        return 'OFFLINE';
    }
  }
}
