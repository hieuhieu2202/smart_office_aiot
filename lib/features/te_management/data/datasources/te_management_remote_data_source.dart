import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../service/auth/auth_config.dart';
import '../models/te_report_models.dart';
import '../models/te_retest_rate_models.dart';

class TEManagementRemoteDataSource {
  static const String _baseUrl =
      'https://10.220.130.117/newweb/api/nvidia/temanagement/TEManagement';

  Map<String, String> _headers({bool includeContentType = false}) {
    final headers = Map<String, String>.from(AuthConfig.getAuthorizedHeaders());
    headers['Accept'] = 'application/json';
    if (!includeContentType) {
      headers.remove('Content-Type');
    }
    return headers;
  }

  Uri _buildUri(String path, Map<String, String?> query) {
    final filtered = <String, String>{};
    query.forEach((key, value) {
      if (value != null && value.trim().isNotEmpty) {
        filtered[key] = value.trim();
      }
    });
    return Uri.parse('$_baseUrl/$path').replace(queryParameters: filtered);
  }

  Future<List<TEReportRowModel>> fetchReport({
    required String modelSerial,
    required String range,
    String model = '',
  }) async {
    final uri = _buildUri('TEReport', {
      'customer': modelSerial,
      'range': range,
      'model': model,
    });
    final stopwatch = Stopwatch()..start();
    final response = await http.get(uri, headers: _headers());
    stopwatch.stop();
    if (response.statusCode == 204 || response.body.isEmpty) {
      return const [];
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to load TE report (${response.statusCode})');
    }

    final dynamic decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected TE report payload');
    }

    return decoded
        .map<TEReportRowModel>((item) =>
            TEReportRowModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<String>> fetchModelNames({required String modelSerial}) async {
    final uri = _buildUri('ModelNames', {'customer': modelSerial});
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 204 || response.body.isEmpty) {
      return const [];
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load TE model names (${response.statusCode})',
      );
    }

    dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) {
      return const [];
    }

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

  Future<TEErrorDetailModel?> fetchErrorDetail({
    required String range,
    required String model,
    required String group,
  }) async {
    final uri = _buildUri('ErrorDetail', {
      'range': range,
      'model': model,
      'group': group,
    });
    // Log request path so tapping a cell reveals the outgoing API route in debug output.
    // ignore: avoid_print
    print('[TEManagement] GET $uri');
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 204 || response.body.isEmpty) {
      return null;
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load error detail (${response.statusCode})',
      );
    }

    final Map<String, dynamic> jsonMap =
        json.decode(response.body) as Map<String, dynamic>;
    return TEErrorDetailModel.fromJson(jsonMap);
  }

  Future<TEErrorDetailModel?> fetchRetestRateErrorDetail({
    required String date,
    required String shift,
    required String model,
    required String group,
  }) async {
    final uri = _buildUri('RetestRateErrorDetail', {
      'date': date,
      'shift': shift,
      'model': model,
      'group': group,
    });
    // ignore: avoid_print
    print('[TEManagement] GET $uri');
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 204 || response.body.isEmpty) {
      return null;
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load retest rate error detail (${response.statusCode})',
      );
    }

    final Map<String, dynamic> jsonMap =
        json.decode(response.body) as Map<String, dynamic>;
    return TEErrorDetailModel.fromJson(jsonMap);
  }

  Future<TERetestDetailModel> fetchRetestRateReport({
    required String modelSerial,
    required String range,
    String model = '',
  }) async {
    final uri = _buildUri('RetestRateReport', {
      'customer': modelSerial,
      'range': range,
      'model': model,
    });
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 204 || response.body.isEmpty) {
      return TERetestDetailModel(dates: const [], rows: const []);
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load TE retest rate report (${response.statusCode})',
      );
    }

    final dynamic decoded = json.decode(response.body);
    return TERetestDetailModel.fromJson(decoded);
  }
}
