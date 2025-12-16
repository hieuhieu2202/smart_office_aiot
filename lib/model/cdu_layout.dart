// lib/model/cdu_layout.dart
import 'dart:convert';

class CduLayout {
  const CduLayout({
    required this.id,
    required this.factory,
    required this.floor,
    required this.image,
    required this.data,
    this.editer,
    this.dateTime,
  });

  final String id;
  final String factory;
  final String floor;
  final String image;
  final List<Map<String, dynamic>> data;
  final String? editer;
  final DateTime? dateTime;

  factory CduLayout.fromJson(Map<String, dynamic> json) {
    // Parse the data field - it might be a stringified JSON array
    List<Map<String, dynamic>> parsedData = [];
    final dataField = json['data'] ?? json['Data'];
    
    if (dataField is String) {
      // If data is a stringified JSON, parse it
      try {
        final decoded = jsonDecode(dataField);
        if (decoded is List) {
          parsedData = decoded
              .whereType<Map>()
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (e) {
        // If parsing fails, leave data as empty list
        parsedData = [];
      }
    } else if (dataField is List) {
      // If data is already a list, use it directly
      parsedData = dataField
          .whereType<Map>()
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    // Parse dateTime field
    DateTime? parsedDateTime;
    final dateTimeField = json['dateTime'] ?? json['DateTime'];
    if (dateTimeField is String && dateTimeField.isNotEmpty) {
      parsedDateTime = DateTime.tryParse(dateTimeField);
    } else if (dateTimeField is int) {
      parsedDateTime = DateTime.fromMillisecondsSinceEpoch(dateTimeField);
    }

    return CduLayout(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      factory: (json['factory'] ?? json['Factory'] ?? '').toString(),
      floor: (json['floor'] ?? json['Floor'] ?? '').toString(),
      image: (json['image'] ?? json['Image'] ?? '').toString(),
      data: parsedData,
      editer: json['editer'] ?? json['Editer'],
      dateTime: parsedDateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'factory': factory,
      'floor': floor,
      'image': image,
      'data': jsonEncode(data),
      'editer': editer,
      'dateTime': dateTime?.toIso8601String(),
    };
  }
}
