import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/sensor_overview.dart';

class SensorOverviewModel extends SensorOverview {
  const SensorOverviewModel({
    required super.totalSensors,
    required super.onlineSensors,
    required super.warningSensors,
    required super.offlineSensors,
  });

  factory SensorOverviewModel.fromJson(Map<String, dynamic> json) {
    return SensorOverviewModel(
      totalSensors: json['totalSensors'] as int? ?? json['total'] as int? ?? 0,
      onlineSensors: json['onlineSensors'] as int? ?? json['online'] as int? ?? 0,
      warningSensors:
          json['warningSensors'] as int? ?? json['warning'] as int? ?? 0,
      offlineSensors:
          json['offlineSensors'] as int? ?? json['offline'] as int? ?? 0,
    );
  }
}

class SensorDataResponseModel extends SensorDataResponse {
  const SensorDataResponseModel({
    required super.sensorName,
    required super.sensorDesc,
    required super.data,
    required super.categories,
    required super.series,
  });

  factory SensorDataResponseModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawData = json['data'] as List<dynamic>? ?? [];
    final List<dynamic> rawCategories = json['categories'] as List<dynamic>? ?? [];
    final List<dynamic> rawSeries = json['series'] as List<dynamic>? ?? [];

    return SensorDataResponseModel(
      sensorName: json['sensorName'] as String? ?? json['sensor'] as String? ?? '',
      sensorDesc: json['sensorDesc'] as String? ?? json['description'] as String? ?? '',
      data: rawData
          .whereType<Map<String, dynamic>>()
          .map(SensorDataPointModel.fromJson)
          .toList(),
      categories: rawCategories
          .map((e) => e is List
              ? SensorCategory(categories: e.map((v) => '$v').toList())
              : SensorCategory(categories: ['$e']))
          .toList(),
      series: rawSeries
          .whereType<Map<String, dynamic>>()
          .map(SensorSeriesModel.fromJson)
          .toList(),
    );
  }
}

class SensorDataPointModel extends SensorDataPoint {
  const SensorDataPointModel({
    required super.paramName,
    required super.paramDisplayName,
    required super.value,
    required super.result,
    required super.precision,
    super.isUp,
    super.delta,
    super.timestamp,
  });

  factory SensorDataPointModel.fromJson(Map<String, dynamic> json) {
    return SensorDataPointModel(
      paramName: json['paramName'] as String? ?? json['parameter'] as String? ?? '',
      paramDisplayName:
          json['paramDisplayName'] as String? ?? json['paramName'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      result: json['result'] as String? ?? '',
      precision: json['precision'] as int? ?? 0,
      isUp: json['isUp'] as bool?,
      delta: (json['delta'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }
}

class SensorSeriesModel extends SensorSeries {
  const SensorSeriesModel({required super.name, required super.data, super.maxValue});

  factory SensorSeriesModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final List<double> parsedData;
    if (rawData is List) {
      parsedData = rawData.map((e) => (e as num?)?.toDouble() ?? 0).toList();
    } else {
      parsedData = const <double>[];
    }

    return SensorSeriesModel(
      name: json['name'] as String? ?? json['parameterName'] as String? ?? '',
      data: parsedData,
      maxValue: (json['maxValue'] as num?)?.toDouble() ??
          (json['parameterMaxValue'] as num?)?.toDouble(),
    );
  }
}
