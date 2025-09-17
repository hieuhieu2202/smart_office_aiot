import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/Apiconfig.dart';
import '../model/notification_attachment_payload.dart';
import '../model/notification_message.dart';
import '../screen/notification/notification_attachment_viewer.dart';

class NotificationAttachmentService {
  NotificationAttachmentService._();

  static Future<void> openAttachment(NotificationMessage message) async {
    try {
      final payload = await _resolve(message);
      if (payload == null) {
        _showError(
          'Không có tệp đính kèm',
          'Thông báo không cung cấp tệp nào để mở.',
        );
        return;
      }

      if (payload.isInline) {
        if (payload.isImage) {
          await Get.to(() => NotificationAttachmentViewer(payload: payload));
          return;
        }

        final result = await OpenFilex.open(payload.file!.path);
        if (result.type != ResultType.done) {
          _showError(
            'Không thể mở tệp đính kèm',
            result.message ?? 'Ứng dụng trên thiết bị không hỗ trợ định dạng này.',
          );
        }
        return;
      }

      if (payload.isRemote) {
        final success =
            await launchUrl(payload.remoteUri!, mode: LaunchMode.externalApplication);
        if (!success) {
          _showError('Không thể mở tệp đính kèm', payload.remoteUri.toString());
        }
      }
    } on FormatException catch (exception) {
      if (exception.message == 'invalid-url') {
        _showError(
          'Đường dẫn tệp không hợp lệ',
          message.fileUrl ?? 'Máy chủ trả về URL trống.',
        );
      } else {
        _showError(
          'Tệp đính kèm bị lỗi',
          'Ứng dụng không giải mã được dữ liệu base64 mà máy chủ gửi về.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Không mở được tệp đính kèm: $error\n$stackTrace');
      _showError('Lỗi khi mở tệp', error.toString());
    }
  }

  static Future<NotificationAttachmentPayload?> _resolve(
    NotificationMessage message,
  ) async {
    final String? normalized = _normalizedBase64(message.fileBase64);
    if (normalized != null) {
      final bytes = base64Decode(normalized);
      final mimeType = _inferMimeType(message);
      final fileName = _buildFileName(message, mimeType);
      final file = await _writeToCache(fileName, bytes);
      return NotificationAttachmentPayload.inline(
        file: file,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    }

    final rawUrl = message.fileUrl?.trim();
    final uri = _resolveRemoteUri(message);
    if (uri != null) {
      final fileName = _remoteFileName(message, uri);
      final mimeType = message.fileContentType ?? _mimeFromExtension(fileName);
      return NotificationAttachmentPayload.remote(
        remoteUri: uri,
        fileName: fileName,
        mimeType: mimeType,
      );
    }

    if (rawUrl != null && rawUrl.isNotEmpty) {
      throw const FormatException('invalid-url');
    }

    return null;
  }

  static Uri? _resolveRemoteUri(NotificationMessage message) {
    final raw = message.fileUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    final resolved = ApiConfig.normalizeNotificationUrl(raw);
    return Uri.tryParse(resolved);
  }

  static String? _normalizedBase64(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final commaIndex = trimmed.indexOf(',');
    if (commaIndex != -1) {
      final header = trimmed.substring(0, commaIndex).toLowerCase();
      if (header.contains('base64')) {
        return trimmed.substring(commaIndex + 1).replaceAll(RegExp(r'\s'), '');
      }
    }
    return trimmed.replaceAll(RegExp(r'\s'), '');
  }

  static String? _inferMimeType(NotificationMessage message) {
    final direct = message.fileContentType;
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    final headerMime = _mimeFromDataUri(message.fileBase64);
    if (headerMime != null) {
      return headerMime;
    }
    if (message.fileName != null && message.fileName!.contains('.')) {
      return _mimeFromExtension(message.fileName!);
    }
    return null;
  }

  static String? _mimeFromDataUri(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (!trimmed.startsWith('data:')) return null;
    final separator = trimmed.indexOf(';');
    if (separator == -1) return null;
    final mime = trimmed.substring(5, separator).trim();
    return mime.isEmpty ? null : mime;
  }

  static String _buildFileName(NotificationMessage message, String? mimeType) {
    final rawName = message.fileName?.trim();
    final fallbackBase = message.id != null && message.id!.isNotEmpty
        ? 'notification_${message.id}'
        : 'notification_${message.timestampUtc?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';
    final baseName = _sanitizeFileName(rawName?.isNotEmpty == true ? rawName! : fallbackBase);
    final sanitized = baseName.isEmpty ? 'attachment' : baseName;
    if (sanitized.contains('.')) {
      return sanitized;
    }
    final extension = _extensionFromMime(mimeType) ?? 'bin';
    return '$sanitized.$extension';
  }

  static String _sanitizeFileName(String value) {
    final replaced = value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return replaced.replaceAll(RegExp(r'\s+'), '_');
  }

  static Future<File> _writeToCache(String fileName, Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final cacheDir = Directory('${directory.path}/notification_attachments');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final file = File('${cacheDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String _remoteFileName(NotificationMessage message, Uri uri) {
    final raw = message.fileName?.trim();
    if (raw != null && raw.isNotEmpty) {
      return _sanitizeFileName(raw);
    }
    if (uri.pathSegments.isNotEmpty) {
      return _sanitizeFileName(uri.pathSegments.last);
    }
    return _buildFileName(message, null);
  }

  static String? _extensionFromMime(String? mime) {
    if (mime == null) return null;
    final lower = mime.toLowerCase();
    const mapping = <String, String>{
      'image/jpeg': 'jpg',
      'image/jpg': 'jpg',
      'image/png': 'png',
      'image/gif': 'gif',
      'image/bmp': 'bmp',
      'image/webp': 'webp',
      'image/heic': 'heic',
      'image/heif': 'heif',
      'application/pdf': 'pdf',
      'application/msword': 'doc',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'docx',
      'application/vnd.ms-excel': 'xls',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'xlsx',
      'application/vnd.ms-powerpoint': 'ppt',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'pptx',
      'text/plain': 'txt',
      'text/csv': 'csv',
    };
    if (mapping.containsKey(lower)) {
      return mapping[lower];
    }
    if (lower.startsWith('image/')) {
      return lower.substring(6);
    }
    if (lower.startsWith('text/')) {
      return lower.substring(5);
    }
    return null;
  }

  static String? _mimeFromExtension(String nameOrExtension) {
    final ext = nameOrExtension.contains('.')
        ? nameOrExtension.substring(nameOrExtension.lastIndexOf('.') + 1)
        : nameOrExtension;
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
    }
    return null;
  }

  static void _showError(String title, String message) {
    final context = Get.context;
    if (context == null) {
      debugPrint('$title: $message');
      return;
    }
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? Colors.redAccent.withOpacity(0.85) : Colors.redAccent.withOpacity(0.92);
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: background,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
