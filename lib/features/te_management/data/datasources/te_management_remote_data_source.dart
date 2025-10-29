import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../service/auth/auth_config.dart';
import '../../domain/entities/te_report.dart';
import '../models/te_report_models.dart';
import '../models/te_retest_rate_models.dart';
import '../models/te_top_error_models.dart';

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

  Future<http.Response> _performGet(
    Uri uri, {
    bool includeContentType = false,
  }) async {
    final headers = _headers(includeContentType: includeContentType);
    try {
      return await http.get(uri, headers: headers);
    } on SocketException catch (error) {
      throw SocketException(
        error.message,
        osError: error.osError,
        address: error.address,
        port: error.port,
      );
    } on http.ClientException catch (error) {
      final message = error.message;
      if (message.contains('SocketException')) {
        final start = message.indexOf('SocketException');
        final detail = start >= 0 ? message.substring(start) : message;
        throw SocketException(detail);
      }
      rethrow;
    }
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
    final response = await _performGet(uri);
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
    final response = await _performGet(uri);
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
    final response = await _performGet(uri);
    if (response.statusCode == 204 || response.body.isEmpty) {
      return null;
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load error detail (${response.statusCode})',
      );
    }

    final dynamic decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      return TEErrorDetailModel.fromJson(decoded);
    }
    if (decoded is List) {
      final clusters = decoded
          .map((item) => TEErrorDetailClusterModel.fromDynamic(item))
          .whereType<TEErrorDetailClusterModel>()
          .toList();
      return TEErrorDetailModel(
        byErrorCode: clusters,
        byMachine: const <TEErrorDetailClusterEntity>[],
      );
    }
    throw Exception('Unexpected error detail payload');
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
    final response = await _performGet(uri);
    if (response.statusCode == 204 || response.body.isEmpty) {
      return null;
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load retest rate error detail (${response.statusCode})',
      );
    }

    final dynamic decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      return TEErrorDetailModel.fromJson(decoded);
    }
    if (decoded is List) {
      final clusters = decoded
          .map((item) => TEErrorDetailClusterModel.fromDynamic(item))
          .whereType<TEErrorDetailClusterModel>()
          .toList();
      return TEErrorDetailModel(
        byErrorCode: clusters,
        byMachine: const <TEErrorDetailClusterEntity>[],
      );
    }
    throw Exception('Unexpected retest rate error detail payload');
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
    final response = await _performGet(uri);
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

  Future<List<TETopErrorModel>> fetchTopErrorCodes({
    required String modelSerial,
    required String range,
    String type = 'System',
  }) async {
    final uri = _buildUri('Top10ErrorCode', {
      'customer': modelSerial,
      'range': range,
      'type': type,
    });
    final response = await _performGet(uri);
    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      return const [];
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load TE top error codes (${response.statusCode})',
      );
    }

    final List<dynamic> decoded = _decodeJsonList(response.body);
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((item) => TETopErrorModel.fromJson(item))
        .toList();
  }

  Future<List<TETopErrorTrendPointModel>> fetchTopErrorTrendByErrorCode({
    required String modelSerial,
    required String range,
    required String errorCode,
    String type = 'System',
  }) async {
    final uri = _buildUri('Top10ErrorCodeByWeek_byErrorCode', {
      'customer': modelSerial,
      'range': range,
      'error': errorCode,
      'type': type,
    });
    final response = await _performGet(uri);
    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      return const [];
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load top error trend (${response.statusCode})',
      );
    }

    final List<dynamic> decoded = _decodeJsonList(response.body);
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((item) => TETopErrorTrendPointModel.fromJson(item))
        .toList();
  }

  Future<List<TETopErrorTrendPointModel>>
      fetchTopErrorTrendByModelStation({
    required String range,
    required String errorCode,
    required String model,
    required String station,
  }) async {
    final uri = _buildUri('Top10ErrorCodeByWeek_byModelStation', {
      'range': range,
      'error': errorCode,
      'model': model,
      'station': station,
    });
    final response = await _performGet(uri);
    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      return const [];
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load top error detail trend (${response.statusCode})',
      );
    }

    final List<dynamic> decoded = _decodeJsonList(response.body);
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((item) => TETopErrorTrendPointModel.fromJson(item))
        .toList();
  }

  List<dynamic> _decodeJsonList(String body) {
    dynamic decoded;
    try {
      decoded = json.decode(body);
    } catch (_) {
      final trimmed = body.trim();
      if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
        try {
          decoded = json.decode(json.decode(body) as String);
        } catch (_) {
          return const [];
        }
      } else {
        return const [];
      }
    }
    if (decoded is String) {
      try {
        decoded = json.decode(decoded) as dynamic;
      } catch (_) {
        return const [];
      }
    }
    if (decoded is List) {
      return decoded;
    }
    return const [];
  }
}
