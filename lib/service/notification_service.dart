import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../model/notification_message.dart';

class NotificationService {
  static const String _baseUrl =
      'http://10.220.130.117:2222/SendNoti/api/Control/';
  static const String _host = 'http://10.220.130.117:2222';
  static final enc.Key _aesKey =
      enc.Key.fromUtf8('32lengthsupersecretkey!!!!!!!!!');
  static final enc.IV _aesIv = enc.IV.fromLength(16);

  static IOClient _getInsecureClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    return IOClient(httpClient);
  }

  static Future<List<NotificationMessage>> getNotifications({
    int page = 1,
    int pageSize = 50,
  }) async {
    final url = Uri.parse('${_baseUrl}get-notifications?page=$page&pageSize=$pageSize');
    final client = _getInsecureClient();
    final res = await client.get(url);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final Map<String, dynamic> data = json.decode(res.body);
      final List<dynamic> items = data['items'] ?? [];
      return items
          .map((e) => _parseMessage(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch notifications (${res.statusCode})');
  }

  static Future<bool> sendNotification({
    String? id,
    required String title,
    required String body,
    File? file,
  }) async {
    final uri = Uri.parse('${_baseUrl}send-notification');
    final client = _getInsecureClient();
    final request = http.MultipartRequest('POST', uri)
      ..fields['Title'] = title
      ..fields['Body'] = body;
    if (id != null) request.fields['Id'] = id;
    if (file != null) {
      request.files
          .add(await http.MultipartFile.fromPath('File', file.path));
    }
    final streamed = await client.send(request);
    return streamed.statusCode == 200;
  }

  static Future<bool> clearNotifications() async {
    final url = Uri.parse('${_baseUrl}clear-notifications');
    final client = _getInsecureClient();
    final res = await client.post(url);
    return res.statusCode == 200;
  }

  static Stream<NotificationMessage> streamNotifications() async* {
    final client = _getInsecureClient();
    final request = http.Request(
        'GET', Uri.parse('${_baseUrl}notifications-stream'))
      ..headers['Accept'] = 'text/event-stream';
    final response = await client.send(request);
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (line.startsWith('data:')) {
        final data = line.substring(5).trim();
        if (data.isNotEmpty) {
          yield _parseMessage(json.decode(data) as Map<String, dynamic>);
        }
      }
    }
  }

  static NotificationMessage _parseMessage(Map<String, dynamic> json) {
    final msg = NotificationMessage.fromJson(json);
    final url = msg.fileUrl;
    if (url != null && url.isNotEmpty && !url.startsWith('http')) {
      return msg.copyWith(fileUrl: '$_host$url');
    }
    return msg;
  }

  static List<int> decryptBase64(String data) {
    final encrypter = enc.Encrypter(enc.AES(_aesKey, mode: enc.AESMode.cbc));
    final encrypted = enc.Encrypted(base64Decode(data));
    return encrypter.decryptBytes(encrypted, iv: _aesIv);
  }
}
