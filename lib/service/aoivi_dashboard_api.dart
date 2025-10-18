import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:smart_factory/service/auth/auth_config.dart';
import 'dart:convert';

class PTHDashboardApi {
  static final String _baseUrl =
      "https://10.220.130.117/newweb/api/Automation/CCDMachine/";

  static Future<List<String>> getGroupNames() async {
    var url = Uri.parse("${_baseUrl}GetGroupNames");
    var res = await http.get(url, headers: AuthConfig.getAuthorizedHeaders());
    print('[DEBUG] GET $url');
    print('[DEBUG] Status: ${res.statusCode}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<String>.from(json.decode(res.body));
    } else if (res.statusCode == 204) {
      return <String>[]; // Trả về list rỗng
    } else {
      throw Exception('Failed to load group names (${res.statusCode})');
    }
  }

  static Future<List<String>> getMachineNames(String groupName) async {
    var url = Uri.parse("${_baseUrl}GetMachineNames?groupName=$groupName");
    var res = await http.get(url, headers: AuthConfig.getAuthorizedHeaders());
    print('[DEBUG] GET $url');
    print('[DEBUG] Status: ${res.statusCode}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<String>.from(json.decode(res.body));
    } else if (res.statusCode == 204) {
      return <String>[];
    } else {
      throw Exception('Failed to load machine names (${res.statusCode})');
    }
  }

  static Future<List<String>> getModelNames(
    String groupName,
    String machineName,
  ) async {
    var url = Uri.parse("${_baseUrl}GetModelNames?groupName=$groupName");
    var res = await http.get(url, headers: AuthConfig.getAuthorizedHeaders());
    print('[DEBUG] GET $url');
    print('[DEBUG] Status: ${res.statusCode}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<String>.from(json.decode(res.body));
    } else if (res.statusCode == 204) {
      return <String>[];
    } else {
      throw Exception('Failed to load model names (${res.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> getMonitoringData({
    required String groupName,
    required String machineName,
    required String modelName,
    required String rangeDateTime,
    required int opTime,
  }) async {
    var url = Uri.parse("${_baseUrl}GetMonitoringData");
    var body = json.encode({
      "groupName": groupName,
      "machineName": machineName,
      "modelName": modelName,
      "rangeDateTime": rangeDateTime,
      "opTime": opTime,
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
      return json.decode(res.body) as Map<String, dynamic>;
    } else if (res.statusCode == 204) {
      return {};
    } else {
      throw Exception('Failed to load monitoring data (${res.statusCode})');
    }
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
      "https://10.220.130.117/newweb/api/Image/raw/$normalizedPath",
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
