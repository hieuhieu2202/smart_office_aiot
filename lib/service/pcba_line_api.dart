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


  // Hàm POST chung
  static Future<http.Response> _post(String url, Map<String, dynamic> body) {
    return http
        .post(
      Uri.parse(url),
      headers: AuthConfig.getAuthorizedHeaders(),
      body: json.encode(body),
    )
        .timeout(const Duration(seconds: 20));
  }


  //Pass/Fail series (cho Bar chart)
  static Future<List<List<Map<String, dynamic>>>> fetchPassFailSeries({
    required String rangeDateTime,
    String machineName = '',
  }) async {
    final body = {
      'RangeDateTime': rangeDateTime,
      'MachineName': machineName,
    };

    final res = await _post(_passFailUrl, body);

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final raw = json.decode(res.body) as List;
      //Mỗi phần tử trong raw = 1 ngày, bên trong lại có 2 record (total + machine)
      return raw
          .map<List<Map<String, dynamic>>>(
              (e) => List<Map<String, dynamic>>.from(e as List))
          .toList();
    }

    if (res.statusCode == 204) return [];
    throw Exception('Failed to load Pass/Fail series (${res.statusCode})');
  }

  //Yield Rate series (cho Line chart)
  static Future<List<Map<String, dynamic>>> fetchYieldRate({
    required String rangeDateTime,
    String machineName = '',
  }) async {
    final body = {
      'RangeDateTime': rangeDateTime,
      'MachineName': machineName,
    };

    final res = await _post(_yieldUrl, body);

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final raw = json.decode(res.body) as List;
      // Mỗi phần tử = { "Date": "...", "Yield": "71.31" }
      return List<Map<String, dynamic>>.from(raw);
    }

    if (res.statusCode == 204) return [];
    throw Exception('Failed to load YieldRate (${res.statusCode})');
  }


  //Average Cycle Time (KPI header)
  static Future<double?> fetchAvgCycleTime({
    required String rangeDateTime,
    String machineName = '',
  }) async {
    final body = {
      'RangeDateTime': rangeDateTime,
      'MachineName': machineName,
    };

    final res = await _post(_avgCycleUrl, body);

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final raw = json.decode(res.body);
      // Server có thể trả số hoặc string
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw);
    }

    if (res.statusCode == 204) return null;
    throw Exception('Failed to load AvgCycleTime (${res.statusCode})');
  }
}
