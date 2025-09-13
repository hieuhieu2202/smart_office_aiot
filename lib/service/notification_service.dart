import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import '../model/notification_message.dart';

class NotificationService {
  static const String _host = 'http://10.220.130.117:2222/SendNoti';
  static const String _baseUrl = '$_host/api/Notifications/';
  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');
  /// AES key used for decrypting base64 attachments.
  /// Must be 16/24/32 bytes to satisfy AES requirements.
  static final enc.Key _aesKey =
      enc.Key.fromUtf8('32lengthsupersecretkey!!!!!!!!!!');
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
    final url = _uri('?page=$page&pageSize=$pageSize');
    final client = _getInsecureClient();
    try {
      final res =
          await client.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(res.body);
        final List<dynamic> items = data['items'] ?? [];
        final result =
            items.map((e) => _parseMessage(e as Map<String, dynamic>)).toList();
        print('[NotificationService] getNotifications => ${result.length} items');
        return result;
      }
      print('[NotificationService] getNotifications failed (${res.statusCode})');
      return [];
    } on TimeoutException catch (e) {
      print('[NotificationService] getNotifications timeout: $e');
      return [];
    } catch (e) {
      print('[NotificationService] getNotifications error: $e');
      return [];
    } finally {
      client.close();
    }
  }

  static Future<bool> sendNotification({
    String? id,
    required String title,
    required String body,
    String? link,
    File? file,
  }) async {
    final uri = _uri('form');
    final client = _getInsecureClient();
    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['Title'] = title
        ..fields['Body'] = body;
      if (id != null) request.fields['Id'] = id;
      if (link != null) request.fields['Link'] = link;
      if (file != null) {
        request.files
            .add(await http.MultipartFile.fromPath('File', file.path));
      }
      final streamed = await client.send(request);
      final responseBody = await streamed.stream.bytesToString();
      print(
          '[NotificationService] sendNotification status ${streamed.statusCode} body: $responseBody');
      return streamed.statusCode == 200;
    } finally {
      client.close();
    }
  }

  static Future<bool> clearNotifications() async {
    final url = _uri('clear');
    final client = _getInsecureClient();
    try {
      final res = await client.post(url);
      print('[NotificationService] clearNotifications status ${res.statusCode}');
      return res.statusCode == 200;
    } finally {
      client.close();
    }
  }

  static Stream<NotificationMessage> streamNotifications() async* {
    final client = _getInsecureClient();
    try {
      final request = http.Request('GET', _uri('stream'))
        ..headers['Accept'] = 'text/event-stream';
      final response = await client.send(request);
      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        if (line.startsWith('data:')) {
          final data = line.substring(5).trim();
          if (data.isNotEmpty) {
            final msg =
                _parseMessage(json.decode(data) as Map<String, dynamic>);
            print('[NotificationService] streamNotifications received ${msg.id}');
            yield msg;
          }
        }
      }
    } finally {
      client.close();
    }
  }

  static NotificationMessage _parseMessage(Map<String, dynamic> json) {
    try {
      final msg = NotificationMessage.fromJson(json);
      var updated = msg;
      final url = msg.fileUrl;
      if (url != null && url.isNotEmpty && !url.startsWith('http')) {
        updated = updated.copyWith(fileUrl: '$_host$url');
      }
      final link = msg.link;
      if (link != null && link.isNotEmpty && !link.startsWith('http')) {
        updated = updated.copyWith(link: '$_host$link');
      }
      return updated;
    } catch (e) {
      print('[NotificationService] failed to parse notification: $e');
      rethrow;
    }
  }

  static Future<Uint8List> decryptBase64(String data) {
    return compute(_decryptBase64, data);
  }

  static Uint8List _decryptBase64(String data) {
    final raw = base64Decode(data);
    try {
      final encrypter = enc.Encrypter(
        enc.AES(_aesKey, mode: enc.AESMode.cbc),
      );
      final decrypted =
          encrypter.decryptBytes(enc.Encrypted(raw), iv: _aesIv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      print('[NotificationService] AES decrypt failed: $e');
      return raw;
    }
  }
}
