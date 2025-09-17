import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../config/Apiconfig.dart';
import '../model/notification_message.dart';

class NotificationService {
  NotificationService._();

  static final Uri _baseUri = Uri.parse(ApiConfig.notificationBaseUrl);

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = ApiConfig.notificationBaseUrl.endsWith('/')
        ? ApiConfig.notificationBaseUrl
            .substring(0, ApiConfig.notificationBaseUrl.length - 1)
        : ApiConfig.notificationBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$normalizedPath');
    if (query == null || query.isEmpty) {
      return uri;
    }
    final queryParams = <String, String>{};
    query.forEach((key, value) {
      if (value != null) {
        queryParams[key] = value.toString();
      }
    });
    return uri.replace(queryParameters: queryParams);
  }

  static HttpClient _createHttpClient() {
    final client = HttpClient();
    if (_baseUri.scheme == 'https') {
      client.badCertificateCallback =
          (cert, host, port) => host == _baseUri.host;
    }
    return client;
  }

  static IOClient _createIoClient() => IOClient(_createHttpClient());

  static Future<List<NotificationMessage>> fetchNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = _uri('/api/control/get-notifications', {
      'page': page,
      'pageSize': pageSize,
    });
    final client = _createIoClient();
    try {
      final response = await client
          .get(uri, headers: {HttpHeaders.acceptHeader: 'application/json'})
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == HttpStatus.noContent) {
        return const [];
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Không thể tải danh sách thông báo (mã ${response.statusCode}). ${_extractError(response.body) ?? ''}',
        );
      }

      final body = response.body.trim();
      if (body.isEmpty) {
        return const [];
      }

      final dynamic decoded = jsonDecode(body);
      final items = NotificationMessage.listFrom(decoded);
      items.sort((a, b) {
        final DateTime ta = a.timestampUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime tb = b.timestampUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      return items;
    } on FormatException catch (e) {
      throw Exception('Dữ liệu thông báo không hợp lệ: ${e.message}');
    } finally {
      client.close();
    }
  }

  static Stream<NotificationMessage> realtimeNotifications() {
    IOClient? client;
    StreamSubscription<String>? subscription;
    StreamController<NotificationMessage>? controller;

    Future<void> closeResources() async {
      await subscription?.cancel();
      subscription = null;
      client?.close();
      client = null;
    }

    Future<void> connect() async {
      await closeResources();
      client = _createIoClient();
      final request = http.Request(
        'GET',
        _uri('/api/control/notifications-stream'),
      );
      request.headers[HttpHeaders.acceptHeader] = 'text/event-stream';

      try {
        final response = await client!
            .send(request)
            .timeout(const Duration(seconds: 20));

        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'Không thể kết nối realtime (mã ${response.statusCode}).',
          );
        }

        var buffer = '';
        subscription = response.stream
            .transform(utf8.decoder)
            .listen((chunk) {
          buffer += chunk;
          final parts = buffer.split(RegExp(r'\r?\n\r?\n'));
          for (var i = 0; i < parts.length - 1; i++) {
            final parsed = _parseSseEvent(parts[i]);
            if (parsed != null) {
              controller?.add(parsed);
            }
          }
          buffer = parts.isNotEmpty ? parts.last : '';
        }, onError: (error, stackTrace) {
          if (!(controller?.isClosed ?? true)) {
            controller?.addError(error, stackTrace);
          }
        }, onDone: () async {
          await closeResources();
          if (!(controller?.isClosed ?? true)) {
            await controller?.close();
          }
        });
      } catch (error, stackTrace) {
        if (!(controller?.isClosed ?? true)) {
          controller?.addError(error, stackTrace);
        }
        await closeResources();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!(controller?.isClosed ?? true)) {
          await controller?.close();
        }
      }
    }

    controller = StreamController<NotificationMessage>(
      onListen: connect,
      onCancel: () async {
        await closeResources();
      },
      onPause: () async {
        await closeResources();
      },
      onResume: connect,
    );

    return controller.stream;
  }

  static NotificationMessage? _parseSseEvent(String rawEvent) {
    final lines = rawEvent.split(RegExp(r'\r?\n'));
    final buffer = StringBuffer();

    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line.startsWith('data:')) {
        final data = line.substring(5).trimLeft();
        if (buffer.isNotEmpty) {
          buffer.write('\n');
        }
        buffer.write(data);
      }
    }

    final payload = buffer.toString().trim();
    if (payload.isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return NotificationMessage.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static String? _extractError(String? body) {
    if (body == null || body.isEmpty) return null;
    final raw = body.trim();
    if (raw.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'error', 'detail']) {
          final value = decoded[key];
          if (value is String && value.isNotEmpty) {
            return value;
          }
        }
      }
    } catch (_) {
      return raw;
    }
    return raw;
  }
}
