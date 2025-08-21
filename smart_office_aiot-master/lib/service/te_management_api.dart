import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth/auth_config.dart';

class TEManagementApi {
  static const String _url =
      'https://10.220.130.117/NVIDIA/TEManagement/GetTableDetail';

  static Future<List<List<Map<String, dynamic>>>> fetchTableDetail({
    String modelSerial = 'SWITCH',
    required String rangeDateTime,
    String model = '',
  }) async {
    final body = json.encode({
      'ModelSerial': modelSerial,
      'RangeDateTime': rangeDateTime,
      'model': model,
    });

    final res = await http.post(
      Uri.parse(_url),
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
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
}
