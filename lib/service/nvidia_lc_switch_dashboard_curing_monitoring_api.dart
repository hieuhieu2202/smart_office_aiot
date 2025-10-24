import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth/auth_config.dart';

class CuringMonitoringApi {
  static const String _url =
      'https://10.220.130.117/newweb/api/nvidia/dashboard/CuringMonitor/GetCuringData';
  static const String _trayUrl =
      'https://10.220.130.117/newweb/api/nvidia/dashboard/CuringMonitor/GetCuringTrayData';

  /// Gọi API lấy dữ liệu Curing Monitoring (POST)
  static Future<Map<String, dynamic>> fetch({
    String customer = 'NVIDIA',
    String factory = 'F16',
    String floor = '3F',
    String room = 'ROOM1',
    String modelSerial = 'SWITCH',
    String tray = '',
  }) async {
    final bodyMap = {
      'customer': customer,
      'modelSerial': modelSerial,
      'factory': factory,
      'floor': floor,
      'room': room,
      'tray': tray,
    };

    // print('[CuringApi] POST body => ${json.encode(bodyMap)}');

    final headers = {
      ...AuthConfig.getAuthorizedHeaders(),
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
      'Content-Type': 'application/json',
    };

    // ignore: avoid_print
    // print('[CuringApi] headers => ${json.encode(headers)}');

    final res = await http.post(
      Uri.parse(_url),
      headers: headers,
      body: json.encode(bodyMap),
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final jsonMap = json.decode(res.body);
      if (jsonMap is Map<String, dynamic>) {
        return jsonMap;
      } else {
        throw Exception('Unexpected response format');
      }
    } else if (res.statusCode == 204) {
      // Không có dữ liệu (No Content)
      return {};
    } else {
      throw Exception(
        'Failed to load Curing Monitoring data (${res.statusCode})',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTrayData({
    String customer = 'NVIDIA',
    String factory = 'F16',
    String floor = '3F',
    String room = 'ROOM1',
    String modelSerial = 'SWITCH',
    required String tray,
  }) async {
    final bodyMap = {
      'customer': customer,
      'modelSerial': modelSerial,
      'factory': factory,
      'floor': floor,
      'room': room,
      'tray': tray,
    };

    final headers = {
      ...AuthConfig.getAuthorizedHeaders(),
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
      'Content-Type': 'application/json',
    };

    final res = await http.post(
      Uri.parse(_trayUrl),
      headers: headers,
      body: json.encode(bodyMap),
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final jsonBody = json.decode(res.body);
      if (jsonBody is List) {
        return jsonBody
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      throw Exception('Unexpected tray response format');
    } else if (res.statusCode == 204) {
      return const [];
    } else {
      throw Exception(
        'Failed to load tray data (${res.statusCode})',
      );
    }
  }
}
