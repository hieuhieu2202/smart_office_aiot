import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../service/http_helper.dart';
import '../../domain/entities/lcr_entities.dart';
import '../models/lcr_location_model.dart';
import '../models/lcr_record_model.dart';

class LcrRemoteDataSource {
  LcrRemoteDataSource({HttpHelper? httpHelper})
      : _http = httpHelper ?? HttpHelper();

  final HttpHelper _http;

  static const String _base = 'https://10.220.130.117/newweb/api/smt/LCR';
  static const Duration _timeout = Duration(seconds: 40);

  Map<String, String> _headers() {
    return const <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<List<LcrFactory>> fetchLocations() async {
    final uri = Uri.parse('$_base/GetLocations');
    final http.Response res = await _http
        .get(uri, headers: _headers(), timeout: _timeout)
        .catchError((error) => throw Exception('GetLocations: $error'));

    _ensureSuccess(res, 'GetLocations');

    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(LcrFactoryModel.fromJson)
          .toList();
    }

    throw Exception('GetLocations: unexpected payload');
  }

  Future<List<LcrRecord>> fetchTrackingData({required LcrRequest request}) async {
    final uri = Uri.parse('$_base/GetTrackingDatas');
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(request.toBody()),
          timeout: _timeout,
        )
        .catchError((error) => throw Exception('GetTrackingDatas: $error'));

    _ensureSuccess(res, 'GetTrackingDatas');

    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(LcrRecordModel.fromJson)
          .toList();
    }

    throw Exception('GetTrackingDatas: unexpected payload');
  }

  Future<List<LcrRecord>> fetchAnalysisData({
    required LcrRequest request,
  }) async {
    final uri = Uri.parse('$_base/GetAnalysisDatas');
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(request.toBody()),
          timeout: _timeout,
        )
        .catchError((error) => throw Exception('GetAnalysisDatas: $error'));

    _ensureSuccess(res, 'GetAnalysisDatas');

    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(LcrRecordModel.fromJson)
          .toList();
    }

    throw Exception('GetAnalysisDatas: unexpected payload');
  }

  Future<List<LcrRecord>> searchSerialNumbers({
    required String query,
    int take = 12,
  }) async {
    if (query.trim().isEmpty) {
      return const <LcrRecord>[];
    }
    final uri = Uri.parse('$_base/SearchSerialNumber')
        .replace(queryParameters: <String, String>{
      'searchInput': query,
      'take': take.toString(),
    });

    final http.Response res = await _http
        .get(uri, headers: _headers(), timeout: _timeout)
        .catchError((error) => throw Exception('SearchSerialNumber: $error'));

    if (res.statusCode == 204) {
      return const <LcrRecord>[];
    }

    _ensureSuccess(res, 'SearchSerialNumber');

    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(LcrRecordModel.fromJson)
          .toList();
    }

    throw Exception('SearchSerialNumber: unexpected payload');
  }

  Future<LcrRecord?> fetchRecord({required int id}) async {
    final uri = Uri.parse('$_base/GetRecord')
        .replace(queryParameters: <String, String>{'Id': '$id'});

    final http.Response res = await _http
        .get(uri, headers: _headers(), timeout: _timeout)
        .catchError((error) => throw Exception('GetRecord: $error'));

    if (res.statusCode == 204) {
      return null;
    }

    _ensureSuccess(res, 'GetRecord');

    if (res.body.isEmpty) {
      return null;
    }

    final dynamic body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return LcrRecordModel.fromJson(body);
    }

    throw Exception('GetRecord: unexpected payload');
  }

  void _ensureSuccess(http.Response res, String endpoint) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$endpoint failed (${res.statusCode}): ${res.body}');
    }
  }
}
