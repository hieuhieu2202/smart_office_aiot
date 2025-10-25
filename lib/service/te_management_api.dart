import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/te_management/te_report_models.dart';
import 'auth/auth_config.dart';

class TEManagementApi {
  static const String _baseUrl =
      'https://10.220.130.117/newweb/api/nvidia/temanagement/TEManagement';

  static Map<String, String> _headers({bool includeContentType = false}) {
    final headers = Map<String, String>.from(AuthConfig.getAuthorizedHeaders());
    headers['Accept'] = 'application/json';
    if (!includeContentType) {
      headers.remove('Content-Type');
    }
    return headers;
  }

  static Uri _buildUri(String path, Map<String, String?> query) {
    final filtered = <String, String>{};
    query.forEach((key, value) {
      if (value != null && value.trim().isNotEmpty) {
        filtered[key] = value.trim();
      }
    });
    return Uri.parse('$_baseUrl/$path').replace(queryParameters: filtered);
  }

  static Future<List<Map<String, dynamic>>> fetchTableDetail({
    String modelSerial = 'SWITCH',
    required String rangeDateTime,
    String model = '',
  }) async {
    final uri = _buildUri('TEReport', {
      'customer': modelSerial,
      'range': rangeDateTime,
      'model': model,
    });
    print('>> [TEManagementApi] GET $uri');

    final stopwatch = Stopwatch()..start();
    final res = await http.get(uri, headers: _headers());
    stopwatch.stop();
    print(
      '>> [TEManagementApi] Response status=${res.statusCode} length=${res.body.length} '
      'elapsed=${stopwatch.elapsedMilliseconds}ms',
    );

    if (res.statusCode == 204 || res.body.isEmpty) {
      return [];
    }
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load TE management data (${res.statusCode})');
    }

    final dynamic decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .map<Map<String, dynamic>>((item) =>
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>))
          .toList();
    }
    throw Exception('Unexpected TEReport payload format');
  }

  static Future<List<String>> fetchModelNames({
    required String modelSerial,
  }) async {
    final uri = _buildUri('ModelNames', {
      'customer': modelSerial,
    });
    print('>> [TEManagementApi] GET $uri');

    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 204 || res.body.isEmpty) {
      return const [];
    }
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load TE model names (${res.statusCode})');
    }

    dynamic decoded;
    try {
      decoded = json.decode(res.body);
    } catch (e) {
      print('>> [TEManagementApi] Failed to decode model names: $e');
      return const [];
    }

    if (decoded is List) {
      final names = decoded
          .map((item) {
            if (item is Map) {
              return (item['MODEL_NAME'] ?? item['model_name'] ?? '').toString();
            }
            return item?.toString() ?? '';
          })
          .where((name) => name.trim().isNotEmpty)
          .map((name) => name.trim())
          .toSet()
          .toList()
        ..sort();
      return names;
    }

    return const [];
  }

  static Future<TEErrorDetail?> fetchErrorDetail({
    required String modelSerial,
    required String rangeDateTime,
    required String model,
    required String group,
  }) async {
    final uri = _buildUri('ErrorDetail', {
      'customer': modelSerial,
      'range': rangeDateTime,
      'model': model,
      'group': group,
    });
    print('>> [TEManagementApi] GET $uri');

    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 204 || res.body.isEmpty) {
      return null;
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to load error detail (${res.statusCode})');
    }

    final Map<String, dynamic> jsonMap =
        json.decode(res.body) as Map<String, dynamic>;
    return TEErrorDetail.fromJson(jsonMap);
  }
}
