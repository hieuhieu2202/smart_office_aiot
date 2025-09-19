// lib/service/cdu_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CduApi {
  CduApi._();

  /// Base URL không có dấu "/" cuối
  static const String _base = 'https://10.220.130.117/NVIDIA/CDU';

  static Map<String, String> _headers() => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  /// POST /GetCDUDataDashBoard
  /// body: { "Factory": "F16|F17", "Floor": "3F" }
  static Future<Map<String, dynamic>> fetchDashboard({
    required String factory,
    required String floor,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final uri = Uri.parse('$_base/GetCDUDataDashBoard');
    final body = jsonEncode({
      'Factory': factory,
      'Floor': floor,
    });

    final res = await http.post(uri, headers: _headers(), body: body).timeout(timeout);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('CDU fetchDashboard ${res.statusCode}: ${res.reasonPhrase}\n${res.body}');
  }

  /// POST /GetCDUDataDashBoardDetailHistory
  /// body: { "Factory": "F16|F17", "Floor": "3F" }
  static Future<Map<String, dynamic>> fetchDetailHistory({
    required String factory,
    required String floor,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final uri = Uri.parse('$_base/GetCDUDataDashBoardDetailHistory');
    final body = jsonEncode({
      'Factory': factory,
      'Floor': floor,
    });

    final res = await http.post(uri, headers: _headers(), body: body).timeout(timeout);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
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
