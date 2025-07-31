import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_factory/service/auth/auth_config.dart';

class CleanRoomApi {
  static final String _baseUrl = "https://10.220.23.244:4433/api/cleanroom/";

  static Future<List<String>> getCustomers() async {
    var url = Uri.parse("${_baseUrl}Location/GetCustomers");
    var res = await http.get(url, headers: AuthConfig.getAuthorizedHeaders());
    print('[DEBUG] GET $url');
    print('[DEBUG] Status: ${res.statusCode}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<String>.from(json.decode(res.body));
    } else if (res.statusCode == 204) {
      return <String>[];
    } else {
      throw Exception('Failed to load customers (${res.statusCode})');
    }
  }

  static Future<List<String>> getFactories(String customer) async {
    var url = Uri.parse("${_baseUrl}Location/GetFactories?customer=$customer");
    var res = await http.get(url, headers: AuthConfig.getAuthorizedHeaders());
    print('[DEBUG] GET $url');
    print('[DEBUG] Status: ${res.statusCode}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<String>.from(json.decode(res.body));
    } else if (res.statusCode == 204) {
      return <String>[];
    } else {
      throw Exception('Failed to load factories (${res.statusCode})');
    }
  }

  static Future<List<String>> getFloors(String customer, String factory) async {
    var url = Uri.parse("${_baseUrl}Location/GetFloors?customer=$customer&factory=$factory");
    var res = await http.get(url, headers: AuthConfig.getAuthorizedHeaders());
    print('[DEBUG] GET $url');
    print('[DEBUG] Status: ${res.statusCode}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<String>.from(json.decode(res.body));
    } else if (res.statusCode == 204) {
      return <String>[];
    } else {
      throw Exception('Failed to load floors (${res.statusCode})');
    }
  }

  static Future<List<String>> getRooms(String customer, String factory, String floor) async {
    var url = Uri.parse("${_baseUrl}Location/GetRooms?customer=$customer&factory=$factory&floor=$floor");
    var res = await http.get(url, headers: AuthConfig.getAuthorizedHeaders());
    print('[DEBUG] GET $url');
    print('[DEBUG] Status: ${res.statusCode}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<String>.from(json.decode(res.body));
    } else if (res.statusCode == 204) {
      return <String>[];
    } else {
      throw Exception('Failed to load rooms (${res.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> getConfigMapping({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) async {
    var url = Uri.parse("${_baseUrl}Location/GetConfigMapping");
    var body = json.encode({
      "customer": customer,
      "factory": factory,
      "floor": floor,
      "room": room,
    });
    print('[DEBUG] POST $url');
    print('[DEBUG] Body send: $body');
    var res = await http.post(
      url,
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
    );
    print('[DEBUG] Status: ${res.statusCode}');
    print('[DEBUG] Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      var response = json.decode(res.body) as Map<String, dynamic>;
      if (response.containsKey('data') && response['data'] is String) {
        response['data'] = json.decode(response['data']) as List<dynamic>;
      }
      return response;
    } else if (res.statusCode == 204) {
      return {};
    } else {
      throw Exception('Failed to load config mapping (${res.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> getSensorOverview({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) async {
    var url = Uri.parse("${_baseUrl}SensorData/GetSensorOverview");
    var body = json.encode({
      "customer": customer,
      "factory": factory,
      "floor": floor,
      "room": room,
    });
    print('[DEBUG] POST $url');
    print('[DEBUG] Body send: $body');
    var res = await http.post(
      url,
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
    );
    print('[DEBUG] Status: ${res.statusCode}');
    print('[DEBUG] Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else if (res.statusCode == 204) {
      return {};
    } else {
      throw Exception('Failed to load sensor overview (${res.statusCode})');
    }
  }

  static Future<List<Map<String, dynamic>>> getSensorDataOverview({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) async {
    var url = Uri.parse("${_baseUrl}SensorData/GetSensorDataOverview");
    var body = json.encode({
      "customer": customer,
      "factory": factory,
      "floor": floor,
      "room": room,
    });
    print('[DEBUG] POST $url');
    print('[DEBUG] Body send: $body');
    var res = await http.post(
      url,
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
    );
    print('[DEBUG] Status: ${res.statusCode}');
    print('[DEBUG] Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    } else if (res.statusCode == 204) {
      return [];
    } else {
      throw Exception('Failed to load sensor data overview (${res.statusCode})');
    }
  }

  static Future<List<Map<String, dynamic>>> getSensorDataHistories({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) async {
    var url = Uri.parse("${_baseUrl}SensorData/GetSensorDataHistories");
    var body = json.encode({
      "customer": customer,
      "factory": factory,
      "floor": floor,
      "room": room,
    });
    print('[DEBUG] POST $url');
    print('[DEBUG] Body send: $body');
    var res = await http.post(
      url,
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
    );
    print('[DEBUG] Status: ${res.statusCode}');
    // print('[DEBUG] Body: ${res.body.substring(0, (res.body.length > 200) as int? : res.body.length)}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    } else if (res.statusCode == 204) {
      return [];
    } else {
      throw Exception('Failed to load sensor data histories (${res.statusCode})');
    }
  }

  static Future<List<Map<String, dynamic>>> getSensorData({
    required String customer,
    required String factory,
    required String floor,
    required String room,
    required String rangeDateTime,
  }) async {
    var url = Uri.parse("${_baseUrl}SensorData/GetSensorData");
    var body = json.encode({
      "customer": customer,
      "factory": factory,
      "floor": floor,
      "room": room,
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
    print('[DEBUG] Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    } else if (res.statusCode == 204) {
      return [];
    } else {
      throw Exception('Failed to load sensor data (${res.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> getAreaData({
    required String customer,
    required String factory,
    required String floor,
    required String room,
    required String rangeDateTime,
  }) async {
    var url = Uri.parse("${_baseUrl}SensorData/GetAreaData");
    var body = json.encode({
      "customer": customer,
      "factory": factory,
      "floor": floor,
      "room": room,
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
    print('[DEBUG] Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else if (res.statusCode == 204) {
      return {};
    } else {
      throw Exception('Failed to load area data (${res.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> getBarData({
    required String customer,
    required String factory,
    required String floor,
    required String room,
    required String rangeDateTime,
  }) async {
    var url = Uri.parse("${_baseUrl}SensorData/GetBarData");
    var body = json.encode({
      "customer": customer,
      "factory": factory,
      "floor": floor,
      "room": room,
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
    print('[DEBUG] Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else if (res.statusCode == 204) {
      return {};
    } else {
      throw Exception('Failed to load bar data (${res.statusCode})');
    }
  }

  static Future<ImageProvider?> fetchRoomImage({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) async {
    var url = Uri.parse("${_baseUrl}Location/GetConfigMapping");
    var body = json.encode({
      "customer": customer,
      "factory": factory,
      "floor": floor,
      "room": room,
    });
    print('[DEBUG] POST $url');
    print('[DEBUG] Body send: $body');
    var res = await http.post(
      url,
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
    );
    print('[DEBUG] Status: ${res.statusCode}');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      var data = json.decode(res.body);
      String? imageBase64 = data['image'];
      if (imageBase64 != null && imageBase64.startsWith('data:image/png;base64,')) {
        String base64String = imageBase64.split(',')[1];
        return MemoryImage(base64Decode(base64String));
      }
    }
    print('[ERROR] Failed to load room image: ${res.statusCode}');
    return null;
  }
}