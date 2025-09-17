import 'dart:async';
import 'dart:convert';
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

  static Stream<NotificationMessage> realtimeNotifications({
    Duration initialRetryDelay = const Duration(seconds: 10),
    Duration maxRetryDelay = const Duration(seconds: 30),
    Duration requestTimeout = const Duration(seconds: 20),
  }) {
    IOClient? client;
    StreamSubscription<String>? subscription;
    Timer? retryTimer;
    var retryDelay = initialRetryDelay;
    var connecting = false;
    var disposed = false;

    Future<void> closeResources() async {
      await subscription?.cancel();
      subscription = null;
      client?.close();
      client = null;
    }

    Duration _nextDelay(Duration current) {
      final currentMs = current.inMilliseconds;
      final maxMs = maxRetryDelay.inMilliseconds;
      if (currentMs >= maxMs) {
        return maxRetryDelay;
      }
      final doubled = currentMs * 2;
      return Duration(milliseconds: doubled >= maxMs ? maxMs : doubled);
    }

    late final StreamController<NotificationMessage> controller;

    late Future<void> Function() connect;

    void scheduleReconnect([Duration? override]) {
      if (disposed || controller.isClosed) {
        return;
      }
      retryTimer?.cancel();
      final delay = override ?? retryDelay;
      retryTimer = Timer(delay, () {
        retryTimer = null;
        if (disposed || controller.isClosed) {
          return;
        }
        connect();
      });
      if (override == null) {
        retryDelay = _nextDelay(retryDelay);
      }
    }

    connect = () async {
      if (connecting || disposed || controller.isClosed) {
        return;
      }
      connecting = true;
      await subscription?.cancel();
      subscription = null;
      client?.close();
      client = null;

      try {
        client = _createIoClient();
        final request = http.Request(
          'GET',
          _uri('/api/control/notifications-stream'),
        );
        request.headers[HttpHeaders.acceptHeader] = 'text/event-stream';
        request.headers[HttpHeaders.cacheControlHeader] = 'no-cache';

        final response = await client!
            .send(request)
            .timeout(requestTimeout);

        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'Không thể kết nối realtime (mã ${response.statusCode}).',
          );
        }

        retryDelay = initialRetryDelay;
        var buffer = '';
        subscription = response.stream
            .transform(utf8.decoder)
            .listen((chunk) {
          buffer += chunk;
          final parts = buffer.split(RegExp(r'\r?\n\r?\n'));
          if (parts.isEmpty) {
            return;
          }
          buffer = parts.removeLast();
          for (final part in parts) {
            final parsed = _parseSseEvent(part);
            if (parsed != null && !disposed && !controller.isClosed) {
              controller.add(parsed);
            }
          }
        }, onError: (error, stackTrace) {
          if (!disposed && !controller.isClosed) {
            controller.addError(error, stackTrace);
          }
          unawaited(closeResources());
          scheduleReconnect();
        }, onDone: () {
          unawaited(closeResources());
          scheduleReconnect();
        });
      } catch (error, stackTrace) {
        if (!disposed && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
        scheduleReconnect();
      } finally {
        connecting = false;
      }
    };

    controller = StreamController<NotificationMessage>(
      onListen: () {
        disposed = false;
        retryDelay = initialRetryDelay;
        scheduleReconnect(Duration.zero);
      },
      onResume: () {
        if (subscription != null) {
          subscription!.resume();
        } else {
          scheduleReconnect(Duration.zero);
        }
      },
      onPause: () {
        subscription?.pause();
      },
      onCancel: () async {
        disposed = true;
        retryTimer?.cancel();
        retryTimer = null;
        await closeResources();
      },
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
