import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/te_management/te_report_models.dart';
import 'auth/auth_config.dart';

class TEManagementApi {
  static const String _url =
      'https://10.220.130.117/NVIDIA/TEManagement/GetTableDetail';
  static const String _errorDetailUrl =
      'https://10.220.130.117/NVIDIA/TEManagement/GetErrorDetail';

  static Future<List<List<Map<String, dynamic>>>> fetchTableDetail({
    String modelSerial = 'SWITCH',
    required String rangeDateTime,
    String model = '',
  }) async {
    final payload = {
      'ModelSerial': modelSerial,
      'RangeDateTime': rangeDateTime,
      'model': model,
    };
    print('>> [TEManagementApi] POST $_url payload=$payload');

    final body = json.encode(payload);
    final stopwatch = Stopwatch()..start();

    final res = await http.post(
      Uri.parse(_url),
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
    );
    stopwatch.stop();
    print(
      '>> [TEManagementApi] Response status=${res.statusCode} length=${res.body.length} '
      'elapsed=${stopwatch.elapsedMilliseconds}ms',
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final raw = json.decode(res.body) as List;
      return raw
          .map<List<Map<String, dynamic>>>(
              (e) => List<Map<String, dynamic>>.from(e as List))
          .toList();
    } else if (res.statusCode == 204) {
      return [];
    } else {
      throw Exception(
          'Failed to load TE management data (${res.statusCode})');
    }
  }

  static Future<TEErrorDetail?> fetchErrorDetail({
    required String modelSerial,
    required String rangeDateTime,
    required String model,
    required String group,
  }) async {
    final payload = {
      'ModelSerial': modelSerial,
      'RangeDateTime': rangeDateTime,
      'model': model,
      'group': group,
    };

    print('>> [TEManagementApi] POST $_errorDetailUrl payload=$payload');

    final body = json.encode(payload);
    final res = await http.post(
      Uri.parse(_errorDetailUrl),
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
    );

    if (res.statusCode == 204 || res.body.isEmpty) {
      return null;
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to load error detail (${res.statusCode})');
    }

    final Map<String, dynamic> jsonMap = json.decode(res.body) as Map<String, dynamic>;
    return TEErrorDetail.fromJson(jsonMap);
  }
}
