import 'package:equatable/equatable.dart';

class SensorOverview extends Equatable {
  const SensorOverview({
    required this.totalSensors,
    required this.onlineSensors,
    required this.warningSensors,
    required this.offlineSensors,
  });

  final int totalSensors;
  final int onlineSensors;
  final int warningSensors;
  final int offlineSensors;

  @override
  List<Object?> get props => [
        totalSensors,
        onlineSensors,
        warningSensors,
        offlineSensors,
      ];
}
