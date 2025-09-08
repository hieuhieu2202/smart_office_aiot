import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:smart_factory/service/auth/auth_config.dart';
import 'dart:convert';

class PTHDashboardApi {
  static final String _baseUrl =
      "https://10.220.23.244:4433/api/CCDMachine/AOIVI/";

  // Mock data fallback for offline development/testing
  static const List<String> _mockGroupNames = [
    // Default mock groups representing the four main dashboards
    "AOI",
    "ASSY_AVI",
    "AVI",
    "PTH_AVI",
  ];

  static const List<String> _mockMachineNames = ["M1", "M2", "M3"];
  static const List<String> _mockModelNames = ["ModelA", "ModelB"];

  static Future<List<String>> getGroupNames() async {
    final url = Uri.parse("${_baseUrl}GetGroupNames");
    try {
      final res = await http.get(url, headers: AuthConfig.getAuthorizedHeaders());
      print('[DEBUG] GET $url');
      print('[DEBUG] Status: ${res.statusCode}');
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return List<String>.from(json.decode(res.body));
      }
    } catch (e) {
      debugPrint('getGroupNames error: $e');
    }
    return _mockGroupNames; // Fallback
  }

  static Future<List<String>> getMachineNames(String groupName) async {
    final url = Uri.parse("${_baseUrl}GetMachineNames?groupName=$groupName");
    try {
      final res = await http.get(url, headers: AuthConfig.getAuthorizedHeaders());
      print('[DEBUG] GET $url');
      print('[DEBUG] Status: ${res.statusCode}');
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return List<String>.from(json.decode(res.body));
      }
    } catch (e) {
      debugPrint('getMachineNames error: $e');
    }
    return _mockMachineNames; // Fallback
  }

  static Future<List<String>> getModelNames(
    String groupName,
    String machineName,
  ) async {
    final url =
        Uri.parse("${_baseUrl}GetModelNames?groupName=$groupName&machineName=$machineName");
    try {
      final res = await http.get(url, headers: AuthConfig.getAuthorizedHeaders());
      print('[DEBUG] GET $url');
      print('[DEBUG] Status: ${res.statusCode}');
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return List<String>.from(json.decode(res.body));
      }
    } catch (e) {
      debugPrint('getModelNames error: $e');
    }
    return _mockModelNames; // Fallback
  }

  static Future<Map<String, dynamic>> getMonitoringData({
    required String groupName,
    required String machineName,
    required String modelName,
    required String rangeDateTime,
    required int opTime,
  }) async {
    final url = Uri.parse("${_baseUrl}GetMonitoringData");
    final body = json.encode({
      "groupName": groupName,
      "machineName": machineName,
      "modelName": modelName,
      "rangeDateTime": rangeDateTime,
      "opTime": opTime,
    });

    print('[DEBUG] POST $url');
    print('[DEBUG] Body send: $body');

    try {
      final res = await http.post(
        url,
        headers: AuthConfig.getAuthorizedHeaders(),
        body: body,
      );
      print('[DEBUG] Status: ${res.statusCode}');
      print(
        '[DEBUG] Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}',
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('getMonitoringData error: $e');
    }

    // Fallback mock data
    return {
      "summary": {
        "pass": 120,
        "fail": 5,
        "yr": 96.0,
        "fpr": 1.0,
        "rr": 0.5,
      },
      "output": [
        {"section": "S1", "pass": 60, "fail": 2, "yr": 96.8},
        {"section": "S2", "pass": 60, "fail": 3, "yr": 95.0},
      ],
      "runtime": {
        "type": "H",
        "runtimeMachine": [
          {
            "machine": machineName,
            "runtimeMachineData": [
              {
                "status": "Run",
                "result": [
                  {"time": "00", "value": 30},
                  {"time": "01", "value": 25},
                  {"time": "02", "value": 20}
                ]
              },
              {
                "status": "Idle",
                "result": [
                  {"time": "00", "value": 30},
                  {"time": "01", "value": 35},
                  {"time": "02", "value": 40}
                ]
              }
            ]
          }
        ]
      },
    };
  }

  static Future<List<Map<String, dynamic>>> getMonitoringDetailByStatus({
    required String status,
    required String groupName,
    required String machineName,
    required String modelName,
    required String rangeDateTime,
  }) async {
    var url = Uri.parse("${_baseUrl}GetMonitoringDataByStatus");
    var body = json.encode({
      "status": status,
      "groupName": groupName,
      "machineName": machineName,
      "modelName": modelName,
      "rangeDateTime": rangeDateTime,
    });

    print('[DEBUG] POST $url');
    print('[DEBUG] Body send: $body');

    var res = await http.post(
      url,
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
    );
    print('[DEBUG] Status: ${res.statusCode}');
    print(
      '[DEBUG] Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}',
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    } else if (res.statusCode == 204) {
      return [];
    } else {
      throw Exception(
        'Failed to load monitoring detail by status (${res.statusCode})',
      );
    }
  }

  static Future<Map<String, dynamic>?> getMonitoringDataById(int id) async {
    final url = Uri.parse("${_baseUrl}GetMonitoringDataById");
    final body = json.encode({"id": id});
    final res = await http.post(
      url,
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
    );
    print('[DEBUG] POST $url');
    print('[DEBUG] Body: ${res.body}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return json.decode(res.body);
    }
    return null;
  }

  static Future<ImageProvider?> fetchRawImage(String path) async {
    // Bỏ encode, thay \ thành / để đảm bảo URL hợp lệ
    final normalizedPath = path.replaceAll("\\", "/");

    // Gắn path trực tiếp vào cuối URL
    final url = Uri.parse(
      "https://10.220.23.244:4433/api/Image/raw/$normalizedPath",
    );

    try {
      print("[DEBUG] GET $url");
      final res = await http.get(
        url,
        headers: AuthConfig.getAuthorizedHeaders(),
      );

      print("[DEBUG] Status: ${res.statusCode}");
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return MemoryImage(res.bodyBytes);
      } else {
        print("[ERROR] GET ảnh lỗi: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR] fetchRawImage: $e");
    }
    return null;
  }
}
