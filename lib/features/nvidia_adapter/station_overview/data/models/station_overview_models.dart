import '../../domain/entities/station_overview_entities.dart';

dynamic _valueForKey(Map<String, dynamic> json, String key) {
  final String normalized = key.toUpperCase();
  for (final MapEntry<dynamic, dynamic> entry in json.entries) {
    final dynamic rawKey = entry.key;
    if (rawKey == null) continue;
    if (rawKey.toString().toUpperCase() == normalized) {
      return entry.value;
    }
  }
  return null;
}

String _stringForKey(Map<String, dynamic> json, String key) {
  final dynamic value = _valueForKey(json, key);
  if (value == null) return '';
  return value.toString();
}

List<dynamic> _listForKey(Map<String, dynamic> json, String key) {
  final dynamic value = _valueForKey(json, key);
  if (value is List) {
    return value;
  }
  if (value == null) {
    return const <dynamic>[];
  }
  return <dynamic>[value];
}

int _intForKey(Map<String, dynamic> json, String key) {
  final dynamic value = _valueForKey(json, key);
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

class StationProductModel extends StationProduct {
  const StationProductModel({
    required super.productName,
    required super.modelNames,
  });

  factory StationProductModel.fromJson(Map<String, dynamic> json) {
    final Iterable<dynamic> rawModels = _listForKey(json, 'MODEL_NAMES');
    final List<String> models = <String>[];
    for (final dynamic item in rawModels) {
      if (item == null) continue;
      final String value = item.toString().trim();
      if (value.isNotEmpty) {
        models.add(value.toUpperCase());
      }
    }
    return StationProductModel(
      productName: _stringForKey(json, 'PRODUCT_NAME').trim().toUpperCase(),
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
    final dynamic groupsJson = _valueForKey(json, 'GROUP_DATAS');
    final List<StationGroupData> groups = <StationGroupData>[];
    if (groupsJson is List) {
      for (final dynamic item in groupsJson) {
        if (item is Map<String, dynamic>) {
          groups.add(StationGroupDataModel.fromJson(item));
        }
      }
    }
    return StationOverviewDataModel(
      productName: _stringForKey(json, 'PRODUCT_NAME').trim().toUpperCase(),
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
    final dynamic stationsJson = _valueForKey(json, 'STATION_DATAS');
    final List<StationData> stations = <StationData>[];
    if (stationsJson is List) {
      for (final dynamic item in stationsJson) {
        if (item is Map<String, dynamic>) {
          stations.add(StationDataModel.fromJson(item));
        }
      }
    }
    return StationGroupDataModel(
      groupName: _stringForKey(json, 'GROUP_NAME').trim().toUpperCase(),
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
    return StationDataModel(
      stationName: _stringForKey(json, 'STATION_NAME').trim().toUpperCase(),
      input: _intForKey(json, 'INPUT'),
      firstFail: _intForKey(json, 'FIRST_FAIL'),
      repairQty: _intForKey(json, 'REPAIR_QTY'),
      firstPass: _intForKey(json, 'FIRST_PASS'),
      pass: _intForKey(json, 'PASS'),
      secondPass: _intForKey(json, 'SECOND_PASS'),
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
    return StationAnalysisDataModel(
      classDate: _stringForKey(json, 'CLASS_DATE'),
      errorCode: _stringForKey(json, 'ERROR_CODE').trim().toUpperCase(),
      failCount: _intForKey(json, 'FAIL_COUNT'),
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
      empNo: _stringForKey(json, 'EMP_NO').trim().toUpperCase(),
      moNumber: _stringForKey(json, 'MO_NUMBER').trim().toUpperCase(),
      modelName: _stringForKey(json, 'MODEL_NAME').trim().toUpperCase(),
      serialNumber: _stringForKey(json, 'SERIAL_NUMBER').trim().toUpperCase(),
      lineName: _stringForKey(json, 'LINE_NAME').trim().toUpperCase(),
      groupName: _stringForKey(json, 'GROUP_NAME').trim().toUpperCase(),
      stationName: _stringForKey(json, 'STATION_NAME').trim().toUpperCase(),
      errorCode: _stringForKey(json, 'ERROR_CODE').trim().toUpperCase(),
      description: _stringForKey(json, 'DESCRIPTION'),
      cycleTime: _stringForKey(json, 'CYCLE_TIME'),
      inStationTime: parseDate(_valueForKey(json, 'IN_STATION_TIME')),
    );
  }
}
