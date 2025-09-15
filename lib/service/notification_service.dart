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
  // Base paths for notification and device endpoints provided by the backend.
  static Uri _notifications(String path) =>
      Uri.parse('$_host/api/notifications$path');
  static Uri _device(String id, String path) =>
      Uri.parse('$_host/api/devices/$id$path');
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
    final url =
        _notifications('?page=$page&pageSize=$pageSize');
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
    // Backend expects multipart form at `/api/notifications/form`.
    final uri = _notifications('/form');
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

  /// Sends a notification as JSON payload. Useful when the attachment is
  /// already encoded to base64. Returns `true` when the server accepts the
  /// request with status `200`.
  static Future<bool> sendNotificationJson(NotificationMessage msg) async {
    final uri = _notifications('');
    final client = _getInsecureClient();
    try {
      final res = await client
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(msg.toJson()))
          .timeout(const Duration(seconds: 10));
      print('[NotificationService] sendNotificationJson status '
          '${res.statusCode} body: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      print('[NotificationService] sendNotificationJson error: $e');
      return false;
    } finally {
      client.close();
    }
  }

  static Future<bool> clearNotifications() async {
    // Endpoint for clearing notifications.
    final url = _notifications('/clear');
    final client = _getInsecureClient();
    try {
      final res = await client.post(url);
      print('[NotificationService] clearNotifications status ${res.statusCode}');
      return res.statusCode == 200;
    } finally {
      client.close();
    }
  }

  /// Report the current app [version] of a device to the server.
  static Future<void> reportDeviceVersion(
      {required String deviceId, required String version}) async {
    final url = _device(deviceId, '/version');
    final client = _getInsecureClient();
    try {
      final res = await client.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'version': version}));
      print('[NotificationService] reportDeviceVersion ${res.statusCode}');
    } catch (e) {
      print('[NotificationService] reportDeviceVersion error: $e');
    } finally {
      client.close();
    }
  }

  /// Fetch notifications not yet received by this device. Optional
  /// [sinceVersion] can be supplied to only receive newer ones.
  static Future<List<NotificationMessage>> getDeviceNotifications(
      {required String deviceId, String? sinceVersion}) async {
    final qs = sinceVersion != null ? '?sinceVersion=$sinceVersion' : '';
    final url = _device(deviceId, '/notifications$qs');
    final client = _getInsecureClient();
    try {
      final res =
          await client.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final List<dynamic> data = json.decode(res.body) as List<dynamic>;
        final result =
            data.map((e) => _parseMessage(e as Map<String, dynamic>)).toList();
        print('[NotificationService] getDeviceNotifications => ${result.length}');
        return result;
      }
      print('[NotificationService] getDeviceNotifications failed (${res.statusCode})');
      return [];
    } on TimeoutException catch (e) {
      print('[NotificationService] getDeviceNotifications timeout: $e');
      return [];
    } catch (e) {
      print('[NotificationService] getDeviceNotifications error: $e');
      return [];
    } finally {
      client.close();
    }
  }

  static Stream<NotificationMessage> streamNotifications() async* {
    final client = _getInsecureClient();
    try {
      // Subscribe to the server-sent events stream.
      final request = http.Request('GET', _notifications('/stream'))
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
