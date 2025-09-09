import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/notification_message.dart';
import '../model/notification_page.dart';

class NotificationService {
  static const String _baseUrl = 'http://10.220.130.117:2222/SendNoti/api/Control/';

  static final http.Client _client = http.Client();

  static Future<NotificationPage> getNotifications({
    int page = 1,
    int pageSize = 50,
  }) async {
    final Uri url =
        Uri.parse('${_baseUrl}get-notifications?page=$page&pageSize=$pageSize');
    debugPrint('[NotificationService] Fetching notifications…');
    final http.Response res = await _client.get(url);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final Map<String, dynamic> data =
          json.decode(res.body) as Map<String, dynamic>;
      final List<dynamic> items = data['items'] ?? [];
      final int total = data['total'] is int ? data['total'] as int : 0;
      debugPrint('[NotificationService] Received ${items.length} notifications');
      return NotificationPage(
        items: items.map((e) => NotificationMessage.fromJson(e)).toList(),
        total: total,
      );
    }
    debugPrint('[NotificationService] Fetch failed: ${res.statusCode}');
    return NotificationPage(items: const [], total: 0);
  }

  static Future<bool> sendNotification({
    required String title,
    required String body,
    String? id,
    File? file,
  }) async {
    final String endpoint =
        file == null ? 'send-notification-json' : 'send-notification-form';
    final Uri url = Uri.parse('$_baseUrl$endpoint');
    debugPrint('[NotificationService] Sending notification: "$title"');
    if (file == null) {
      final String payload =
          json.encode({'title': title, 'body': body, if (id != null) 'id': id});
      final http.Response res = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );
      debugPrint('[NotificationService] Send JSON status: ${res.statusCode}');
      return res.statusCode == 200;
    } else {
      final http.MultipartRequest req = http.MultipartRequest('POST', url);
      req.fields['title'] = title;
      req.fields['body'] = body;
      if (id != null) {
        req.fields['id'] = id;
      }
      final http.MultipartFile multipartFile =
          await http.MultipartFile.fromPath('file', file.path);
      req.files.add(multipartFile);
      final http.StreamedResponse streamed = await _client.send(req);
      debugPrint('[NotificationService] Send multipart status: ${streamed.statusCode}');
      return streamed.statusCode == 200;
    }
  }

  static Future<bool> clearNotifications() async {
    final Uri url = Uri.parse('${_baseUrl}clear-notifications');
    debugPrint('[NotificationService] Clearing notifications…');
    final http.Response res = await _client.post(url);
    debugPrint('[NotificationService] Clear status: ${res.statusCode}');
    return res.statusCode == 200;
  }

  /// Listen to server sent events for realtime notifications.
  ///
  /// Emits a [NotificationMessage] whenever the backend pushes a new event.
  static Stream<NotificationMessage> streamNotifications() async* {
    final http.Request request = http.Request(
      'GET',
      Uri.parse('${_baseUrl}notifications-stream'),
    );
    request.headers['Accept'] = 'text/event-stream';

    debugPrint('[NotificationService] Connecting to notification stream…');
    final http.StreamedResponse response = await _client.send(request);

    // SSE events are separated by empty lines. We accumulate `data:` lines
    // until an empty line is received, then decode the JSON payload.
    final Stream<String> lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    String dataBuffer = '';
    await for (final String line in lines) {
      if (line.startsWith('data:')) {
        dataBuffer += line.substring(5).trim();
      } else if (line.isEmpty) {
        if (dataBuffer.isNotEmpty) {
          try {
            final Map<String, dynamic> jsonData =
                json.decode(dataBuffer) as Map<String, dynamic>;
            debugPrint('[NotificationService] Stream event: $jsonData');
            yield NotificationMessage.fromJson(jsonData);
          } catch (e) {
            debugPrint('[NotificationService] Stream parse error: $e');
          }
          dataBuffer = '';
        }
      }
    }
  }
}
