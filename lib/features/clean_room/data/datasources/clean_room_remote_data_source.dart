import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../service/auth/auth_config.dart';
import '../../../../service/http_helper.dart';
import '../../domain/entities/clean_room_config.dart';
import '../models/clean_room_config_model.dart';
import '../models/sensor_models.dart';

class CleanRoomRemoteDataSource {
  CleanRoomRemoteDataSource({HttpHelper? httpHelper})
      : _http = httpHelper ?? HttpHelper();

  final HttpHelper _http;
  final bool _logVerbose = true;

  static const String _baseUrl =
      'https://10.220.130.117/api/nvidia/cleanroom';
  static const Duration _timeout = Duration(seconds: 30);

  Map<String, String> _headers({bool includeContentType = false}) {
    final headers = Map<String, String>.from(AuthConfig.getAuthorizedHeaders());
    headers['Accept'] = 'application/json';
    if (!includeContentType) {
      headers.remove('Content-Type');
    }
    return headers;
  }

  Future<List<String>> fetchCustomers() async {
    final uri = Uri.parse('$_baseUrl/location/GetCustomers');
    final res = await _http.get(uri, headers: _headers()).timeout(_timeout);
    _logApi(
      endpoint: 'GetCustomers',
      uri: uri,
      method: 'GET',
      response: res,
    );
    if (res.statusCode == 204) return const <String>[];
    _ensureSuccess(res, 'GetCustomers');
    return _decodeStringList(res.body);
  }

  Future<List<String>> fetchFactories({required String customer}) async {
    final uri = Uri.parse('$_baseUrl/location/GetFactories');
    final res = await _http.get(uri, headers: _headers()).timeout(_timeout);
    _logApi(
      endpoint: 'GetFactories',
      uri: uri,
      method: 'GET',
      response: res,
    );
    if (res.statusCode == 204) return const <String>[];
    _ensureSuccess(res, 'GetFactories');
    return _decodeStringList(res.body);
  }

  Future<List<String>> fetchFloors({
    required String customer,
    required String factory,
  }) async {
    final uri = Uri.parse('$_baseUrl/location/GetFloors')
        .replace(queryParameters: <String, String>{'factory': factory});
    final res = await _http.get(uri, headers: _headers()).timeout(_timeout);
    _logApi(
      endpoint: 'GetFloors',
      uri: uri,
      method: 'GET',
      response: res,
    );
    if (res.statusCode == 204) return const <String>[];
    _ensureSuccess(res, 'GetFloors');
    return _decodeStringList(res.body);
  }

  Future<List<String>> fetchRooms({
    required String customer,
    required String factory,
    required String floor,
  }) async {
    final uri = Uri.parse('$_baseUrl/location/GetRooms').replace(
      queryParameters: <String, String>{
        'factory': factory,
        'floor': floor,
      },
    );
    final res = await _http.get(uri, headers: _headers()).timeout(_timeout);
    _logApi(
      endpoint: 'GetRooms',
      uri: uri,
      method: 'GET',
      response: res,
    );
    if (res.statusCode == 204) return const <String>[];
    _ensureSuccess(res, 'GetRooms');
    return _decodeStringList(res.body);
  }

  Future<CleanRoomConfig?> fetchConfig({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) async {
    final uri = Uri.parse('$_baseUrl/location/GetConfigMapping');
    final payload = <String, String>{
      'customer': customer,
      'factory': factory,
      'floor': floor,
      'room': room,
    };
    final res = await _http
        .post(
          uri,
          headers: _headers(includeContentType: true),
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    _logApi(
      endpoint: 'GetConfigMapping',
      uri: uri,
      method: 'POST',
      payload: payload,
      response: res,
    );

    if (res.statusCode == 204) return null;
    _ensureSuccess(res, 'GetConfigMapping');
    final dynamic body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return CleanRoomConfigModel.fromJson(body);
    }
    return null;
  }

  Future<SensorOverviewModel?> fetchSensorOverview({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) async {
    final uri = Uri.parse('$_baseUrl/sensordata/GetSensorOverview');
    final payload = <String, String>{
      'customer': customer,
      'factory': factory,
      'floor': floor,
      'room': room,
    };
    final res = await _http
        .post(
          uri,
          headers: _headers(includeContentType: true),
          body: jsonEncode(payload),
        )
        .timeout(_timeout);
    _logApi(
      endpoint: 'GetSensorOverview',
      uri: uri,
      method: 'POST',
      payload: payload,
      response: res,
    );
    if (res.statusCode == 204) return null;
    _ensureSuccess(res, 'GetSensorOverview');
    final dynamic body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return SensorOverviewModel.fromJson(body);
    }
    return null;
  }

  Future<List<SensorDataResponseModel>> fetchSensorDataOverview({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) async {
    final uri = Uri.parse('$_baseUrl/sensordata/GetSensorDataOverview');
    final payload = <String, String>{
      'customer': customer,
      'factory': factory,
      'floor': floor,
      'room': room,
    };
    final res = await _http
        .post(
          uri,
          headers: _headers(includeContentType: true),
          body: jsonEncode(payload),
        )
        .timeout(_timeout);
    _logApi(
      endpoint: 'GetSensorDataOverview',
      uri: uri,
      method: 'POST',
      payload: payload,
      response: res,
    );
    if (res.statusCode == 204) return const <SensorDataResponseModel>[];
    _ensureSuccess(res, 'GetSensorDataOverview');
    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(SensorDataResponseModel.fromJson)
          .toList();
    }
    return const <SensorDataResponseModel>[];
  }

  Future<List<SensorDataResponseModel>> fetchSensorDataHistories({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) async {
    final uri = Uri.parse('$_baseUrl/sensordata/GetSensorDataHistories');
    final payload = <String, String>{
      'customer': customer,
      'factory': factory,
      'floor': floor,
      'room': room,
    };
    final res = await _http
        .post(
          uri,
          headers: _headers(includeContentType: true),
          body: jsonEncode(payload),
        )
        .timeout(_timeout);
    _logApi(
      endpoint: 'GetSensorDataHistories',
      uri: uri,
      method: 'POST',
      payload: payload,
      response: res,
    );
    if (res.statusCode == 204) return const <SensorDataResponseModel>[];
    _ensureSuccess(res, 'GetSensorDataHistories');
    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(SensorDataResponseModel.fromJson)
          .toList();
    }
    return const <SensorDataResponseModel>[];
  }

  List<String> _decodeStringList(String body) {
    final dynamic data = jsonDecode(body);
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return const <String>[];
  }

  void _logApi({
    required String endpoint,
    required Uri uri,
    required String method,
    http.Response? response,
    Map<String, String>? payload,
  }) {
    if (!_logVerbose) return;
    final buffer = StringBuffer();
    buffer.writeln('[CleanRoomAPI][$endpoint] $method $uri');
    if (payload != null && payload.isNotEmpty) {
      buffer.writeln('  Payload: ${jsonEncode(payload)}');
    }
    if (response != null) {
      buffer.writeln(
          '  Response: status=${response.statusCode}, length=${response.body.length}');
      final encodedBody = base64Encode(utf8.encode(response.body));
      buffer.writeln('  Body (raw): ${response.body}');
      buffer.writeln('  Body (base64): $encodedBody');
    }
    // ignore: avoid_print
    print(buffer.toString());
  }

  void _ensureSuccess(http.Response res, String endpoint) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$endpoint failed (${res.statusCode}): ${res.body}');
    }
  }
}
