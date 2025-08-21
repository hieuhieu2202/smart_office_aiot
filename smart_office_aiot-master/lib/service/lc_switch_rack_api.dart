import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth/auth_config.dart';

class LCSwitchRackApi {
  static const String _url =
      'https://10.220.130.117/NVIDIA/NvidiaLayout/GroupDataMonitoring';

  static Future<Map<String, dynamic>> getRackMonitoring({
    String modelSerial = 'SWITCH',
    String groupName = 'J_TAG',
    String nickName = 'GB300',
  }) async {
    final body = json.encode({
      'ModelSerial': modelSerial,
      'GroupName': groupName,
      'NickName': nickName,
    });

    final res = await http.post(
      Uri.parse(_url),
      headers: AuthConfig.getAuthorizedHeaders(),
      body: body,
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else if (res.statusCode == 204) {
      return {};
    } else {
      throw Exception(
          'Failed to load rack monitoring data (${res.statusCode})');
    }
  }
}
