import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'auth/auth_config.dart';

class PcbaLineApi {
  static const _passFailUrl =
      'https://10.220.130.117/PCBASystem/Post_DashBoard_CleanSensor_PassQty';
  static const _yieldUrl =
      'https://10.220.130.117/PCBASystem/Post_DashBoard_CleanSensor_YieldRate';
  static const _avgCycleUrl =
      'https://10.220.130.117/PCBASystem/Post_DashBoard_CleanSensor_AVG_CycleTime';

  static Future<http.Response> _post(String url, Map<String, dynamic> body) {
    return http
        .post(
      Uri.parse(url),
      headers: AuthConfig.getAuthorizedHeaders(),
      body: json.encode(body),
    )
        .timeout(const Duration(seconds: 20));
  }

  ///Fetch Pass/Fail series (cho biểu đồ cột)
  static Future<List<List<Map<String, dynamic>>>> fetchPassFailSeries({
    required String rangeDateTime,
    String machineName = '',
    String groupName = 'RR',
  }) async {
    final body = {
      'GroupName': groupName,
      'RangeDateTime': rangeDateTime,
      'MachineName': machineName,
    };

    final res = await _post(_passFailUrl, body);

    print('=== [PassFail] Status: ${res.statusCode}');
    print('=== [PassFail] Body: ${res.body}');

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      try {
        final raw = json.decode(res.body) as List;
        return raw
            .map<List<Map<String, dynamic>>>(
              (e) => List<Map<String, dynamic>>.from(e as List),
        )
            .toList();
      } catch (e) {
        throw Exception('❌ JSON parse lỗi: $e\nBody: ${res.body}');
      }
    }

    if (res.statusCode == 204) return [];
    throw Exception('Failed to load Pass/Fail series (${res.statusCode})');
  }

  ///Fetch YieldRate (cho biểu đồ đường)
  static Future<List<Map<String, dynamic>>> fetchYieldRate({
    required String rangeDateTime,
    String machineName = '',
    String groupName = 'RR',
  }) async {
    final body = {
      'GroupName': groupName,
      'RangeDateTime': rangeDateTime,
      'MachineName': machineName,
    };

    final res = await _post(_yieldUrl, body);

    print('=== [YieldRate] Status: ${res.statusCode}');
    print('=== [YieldRate] Body: ${res.body}');

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      try {
        final raw = json.decode(res.body) as List;
        return List<Map<String, dynamic>>.from(raw);
      } catch (e) {
        throw Exception('❌ JSON parse lỗi (Yield): $e\nBody: ${res.body}');
      }
    }

    if (res.statusCode == 204) return [];
    throw Exception('Failed to load YieldRate (${res.statusCode})');
  }

  /// Fetch AvgCycleTime (KPI)
  static Future<double?> fetchAvgCycleTime({
    required String rangeDateTime,
    String machineName = '',
    String groupName = 'RR',
  }) async {
    final body = {
      'GroupName': groupName,
      'RangeDateTime': rangeDateTime,
      'MachineName': machineName,
    };

    final res = await _post(_avgCycleUrl, body);

    print('=== [AvgCycleTime] Status: ${res.statusCode}');
    print('=== [AvgCycleTime] Body: ${res.body}');

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final raw = res.body.trim();
      final cleaned = raw.replaceAll(',', '');
      return double.tryParse(cleaned);
    }

    if (res.statusCode == 204) return null;
    throw Exception('Failed to load AvgCycleTime (${res.statusCode})');
  }
}
