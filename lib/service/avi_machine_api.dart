import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth/auth_config.dart';

class PthAviApi {
  static const _baseUrl = 'https://10.220.130.117/CCDMachine/AOIVI';

  // Hàm POST dùng chung
  static Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    final encodedBody = json.encode(body);

    print('[DEBUG] POST $url');
    print('[DEBUG] Body send: $encodedBody');

    final res = await http
        .post(
      url,
      headers: AuthConfig.getAuthorizedHeaders(),
      body: encodedBody,
    )
        .timeout(const Duration(seconds: 20));

    print('[DEBUG] Status: ${res.statusCode}');
    print('[DEBUG] Response body: ${res.body.length > 300 ? res.body.substring(0, 300) + "..." : res.body}');

    return res;
  }

  /// Lấy danh sách tên máy (dùng cho dropdown MachineName)
  static Future<List<String>> fetchMachineNames({required String machineType}) async {
    final body = {'MachineType': machineType};
    final res = await _post('GetMachineNames', body);

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final raw = json.decode(res.body);
      if (raw is List) {
        return raw.map<String>((e) => e.toString()).toList();
      }
    } else if (res.statusCode == 204) {
      print('[DEBUG] No machine names found (204)');
      return [];
    }

    throw Exception('Failed to load machine names (${res.statusCode})');
  }

  /// Lấy danh sách model theo máy (dùng cho dropdown ModelName)
  static Future<List<String>> fetchModelNames({required String machineName}) async {
    final body = {'MachineName': machineName};
    final res = await _post('GetModelNames', body);

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final raw = json.decode(res.body);
      if (raw is List) {
        return raw.map<String>((e) => e.toString()).toList();
      }
    } else if (res.statusCode == 204) {
      print('[DEBUG] No model names found (204)');
      return [];
    }

    throw Exception('Failed to load model names (${res.statusCode})');
  }

  /// Lấy dữ liệu chính để hiển thị dashboard (pass/fail, charts, v.v.)
  static Future<Map<String, dynamic>> fetchMonitoringData({
    required String machineType,
    required String machineName,
    required String modelName,
    required String rangeDateTime,
    required int opTime,
  }) async {
    final body = {
      'MachineType': machineType,
      'MachineName': machineName,
      'ModelName': modelName,
      'RangeDateTime': rangeDateTime,
      'OpTime': opTime,
    };

    final res = await _post('GetMonitoringData', body);

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final raw = json.decode(res.body);
      if (raw is Map<String, dynamic>) {
        return raw;
      }
    } else if (res.statusCode == 204) {
      print('[DEBUG] No monitoring data found (204)');
      return {};
    }

    throw Exception('Failed to load monitoring data (${res.statusCode})');
  }
}
