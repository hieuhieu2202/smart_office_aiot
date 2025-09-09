import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../model/notification_message.dart';

class NotificationService {
  static const String _baseUrl = 'http://10.220.130.117:2222/SendNoti/';

  static Future<List<NotificationMessage>> getNotifications({int page = 1, int pageSize = 50}) async {
    final Uri url = Uri.parse('${_baseUrl}get-notifications?page=$page&pageSize=$pageSize');
    final http.Response res = await http.get(url);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
      final List<dynamic> items = data['items'] ?? [];
      return items.map((e) => NotificationMessage.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> sendNotification({required String title, required String body, String? id, File? file}) async {
    final Uri url = Uri.parse('${_baseUrl}send-notification');
    if (file == null) {
      final String payload = json.encode({'title': title, 'body': body, if (id != null) 'id': id});
      final http.Response res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: payload);
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
      final http.StreamedResponse streamed = await req.send();
      return streamed.statusCode == 200;
    }
  }

  static Future<bool> clearNotifications() async {
    final Uri url = Uri.parse('${_baseUrl}clear-notifications');
    final http.Response res = await http.post(url);
    return res.statusCode == 200;
  }
}
