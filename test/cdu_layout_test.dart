import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_factory/model/cdu_layout.dart';

void main() {
  group('CduLayout', () {
    test('should parse JSON with stringified data field', () {
      final jsonResponse = {
        'id': '123',
        'factory': 'F16',
        'floor': '3F',
        'image': 'base64_image_data',
        'data': jsonEncode([
          {'CDUName': 'CDU001', 'Left': 10, 'Top': 20, 'Width': 5, 'Height': 5},
          {'CDUName': 'CDU002', 'Left': 30, 'Top': 40, 'Width': 5, 'Height': 5},
        ]),
        'editer': 'admin',
        'dateTime': '2025-12-16T03:40:00Z',
      };

      final layout = CduLayout.fromJson(jsonResponse);

      expect(layout.id, '123');
      expect(layout.factory, 'F16');
      expect(layout.floor, '3F');
      expect(layout.image, 'base64_image_data');
      expect(layout.data.length, 2);
      expect(layout.data[0]['CDUName'], 'CDU001');
      expect(layout.data[1]['CDUName'], 'CDU002');
      expect(layout.editer, 'admin');
      expect(layout.dateTime, isNotNull);
    });

    test('should parse JSON with already-parsed data field', () {
      final jsonResponse = {
        'id': '456',
        'Factory': 'F17',
        'Floor': '2F',
        'Image': 'base64_image_data_2',
        'Data': [
          {'CDUName': 'CDU003', 'Left': 50, 'Top': 60},
          {'CDUName': 'CDU004', 'Left': 70, 'Top': 80},
        ],
        'Editer': 'user1',
        'DateTime': '2025-12-16T10:00:00Z',
      };

      final layout = CduLayout.fromJson(jsonResponse);

      expect(layout.id, '456');
      expect(layout.factory, 'F17');
      expect(layout.floor, '2F');
      expect(layout.image, 'base64_image_data_2');
      expect(layout.data.length, 2);
      expect(layout.data[0]['CDUName'], 'CDU003');
      expect(layout.data[1]['CDUName'], 'CDU004');
      expect(layout.editer, 'user1');
      expect(layout.dateTime, isNotNull);
    });

    test('should handle missing optional fields', () {
      final jsonResponse = {
        'id': '789',
        'factory': 'F16',
        'floor': '1F',
        'image': 'image_data',
        'data': '[]',
      };

      final layout = CduLayout.fromJson(jsonResponse);

      expect(layout.id, '789');
      expect(layout.factory, 'F16');
      expect(layout.floor, '1F');
      expect(layout.image, 'image_data');
      expect(layout.data.length, 0);
      expect(layout.editer, isNull);
      expect(layout.dateTime, isNull);
    });

    test('should handle malformed data field gracefully', () {
      final jsonResponse = {
        'id': '999',
        'factory': 'F16',
        'floor': '3F',
        'image': 'image_data',
        'data': 'invalid_json',
      };

      final layout = CduLayout.fromJson(jsonResponse);

      expect(layout.id, '999');
      expect(layout.data.length, 0); // Should return empty list on parse error
    });

    test('should serialize to JSON correctly', () {
      final layout = CduLayout(
        id: '123',
        factory: 'F16',
        floor: '3F',
        image: 'base64_image_data',
        data: [
          {'CDUName': 'CDU001', 'Status': 'Running'},
          {'CDUName': 'CDU002', 'Status': 'Warning'},
        ],
        editer: 'admin',
        dateTime: DateTime.parse('2025-12-16T03:40:00Z'),
      );

      final json = layout.toJson();

      expect(json['id'], '123');
      expect(json['factory'], 'F16');
      expect(json['floor'], '3F');
      expect(json['image'], 'base64_image_data');
      expect(json['data'], isA<String>());
      expect(json['editer'], 'admin');
      expect(json['dateTime'], '2025-12-16T03:40:00.000Z');

      // Verify the data field is properly encoded
      final decodedData = jsonDecode(json['data']) as List;
      expect(decodedData.length, 2);
    });
  });
}
