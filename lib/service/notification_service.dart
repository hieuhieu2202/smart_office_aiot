import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../model/notification_message.dart';

class NotificationService {
  static const String _baseUrl = 'https://localhost:7283/api/control/';

  static IOClient _client() {
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  static Future<List<NotificationMessage>> getNotifications({int page = 1, int pageSize = 50}) async {
    final Uri url = Uri.parse('${_baseUrl}get-notifications?page=$page&pageSize=$pageSize');
    final IOClient client = _client();
    final http.Response res = await client.get(url);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
      final List<dynamic> items = data['items'] ?? [];
      return items.map((e) => NotificationMessage.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> sendNotification({required String title, required String body, String? id, File? file}) async {
    final Uri url = Uri.parse('${_baseUrl}send-notification');
    final IOClient client = _client();
    if (file == null) {
      final String payload = json.encode({'title': title, 'body': body, if (id != null) 'id': id});
      final http.Response res = await client.post(url, headers: {'Content-Type': 'application/json'}, body: payload);
      return res.statusCode == 200;
    } else {
      final http.MultipartRequest req = http.MultipartRequest('POST', url);
      req.fields['title'] = title;
      req.fields['body'] = body;
      if (id != null) {
        req.fields['id'] = id;
      }
      final http.MultipartFile multipartFile = await http.MultipartFile.fromPath('file', file.path);
      req.files.add(multipartFile);
      final http.StreamedResponse streamed = await client.send(req);
      return streamed.statusCode == 200;
    }
  }

  static Future<bool> clearNotifications() async {
    final Uri url = Uri.parse('${_baseUrl}clear-notifications');
    final IOClient client = _client();
    final http.Response res = await client.post(url);
    return res.statusCode == 200;
  }
}
