import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class CleanRoomConfig extends Equatable {
  const CleanRoomConfig({
    required this.id,
    required this.image,
    required this.imageBytes,
    required this.imageBrightness,
    required this.data,
  });

  final int id;
  final String? image;
  final Uint8List? imageBytes;
  final double imageBrightness;
  final String? data;

  @override
  List<Object?> get props => [id, image, imageBytes, imageBrightness, data];
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
