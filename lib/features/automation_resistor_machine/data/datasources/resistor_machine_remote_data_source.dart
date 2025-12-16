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

  // ===============================
  // BASE CONFIG
  // ===============================
  static const String _host = 'https://10.220.130.117';
  static const String _apiPrefix = '/api/auto';
  static const String _controller = '/ResistorMachine';

  static const Duration _timeout = Duration(seconds: 40);

  String _endpoint(String path) =>
      '$_host$_apiPrefix$_controller/$path';

  Map<String, String> _headers() => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ===============================
  // API METHODS
  // ===============================

  /// GET: GetResistorMachineNames
  Future<List<String>> fetchMachineNames() async {
    final uri = Uri.parse(_endpoint('GetResistorMachineNames'));
    _log(uri);

    final res = await _http.get(
      uri,
      headers: _headers(),
      timeout: _timeout,
    );

    _ensureSuccess(res, 'GetResistorMachineNames');

    final body = jsonDecode(res.body);
    if (body is List) {
      return body.whereType<String>().toList();
    }
    throw Exception('GetResistorMachineNames: unexpected payload');
  }

  /// POST: GetResistorMachineTrackingData
  Future<ResistorMachineTrackingData> fetchTrackingData(
      ResistorMachineRequest request,
      ) async {
    final uri = Uri.parse(_endpoint('GetResistorMachineTrackingData'));
    _log(uri, request.toBody());

    final res = await _http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(request.toBody()),
      timeout: _timeout,
    );

    _ensureSuccess(res, 'GetResistorMachineTrackingData');

    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return ResistorMachineTrackingDataModel.fromJson(body);
    }
    throw Exception('GetResistorMachineTrackingData: unexpected payload');
  }

  /// POST: GetResistorMachineStatusData
  Future<List<ResistorMachineStatus>> fetchStatusData(
      ResistorMachineRequest request,
      ) async {
    final uri = Uri.parse(_endpoint('GetResistorMachineStatusData'));
    _log(uri, request.toBody());

    final res = await _http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(request.toBody()),
      timeout: _timeout,
    );

    _ensureSuccess(res, 'GetResistorMachineStatusData');

    final body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(ResistorMachineStatusModel.fromJson)
          .toList();
    }
    throw Exception('GetResistorMachineStatusData: unexpected payload');
  }

  /// GET: GetResistorMachineDataById
  Future<ResistorMachineRecord?> fetchRecordById(int id) async {
    final uri = Uri.parse(_endpoint('GetResistorMachineDataById'))
        .replace(queryParameters: {'Id': '$id'});
    _log(uri);

    final res = await _http.get(
      uri,
      headers: _headers(),
      timeout: _timeout,
    );

    if (res.statusCode == 204 || res.body.isEmpty) return null;

    _ensureSuccess(res, 'GetResistorMachineDataById');

    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return ResistorMachineRecordModel.fromJson(body);
    }
    throw Exception('GetResistorMachineDataById: unexpected payload');
  }

  /// GET: GetResistorMachineDataBySn
  Future<ResistorMachineRecord?> fetchRecordBySerial(String serial) async {
    final uri = Uri.parse(_endpoint('GetResistorMachineDataBySn'))
        .replace(queryParameters: {'SerialNumber': serial});
    _log(uri);

    final res = await _http.get(
      uri,
      headers: _headers(),
      timeout: _timeout,
    );

    if (res.statusCode == 204 || res.body.isEmpty) return null;

    _ensureSuccess(res, 'GetResistorMachineDataBySn');

    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return ResistorMachineRecordModel.fromJson(body);
    }
    throw Exception('GetResistorMachineDataBySn: unexpected payload');
  }

  /// GET: GetMatchedSerialNumbers
  Future<List<ResistorMachineSerialMatch>> searchSerialNumbers(
      String query, {
        int take = 12,
      }) async {
    if (query.trim().isEmpty) return const [];

    final uri = Uri.parse(_endpoint('GetMatchedSerialNumbers')).replace(
      queryParameters: {
        'searchInput': query,
        'take': take.toString(),
      },
    );
    _log(uri);

    final res = await _http.get(
      uri,
      headers: _headers(),
      timeout: _timeout,
    );

    if (res.statusCode == 204) return const [];

    _ensureSuccess(res, 'GetMatchedSerialNumbers');

    final body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(ResistorMachineSerialMatchModel.fromJson)
          .toList();
    }
    throw Exception('GetMatchedSerialNumbers: unexpected payload');
  }

  /// GET: Test Result
  Future<List<ResistorMachineTestResult>> fetchTestResults(int id) async {
    final record = await fetchRecordById(id);
    final raw = record?.dataDetails;
    if (raw == null) return const [];

    try {
      final parsed = raw is String ? jsonDecode(raw) : raw;
      if (parsed is List) {
        return parsed
            .whereType<Map<String, dynamic>>()
            .map(ResistorMachineTestResultModel.fromJson)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  // ===============================
  // HELPERS
  // ===============================
  void _ensureSuccess(http.Response res, String action) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$action failed (${res.statusCode}): ${res.body}');
    }
  }

  void _log(Uri uri, [Map<String, dynamic>? body]) {
    // ignore: avoid_print
    print('[ResistorAPI] ${uri.toString()}');
    if (body != null) {
      // ignore: avoid_print
      print('[ResistorAPI] payload: $body');
    }
  }
}
