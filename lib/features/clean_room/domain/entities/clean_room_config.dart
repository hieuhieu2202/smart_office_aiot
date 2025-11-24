import 'package:equatable/equatable.dart';

class CleanRoomConfig extends Equatable {
  const CleanRoomConfig({
    required this.id,
    required this.image,
    required this.imageBrightness,
    required this.data,
  });

  final int id;
  final String? image;
  final double imageBrightness;
  final String? data;

  @override
  List<Object?> get props => [id, image, imageBrightness, data];
}

class PositionMapping extends Equatable {
  const PositionMapping({
    required this.top,
    required this.left,
    required this.size,
    required this.sensorName,
    required this.speechType,
  });

  final double top;
  final double left;
  final double size;
  final String sensorName;
  final String speechType;

  @override
  List<Object?> get props => [top, left, size, sensorName, speechType];
}
