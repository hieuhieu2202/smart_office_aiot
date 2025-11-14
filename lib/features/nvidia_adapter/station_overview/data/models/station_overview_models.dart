import '../../domain/entities/station_overview_entities.dart';

class StationProductModel extends StationProduct {
  const StationProductModel({
    required super.productName,
    required super.modelNames,
  });

  factory StationProductModel.fromJson(Map<String, dynamic> json) {
    final List<String> models = <String>[];
    final dynamic rawModels = json['MODEL_NAMES'];
    if (rawModels is List) {
      for (final dynamic item in rawModels) {
        if (item != null) {
          models.add(item.toString());
        }
      }
    }
    return StationProductModel(
      productName: json['PRODUCT_NAME']?.toString() ?? '',
      modelNames: models,
    );
  }
}

class StationOverviewDataModel extends StationOverviewData {
  StationOverviewDataModel({
    required super.productName,
    required super.groupDatas,
  });

  factory StationOverviewDataModel.fromJson(Map<String, dynamic> json) {
    final dynamic groupsJson = json['GROUP_DATAS'];
    final List<StationGroupData> groups = <StationGroupData>[];
    if (groupsJson is List) {
      for (final dynamic item in groupsJson) {
        if (item is Map<String, dynamic>) {
          groups.add(StationGroupDataModel.fromJson(item));
        }
      }
    }
    return StationOverviewDataModel(
      productName: json['PRODUCT_NAME']?.toString() ?? '',
      groupDatas: groups,
    );
  }
}

class StationGroupDataModel extends StationGroupData {
  StationGroupDataModel({
    required super.groupName,
    required super.stationDatas,
  });

  factory StationGroupDataModel.fromJson(Map<String, dynamic> json) {
    final dynamic stationsJson = json['STATION_DATAS'];
    final List<StationData> stations = <StationData>[];
    if (stationsJson is List) {
      for (final dynamic item in stationsJson) {
        if (item is Map<String, dynamic>) {
          stations.add(StationDataModel.fromJson(item));
        }
      }
    }
    return StationGroupDataModel(
      groupName: json['GROUP_NAME']?.toString() ?? '',
      stationDatas: stations,
    );
  }
}

class StationDataModel extends StationData {
  StationDataModel({
    required super.stationName,
    required super.input,
    required super.firstFail,
    required super.repairQty,
    required super.firstPass,
    required super.pass,
    required super.secondPass,
  });

  factory StationDataModel.fromJson(Map<String, dynamic> json) {
    int _intValue(String key) {
      final dynamic value = json[key];
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return StationDataModel(
      stationName: json['STATION_NAME']?.toString() ?? '',
      input: _intValue('INPUT'),
      firstFail: _intValue('FIRST_FAIL'),
      repairQty: _intValue('REPAIR_QTY'),
      firstPass: _intValue('FIRST_PASS'),
      pass: _intValue('PASS'),
      secondPass: _intValue('SECOND_PASS'),
    );
  }
}

class StationAnalysisDataModel extends StationAnalysisData {
  StationAnalysisDataModel({
    required super.classDate,
    required super.errorCode,
    required super.failCount,
  });

  factory StationAnalysisDataModel.fromJson(Map<String, dynamic> json) {
    final dynamic fail = json['FAIL_COUNT'];
    int parsedFail = 0;
    if (fail is num) {
      parsedFail = fail.toInt();
    } else if (fail is String) {
      parsedFail = int.tryParse(fail) ?? 0;
    }

    return StationAnalysisDataModel(
      classDate: json['CLASS_DATE']?.toString() ?? '',
      errorCode: json['ERROR_CODE']?.toString() ?? '',
      failCount: parsedFail,
    );
  }
}

class StationDetailDataModel extends StationDetailData {
  StationDetailDataModel({
    required super.empNo,
    required super.moNumber,
    required super.modelName,
    required super.serialNumber,
    required super.lineName,
    required super.groupName,
    required super.stationName,
    required super.errorCode,
    required super.description,
    required super.cycleTime,
    required super.inStationTime,
  });

  factory StationDetailDataModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      final String text = value.toString();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return StationDetailDataModel(
      empNo: json['EMP_NO']?.toString() ?? '',
      moNumber: json['MO_NUMBER']?.toString() ?? '',
      modelName: json['MODEL_NAME']?.toString() ?? '',
      serialNumber: json['SERIAL_NUMBER']?.toString() ?? '',
      lineName: json['LINE_NAME']?.toString() ?? '',
      groupName: json['GROUP_NAME']?.toString() ?? '',
      stationName: json['STATION_NAME']?.toString() ?? '',
      errorCode: json['ERROR_CODE']?.toString() ?? '',
      description: json['DESCRIPTION']?.toString() ?? '',
      cycleTime: json['CYCLE_TIME']?.toString() ?? '',
      inStationTime: parseDate(json['IN_STATION_TIME']),
    );
  }
}
