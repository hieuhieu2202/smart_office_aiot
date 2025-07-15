import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screen/login/controller/token_manager.dart';

class PTHDashboardApi {
  static String get token => TokenManager().civetToken.value;
  static Map<String, String> get headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  static final String _baseUrl = "https://10.220.23.244:4433/api/ccdmachine/aoivi/";

  static Future<List<String>> getGroupNames() async {
    var url = Uri.parse("${_baseUrl}GetGroupNames");
    var res = await http.get(url, headers: headers);
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
    var res = await http.get(url, headers: headers);
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

  static Future<List<String>> getModelNames(String groupName, String machineName) async {
    var url = Uri.parse("${_baseUrl}GetModelNames?groupName=$groupName&machineName=$machineName");
    var res = await http.get(url, headers: headers);
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

    var res = await http.post(url, headers: headers, body: body);
    print('[DEBUG] Status: ${res.statusCode}');
    print('[DEBUG] Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else if (res.statusCode == 204) {
      return {};
    } else {
      throw Exception('Failed to load monitoring data (${res.statusCode})');
    }
  }
}
