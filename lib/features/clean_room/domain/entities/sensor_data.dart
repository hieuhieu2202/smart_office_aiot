import 'package:equatable/equatable.dart';

class SensorDataResponse extends Equatable {
  const SensorDataResponse({
    required this.sensorName,
    required this.sensorDesc,
    required this.data,
    required this.categories,
    required this.series,
  });

  final String sensorName;
  final String sensorDesc;
  final List<SensorDataPoint> data;
  final List<SensorCategory> categories;
  final List<SensorSeries> series;

  @override
  List<Object?> get props => [sensorName, sensorDesc, data, categories, series];
}

class SensorDataPoint extends Equatable {
  const SensorDataPoint({
    required this.paramName,
    required this.paramDisplayName,
    required this.value,
    required this.result,
    required this.precision,
    this.isUp,
    this.delta,
    this.timestamp,
  });

  final String paramName;
  final String paramDisplayName;
  final double value;
  final String result;
  final int precision;
  final bool? isUp;
  final double? delta;
  final DateTime? timestamp;

  @override
  List<Object?> get props => [
        paramName,
        paramDisplayName,
        value,
        result,
        precision,
        isUp,
        delta,
        timestamp,
      ];
}

class SensorCategory extends Equatable {
  const SensorCategory({required this.categories});

  final List<String> categories;

  @override
  List<Object?> get props => [categories];
}

class SensorSeries extends Equatable {
  const SensorSeries({
    required this.name,
    required this.data,
    this.maxValue,
  });

  final String name;
  final List<double> data;
  final double? maxValue;

  @override
  List<Object?> get props => [name, data, maxValue];
}
