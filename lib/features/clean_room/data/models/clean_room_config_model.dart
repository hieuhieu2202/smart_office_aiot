import '../../domain/entities/clean_room_config.dart';

class CleanRoomConfigModel extends CleanRoomConfig {
  CleanRoomConfigModel({
    required super.id,
    required super.image,
    required super.imageBrightness,
    required super.data,
  });

  factory CleanRoomConfigModel.fromJson(Map<String, dynamic> json) {
    return CleanRoomConfigModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      image: json['image'] as String?,
      imageBrightness: (json['imageBrightness'] as num?)?.toDouble() ?? 1,
      data: json['data'] as String?,
    );
  }
}

class PositionMappingModel extends PositionMapping {
  PositionMappingModel({
    required super.top,
    required super.left,
    required super.size,
    required super.sensorName,
    required super.speechType,
  });

  factory PositionMappingModel.fromJson(Map<String, dynamic> json) {
    return PositionMappingModel(
      top: (json['top'] as num?)?.toDouble() ?? 0,
      left: (json['left'] as num?)?.toDouble() ?? 0,
      size: (json['size'] as num?)?.toDouble() ?? 12,
      sensorName: json['sensorName'] as String? ?? '',
      speechType: json['speechType'] as String? ?? 'top-mid',
    );
  }
}
