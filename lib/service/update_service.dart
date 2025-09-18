import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../config/Apiconfig.dart';
import '../model/notification_message.dart';
import '../model/version_check_summary.dart';

class UpdateService {
  const UpdateService();

  /// Gọi ở Splash kiểm tra và hỏi người dùng có muốn cập nhật không
  Future<VersionCheckSummary?> checkAndPrompt(BuildContext context) async {
    if (!Platform.isAndroid) {
      // Luồng cài đặt hiện tại chỉ hỗ trợ Android (APK)
      return null;
    }

    try {
      final summary = await fetchVersionSummary();
      if (summary == null) {
        return null;
      }

      if (!summary.updateAvailable) {
        return summary;
      }

      final downloadUrl = summary.downloadUrl;
      if (downloadUrl == null || downloadUrl.isEmpty) {
        return summary;
      }

      if (!_isContextMounted(context)) return summary;

      final String? serverVersion = summary.effectiveLatestVersion;
      final String changelog = summary.releaseNotes ?? '';
      final String checksum = summary.checksum ?? '';

      final bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Có bản cập nhật mới'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Phiên bản hiện tại: ${summary.currentVersion}'),
                  if (serverVersion != null && serverVersion.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Phiên bản mới: $serverVersion',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (summary.minSupported != null &&
                      summary.minSupported!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Yêu cầu tối thiểu: ${summary.minSupported}'),
                    ),
                  if (changelog.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(changelog),
                    ),
                  if (checksum.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('Checksum: $checksum'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Để sau'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Cập nhật'),
              ),
            ],
          );
        },
      );

      if (confirm == true && _isContextMounted(context)) {
        await _downloadAndInstall(context, downloadUrl);
      }

      return summary;
    } on Exception {
      // Bỏ qua lỗi kiểm tra phiên bản để không chặn luồng khởi động ứng dụng
      return null;
    }
  }

  Future<VersionCheckSummary?> fetchVersionSummary({
    String? overrideCurrentVersion,
    String platform = 'android',
  }) async {
    final info = await PackageInfo.fromPlatform();
    final String resolvedPlatform = platform.isNotEmpty
        ? platform
        : (Platform.isAndroid ? 'android' : Platform.operatingSystem);
    final String currentVersion = overrideCurrentVersion ??
        (info.version.isNotEmpty ? info.version : info.buildNumber);

    if (!Platform.isAndroid && resolvedPlatform.toLowerCase() == 'android') {
      return VersionCheckSummary(
        currentVersion: currentVersion,
        platform: resolvedPlatform,
        updateAvailable: false,
        serverVersion: currentVersion,
        minSupported: null,
        notes: null,
        downloadUrl: null,
        latestRelease: null,
      );
    }

    final client = http.Client();
    try {
      final response = await client
          .get(
            _uri('/api/Control/check-app-version', {
              'appKey': ApiConfig.notificationAppKey,
              'currentVersion': currentVersion,
              'platform': resolvedPlatform,
            }),
            headers: {HttpHeaders.acceptHeader: 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'Không thể kiểm tra cập nhật (mã ${response.statusCode}).',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Dữ liệu phản hồi không hợp lệ');
      }

      final updateAvailable =
          _readBool(decoded, const ['updateAvailable', 'UpdateAvailable']);

      final NotificationAppVersion? latestRelease =
          NotificationAppVersion.maybeFrom(
        decoded['latestRelease'] ?? decoded['LatestRelease'],
      );

      final String? serverVersion = _readString(
        decoded,
        const ['serverVersion', 'ServerVersion', 'latestVersion', 'LatestVersion'],
      );

      final String? minSupported = _readString(
        decoded,
        const [
          'minSupported',
          'MinSupported',
          'minimumSupported',
          'MinimumSupported',
          'minVersion',
          'MinVersion',
          'min_version',
        ],
      );

      final String? notes = _readString(
        decoded,
        const [
          'comparisonNote',
          'ComparisonNote',
          'notesVi',
          'NotesVi',
          'notes',
          'releaseNotes',
        ],
      );

      String? downloadUrl = _readString(
        decoded,
        const ['downloadUrl', 'DownloadUrl', 'fileUrl', 'FileUrl'],
      );

      downloadUrl ??= latestRelease?.fileUrl;

      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        downloadUrl = ApiConfig.normalizeNotificationUrl(downloadUrl);
      } else {
        downloadUrl = _uri(
          '/api/Control/app-version/download',
          {
            'appKey': ApiConfig.notificationAppKey,
            'platform': resolvedPlatform,
          },
        ).toString();
      }

      return VersionCheckSummary(
        currentVersion: currentVersion,
        platform: resolvedPlatform,
        updateAvailable: updateAvailable,
        serverVersion: serverVersion ?? latestRelease?.versionName,
        minSupported: minSupported,
        notes: notes,
        downloadUrl: downloadUrl,
        latestRelease: latestRelease,
      );
    } on FormatException catch (e) {
      throw Exception('Dữ liệu phản hồi không hợp lệ: ${e.message}');
    } finally {
      client.close();
    }
  }

  /// Tải file APK về thư mục app và mở trình cài đặt
  Future<void> _downloadAndInstall(BuildContext context, String url) async {
    if (!_isContextMounted(context)) return;

    final dir = await getExternalStorageDirectory(); // app-specific external dir
    final savedDir = dir?.path ?? '/sdcard/Download';
    final fileName = Uri.parse(url).pathSegments.isNotEmpty
        ? Uri.parse(url).pathSegments.last
        : 'update.apk';
    final filePath = '$savedDir/$fileName';

    final dio = Dio();

    double progress = 0;
    void Function(void Function())? updateDialog;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          updateDialog = setState;
          return AlertDialog(
            title: const Text('Đang tải cập nhật'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress <= 0 ? null : progress.clamp(0.0, 1.0)),
                const SizedBox(height: 12),
                Text('${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%'),
              ],
            ),
          );
        },
      ),
    );

    try {
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (recv, total) {
          if (total > 0) {
            final value = recv / total;
            updateDialog?.call(() {
              progress = value;
            });
          }
        },
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 2),
        ),
      );
    } finally {
      if (_isContextMounted(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    await OpenFilex.open(filePath);
  }

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = ApiConfig.notificationBaseUrl.endsWith('/')
        ? ApiConfig.notificationBaseUrl.substring(0, ApiConfig.notificationBaseUrl.length - 1)
        : ApiConfig.notificationBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$normalizedPath');
    if (query == null || query.isEmpty) {
      return uri;
    }
    final filtered = <String, String>{};
    query.forEach((key, value) {
      if (value == null) return;
      final stringValue = value.toString();
      if (stringValue.isEmpty) return;
      filtered[key] = stringValue;
    });
    return uri.replace(queryParameters: filtered);
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (!json.containsKey(key)) continue;
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lowered = value.toLowerCase();
        if (lowered == 'true' || lowered == '1' || lowered == 'yes') {
          return true;
        }
        if (lowered == 'false' || lowered == '0' || lowered == 'no') {
          return false;
        }
      }
    }
    return false;
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (!json.containsKey(key)) continue;
      final value = json[key];
      if (value == null) continue;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      } else {
        final stringValue = value.toString().trim();
        if (stringValue.isNotEmpty) return stringValue;
      }
    }
    return null;
  }

  static bool _isContextMounted(BuildContext context) {
    return context is Element && context.mounted;
  }
}
