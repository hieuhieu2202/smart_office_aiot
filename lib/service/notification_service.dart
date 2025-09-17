import 'dart:convert';
import 'dart:io';

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
