import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

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

  static Future<NotificationFetchResult> fetchNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = _uri('/api/Control/get-notifications', {
      'appKey': ApiConfig.notificationAppKey,
      'page': page,
      'pageSize': pageSize,
    });
    final stopwatch = Stopwatch()..start();
    _log('GET $uri (page=$page, pageSize=$pageSize)');
    final client = _createIoClient();
    try {
      final response = await client
          .get(uri, headers: {HttpHeaders.acceptHeader: 'application/json'})
          .timeout(const Duration(seconds: 20));
      stopwatch.stop();
      _log(
        'GET $uri responded with ${response.statusCode} in '
        '${stopwatch.elapsedMilliseconds}ms',
      );

      if (response.statusCode == HttpStatus.noContent) {
        _log('Không có dữ liệu thông báo (204).');
        return NotificationFetchResult.empty(page: page, pageSize: pageSize);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final preview = _previewBody(response.body);
        _log(
          'Lỗi tải thông báo (mã ${response.statusCode}). Body: $preview',
        );
        throw Exception(
          'Không thể tải danh sách thông báo (mã ${response.statusCode}). ${_extractError(response.body) ?? ''}',
        );
      }

      final body = response.body.trim();
      if (body.isEmpty) {
        _log('Phản hồi rỗng khi tải thông báo.');
        return NotificationFetchResult.empty(page: page, pageSize: pageSize);
      }

      _log('Phản hồi: ${_previewBody(body)}');

      final dynamic decoded = jsonDecode(body);
      final items = NotificationMessage.listFrom(decoded);
      items.sort((a, b) {
        final DateTime ta =
            a.timestampUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime tb =
            b.timestampUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });

      final pagination = _extractPagination(
        decoded,
        requestedPage: page,
        requestedPageSize: pageSize,
        itemCount: items.length,
      );

      _log(
        'Đã phân tích ${items.length} thông báo. '
        'page=${pagination.page}, pageSize=${pagination.pageSize}, '
        'total=${pagination.total}',
      );

      return NotificationFetchResult(
        items: items,
        page: pagination.page,
        pageSize: pagination.pageSize,
        total: pagination.total,
      );
    } on FormatException catch (e, stackTrace) {
      _log('Dữ liệu thông báo không hợp lệ: ${e.message}',
          error: e, stackTrace: stackTrace);
      throw Exception('Dữ liệu thông báo không hợp lệ: ${e.message}');
    } catch (error, stackTrace) {
      _log('Lỗi không xác định khi tải thông báo: $error',
          error: error, stackTrace: stackTrace);
      rethrow;
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
      _log('Lên lịch kết nối lại realtime sau ${delay.inSeconds}s.');
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
          _uri('/api/Control/notifications-stream', {
            'appKey': ApiConfig.notificationAppKey,
          }),
        );
        final uri = request.url;
        _log('Mở kết nối realtime tới $uri');
        request.headers[HttpHeaders.acceptHeader] = 'text/event-stream';
        request.headers[HttpHeaders.cacheControlHeader] = 'no-cache';

        final response = await client!
            .send(request)
            .timeout(requestTimeout);

        if (response.statusCode != HttpStatus.ok) {
          _log('Kết nối realtime thất bại (mã ${response.statusCode}).');
          throw HttpException(
            'Không thể kết nối realtime (mã ${response.statusCode}).',
          );
        }

        _log('Kết nối realtime thành công.');
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
              _log(
                'Nhận thông báo realtime: '
                'id=${parsed.id ?? '-'}, title=${parsed.title}',
              );
              controller.add(parsed);
            }
          }
        }, onError: (error, stackTrace) {
          _log('Lỗi luồng realtime: $error',
              error: error, stackTrace: stackTrace);
          if (!disposed && !controller.isClosed) {
            controller.addError(error, stackTrace);
          }
          unawaited(closeResources());
          scheduleReconnect();
        }, onDone: () {
          _log('Kết nối realtime đóng.');
          unawaited(closeResources());
          scheduleReconnect();
        });
      } catch (error, stackTrace) {
        _log('Không thể duy trì kết nối realtime: $error',
            error: error, stackTrace: stackTrace);
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
    } catch (error, stackTrace) {
      _log('Không thể parse sự kiện realtime: $error',
          error: error, stackTrace: stackTrace);
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

  static void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'NotificationService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _previewBody(String? body) {
    if (body == null) {
      return '';
    }
    final normalized = body.trim();
    if (normalized.length <= 512) {
      return normalized;
    }
    return '${normalized.substring(0, 512)}…';
  }
}

class NotificationFetchResult {
  const NotificationFetchResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<NotificationMessage> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasMore {
    if (total > 0 && pageSize > 0) {
      return page * pageSize < total;
    }
    if (pageSize > 0) {
      return items.length >= pageSize;
    }
    return items.isNotEmpty;
  }

  bool get isEmpty => items.isEmpty;

  factory NotificationFetchResult.empty({int page = 1, int pageSize = 0}) {
    return NotificationFetchResult(
      items: const <NotificationMessage>[],
      page: page,
      pageSize: pageSize,
      total: 0,
    );
  }
}

class _PaginationSnapshot {
  const _PaginationSnapshot({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final int page;
  final int pageSize;
  final int total;
}

_PaginationSnapshot _extractPagination(
  dynamic decoded, {
  required int requestedPage,
  required int requestedPageSize,
  required int itemCount,
}) {
  var resolvedPage = requestedPage <= 0 ? 1 : requestedPage;
  var resolvedPageSize = requestedPageSize < 0 ? 0 : requestedPageSize;
  var resolvedTotal = itemCount;

  if (decoded is Map<String, dynamic>) {
    resolvedPage = _readInt(decoded, const [
          'page',
          'Page',
          'currentPage',
          'CurrentPage',
          'pageIndex',
          'PageIndex',
        ]) ??
        resolvedPage;

    resolvedPageSize = _readInt(decoded, const [
          'pageSize',
          'PageSize',
          'size',
          'Size',
          'limit',
          'Limit',
        ]) ??
        resolvedPageSize;

    resolvedTotal = _readInt(decoded, const [
          'total',
          'Total',
          'totalCount',
          'TotalCount',
          'records',
          'Records',
        ]) ??
        resolvedTotal;

    if (resolvedPageSize <= 0) {
      final dynamic items = decoded['items'] ?? decoded['Items'];
      if (items is List) {
        resolvedPageSize = items.length;
      }
    }
  }

  if (resolvedPage <= 0) {
    resolvedPage = requestedPage > 0 ? requestedPage : 1;
  }
  if (resolvedPageSize <= 0) {
    resolvedPageSize = itemCount > 0
        ? itemCount
        : (requestedPageSize > 0 ? requestedPageSize : itemCount);
  }
  if (resolvedTotal < itemCount) {
    resolvedTotal = itemCount;
  }

  return _PaginationSnapshot(
    page: resolvedPage,
    pageSize: resolvedPageSize,
    total: resolvedTotal,
  );
}

int? _readInt(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (!source.containsKey(key)) continue;
    final value = source[key];
    if (value == null) {
      continue;
    } else if (value is int) {
      return value;
    } else if (value is double) {
      return value.toInt();
    } else if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}
