import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth/auth_config.dart';

class YieldRateApi {
  static const String _url =
      'https://10.220.130.117/NVIDIA/YieldRate/PostOutputReport';

  static Future<Map<String, dynamic>> getOutputReport({
    String customer = 'NVIDIA',
    String type = 'SWITCH',
    required String rangeDateTime,
    String nickName = 'All',
  }) async {
    final payload = {
      'Customer': customer,
      'Type': type,
      'RangeDateTime': rangeDateTime,
      'NickName': nickName,
    };
    print('>> [YieldRateApi] POST $_url payload=$payload');

    final body = json.encode(payload);

    final res = await http.post(
      Uri.parse(_url),
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
    );
    print(
      '>> [YieldRateApi] Response status=${res.statusCode} length=${res.body.length}',
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else if (res.statusCode == 204) {
      return {};
    } else {
      throw Exception('Failed to load output report (${res.statusCode})');
    }
  }
}
