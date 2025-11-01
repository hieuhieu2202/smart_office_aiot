import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../service/http_helper.dart';
import '../../domain/entities/resistor_machine_entities.dart';
import '../models/resistor_machine_record_model.dart';
import '../models/resistor_machine_serial_match_model.dart';
import '../models/resistor_machine_status_model.dart';
import '../models/resistor_machine_test_result_model.dart';
import '../models/resistor_machine_tracking_model.dart';

class ResistorMachineRemoteDataSource {
  ResistorMachineRemoteDataSource({HttpHelper? httpHelper})
      : _http = httpHelper ?? HttpHelper();

  final HttpHelper _http;

  static const String _base =
      'https://10.220.130.117/newweb/api/Automation/ResistorMachine';
  static const Duration _timeout = Duration(seconds: 40);

  Map<String, String> _headers() {
    return const <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<List<String>> fetchMachineNames() async {
    final uri = Uri.parse('$_base/GetResistorMachineNames');
    final http.Response res = await _http
        .get(uri, headers: _headers(), timeout: _timeout)
        .catchError((error) =>
            throw Exception('GetResistorMachineNames failed: $error'));

    _ensureSuccess(res, 'GetResistorMachineNames');

    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body.whereType<String>().toList();
    }
    throw Exception('GetResistorMachineNames: unexpected payload');
  }

  Future<ResistorMachineTrackingData> fetchTrackingData(
    ResistorMachineRequest request,
  ) async {
    final uri = Uri.parse('$_base/GetResistorMachineTrackingData');
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(request.toBody()),
          timeout: _timeout,
        )
        .catchError((error) => throw Exception(
            'GetResistorMachineTrackingData failed: $error'));

    _ensureSuccess(res, 'GetResistorMachineTrackingData');

    final dynamic body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return ResistorMachineTrackingDataModel.fromJson(body);
    }
    throw Exception('GetResistorMachineTrackingData: unexpected payload');
  }

  Future<List<ResistorMachineStatus>> fetchStatusData(
    ResistorMachineRequest request,
  ) async {
    final uri = Uri.parse('$_base/GetResistorMachineStatusData');
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(request.toBody()),
          timeout: _timeout,
        )
        .catchError(
            (error) => throw Exception('GetResistorMachineStatusData: $error'));

    _ensureSuccess(res, 'GetResistorMachineStatusData');

    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(ResistorMachineStatusModel.fromJson)
          .toList();
    }
    throw Exception('GetResistorMachineStatusData: unexpected payload');
  }

  Future<ResistorMachineRecord?> fetchRecordById(int id) async {
    final uri = Uri.parse('$_base/GetResistorMachineDataById')
        .replace(queryParameters: <String, String>{'Id': '$id'});

    final http.Response res = await _http
        .get(uri, headers: _headers(), timeout: _timeout)
        .catchError(
            (error) => throw Exception('GetResistorMachineDataById: $error'));

    if (res.statusCode == 204 || res.body.isEmpty) {
      return null;
    }

    _ensureSuccess(res, 'GetResistorMachineDataById');

    final dynamic body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return ResistorMachineRecordModel.fromJson(body);
    }
    throw Exception('GetResistorMachineDataById: unexpected payload');
  }

  Future<ResistorMachineRecord?> fetchRecordBySerial(String serialNumber) async {
    final uri = Uri.parse('$_base/GetResistorMachineDataBySn').replace(
      queryParameters: <String, String>{'SerialNumber': serialNumber},
    );

    final http.Response res = await _http
        .get(uri, headers: _headers(), timeout: _timeout)
        .catchError(
            (error) => throw Exception('GetResistorMachineDataBySn: $error'));

    if (res.statusCode == 204 || res.body.isEmpty) {
      return null;
    }

    _ensureSuccess(res, 'GetResistorMachineDataBySn');

    final dynamic body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return ResistorMachineRecordModel.fromJson(body);
    }
    throw Exception('GetResistorMachineDataBySn: unexpected payload');
  }

  Future<List<ResistorMachineSerialMatch>> searchSerialNumbers(
    String query, {
    int take = 12,
  }) async {
    if (query.trim().isEmpty) {
      return const <ResistorMachineSerialMatch>[];
    }

    final uri = Uri.parse('$_base/GetMatchedSerialNumbers').replace(
      queryParameters: <String, String>{
        'searchInput': query,
        'take': take.toString(),
      },
    );

    final http.Response res = await _http
        .get(uri, headers: _headers(), timeout: _timeout)
        .catchError(
            (error) => throw Exception('GetMatchedSerialNumbers: $error'));

    if (res.statusCode == 204) {
      return const <ResistorMachineSerialMatch>[];
    }

    _ensureSuccess(res, 'GetMatchedSerialNumbers');

    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(ResistorMachineSerialMatchModel.fromJson)
          .toList();
    }
    throw Exception('GetMatchedSerialNumbers: unexpected payload');
  }

  Future<List<ResistorMachineTestResult>> fetchTestResults(int id) async {
    final uri = Uri.parse('$_base/GetResistorMachineDataById')
        .replace(queryParameters: <String, String>{'Id': '$id'});

    final http.Response res = await _http
        .get(uri, headers: _headers(), timeout: _timeout)
        .catchError(
            (error) => throw Exception('GetResistorMachineDataById: $error'));

    if (res.statusCode == 204 || res.body.isEmpty) {
      return const <ResistorMachineTestResult>[];
    }

    _ensureSuccess(res, 'GetResistorMachineDataById');

    final dynamic body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      final dynamic testResults = body['TestResults'] ?? body['testResults'];
      if (testResults is List) {
        return testResults
            .whereType<Map<String, dynamic>>()
            .map(ResistorMachineTestResultModel.fromJson)
            .toList();
      }
    }

    return const <ResistorMachineTestResult>[];
  }

  void _ensureSuccess(http.Response res, String action) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$action failed (${res.statusCode}): ${res.body}');
    }
  }
}
