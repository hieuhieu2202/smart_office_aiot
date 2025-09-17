import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../config/Apiconfig.dart';
import '../model/notification_draft.dart';
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

  static Future<void> sendNotification(NotificationDraft draft) async {
    if (draft.hasAttachment &&
        draft.attachment?.bytes == null &&
        (draft.attachment?.filePath?.isEmpty ?? true)) {
      throw ArgumentError('Tệp đính kèm không hợp lệ');
    }

    if (draft.hasAttachment) {
      await _sendMultipart(draft);
    } else {
      await _sendJson(draft);
    }
  }

  static Future<void> clearNotifications() async {
    final uri = _uri('/api/control/clear-notifications');
    final client = _createIoClient();
    try {
      final response = await client
          .post(uri, headers: {HttpHeaders.acceptHeader: 'application/json'})
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Không thể xoá thông báo (mã ${response.statusCode}). ${_extractError(response.body) ?? ''}',
        );
      }
    } finally {
      client.close();
    }
  }

  static Future<void> _sendJson(NotificationDraft draft) async {
    final uri = _uri('/api/control/send-notification-json');
    final client = _createIoClient();
    try {
      final payload = draft.toJsonPayload();
      final response = await client
          .post(
            uri,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.acceptHeader: 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Gửi thông báo thất bại (mã ${response.statusCode}). ${_extractError(response.body) ?? ''}',
        );
      }
    } finally {
      client.close();
    }
  }

  static Future<void> _sendMultipart(NotificationDraft draft) async {
    final uri = _uri('/api/control/send-notification');
    final request = http.MultipartRequest('POST', uri);

    final timestamp = draft.timestampUtc.toIso8601String();
    final fields = <String, String>{
      'title': draft.title,
      'Title': draft.title,
      'body': draft.body,
      'Body': draft.body,
      'message': draft.body,
      'timestampUtc': timestamp,
      'TimestampUtc': timestamp,
      'createdAt': timestamp,
    };

    if (draft.id != null && draft.id!.isNotEmpty) {
      fields['id'] = draft.id!;
      fields['Id'] = draft.id!;
    }
    if (draft.link != null && draft.link!.isNotEmpty) {
      fields['link'] = draft.link!;
      fields['Link'] = draft.link!;
    }
    if (draft.targetVersion != null && draft.targetVersion!.isNotEmpty) {
      fields['targetVersion'] = draft.targetVersion!;
      fields['TargetVersion'] = draft.targetVersion!;
    }

    request.fields.addAll(fields);

    final attachment = draft.attachment;
    if (attachment != null) {
      if (attachment.hasBytes) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          attachment.bytes!,
          filename: attachment.fileName,
        ));
      } else if (attachment.filePath != null && attachment.filePath!.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          attachment.filePath!,
          filename: attachment.fileName,
        ));
      }
    }

    final client = _createIoClient();
    try {
      final streamed = await client.send(request);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Gửi thông báo thất bại (mã ${response.statusCode}). ${_extractError(response.body) ?? ''}',
        );
      }
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
