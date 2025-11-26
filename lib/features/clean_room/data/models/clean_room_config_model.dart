import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/clean_room_config.dart';

class CleanRoomConfigModel extends CleanRoomConfig {
  CleanRoomConfigModel({
    required super.id,
    required super.image,
    required super.imageBytes,
    required super.imageBrightness,
    required super.data,
  });

  factory CleanRoomConfigModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image'] as String?;
    final Uint8List? decodedBytes = _decodeBase64(rawImage);
    return CleanRoomConfigModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      image: rawImage,
      imageBytes: decodedBytes,
      imageBrightness: (json['imageBrightness'] as num?)?.toDouble() ?? 1,
      data: json['data'] as String?,
    );
  }
}

Uint8List? _decodeBase64(String? value) {
  if (value == null || value.isEmpty) return null;
  final lower = value.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return null;
  }

  try {
    final cleaned = value.contains(',') ? value.split(',').last : value;
    final normalized = cleaned.replaceAll(RegExp(r'\s'), '');
    return base64Decode(normalized);
  } catch (_) {
    return null;
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
    double _parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    String _parseSensorName(Map<String, dynamic> source) {
      return source['sensorName']?.toString() ??
          source['sensor']?.toString() ??
          source['SensorName']?.toString() ??
          source['SensorId']?.toString() ??
          '';
    }

    return PositionMappingModel(
      top: _parseDouble(json['top'] ?? json['Top']),
      left: _parseDouble(json['left'] ?? json['Left']),
      size: _parseDouble(json['size'] ?? json['Size'] ?? 12),
      sensorName: _parseSensorName(json),
      speechType: (json['speechType'] ?? json['SpeechType']) as String? ??
          'top-mid',
    );
  }
}
