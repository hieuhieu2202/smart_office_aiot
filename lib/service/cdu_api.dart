// lib/service/cdu_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/cdu_layout.dart';

class CduApi {
  CduApi._();

  /// Base URL không có dấu "/" cuối
  static const String _base = 'https://10.220.130.117/api/nvidia/dashboard/CduMonitor';

  static Map<String, String> _headers() => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  /// GET /GetLatestLayout
  /// Returns the latest CDU layout with factory, floor, image, and device data
  static Future<CduLayout> getLatestLayout({
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final uri = Uri.parse('$_base/GetLatestLayout');

    final res = await http.get(uri, headers: _headers()).timeout(timeout);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return CduLayout.fromJson(json);
    }
    throw Exception('CDU getLatestLayout ${res.statusCode}: ${res.reasonPhrase}\n${res.body}');
  }
}
