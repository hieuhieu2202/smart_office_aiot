// lib/service/cdu_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CduApi {
  CduApi._();

  /// Base URL không có dấu "/" cuối
  static const String _base = 'https://10.220.130.117/api/nvidia/dashboard/CduMonitor';

  static Map<String, String> _headers() => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  /// GET /GetLastestLayout
  /// Returns layout configuration with CDU positions
  static Future<Map<String, dynamic>> fetchDashboard({
    required String factory,
    required String floor,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final uri = Uri.parse('$_base/GetLastestLayout');

    final res = await http.get(uri, headers: _headers()).timeout(timeout);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('CDU fetchDashboard ${res.statusCode}: ${res.reasonPhrase}\n${res.body}');
  }

  /// GET /GetHistoryWarningDatas
  /// Returns array of warning history items directly
  static Future<List<dynamic>> fetchDetailHistory({
    required String factory,
    required String floor,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final uri = Uri.parse('$_base/GetHistoryWarningDatas');

    final res = await http.get(uri, headers: _headers()).timeout(timeout);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }
    throw Exception('CDU fetchDetailHistory ${res.statusCode}: ${res.reasonPhrase}\n${res.body}');
  }

  /// Link Web dashboard (để mở WebView/Browser khi cần đối chiếu)
  static String webDashboardUrl({
    required String factory,
    required String floor,
  }) =>
      '$_base/DashBoard?Factory=$factory&Floor=$floor';
}
