import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

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

  static const String _defaultInitialVersion = '1.1.0';

  /// Gọi để kiểm tra và hỏi người dùng có muốn cập nhật không.
  ///
  /// [initialSummary] cho phép truyền kết quả đã có sẵn (ví dụ được lấy ở
  /// màn splash) để tránh việc gọi lại API nếu không cần thiết.
  Future<VersionCheckSummary?> checkAndPrompt(
    BuildContext context, {
    VersionCheckSummary? initialSummary,
  }) async {
    _log('Bắt đầu kiểm tra cập nhật và hiển thị thông báo nếu cần.');
    if (!Platform.isAndroid) {
      // Luồng cài đặt hiện tại chỉ hỗ trợ Android (APK)
      _log('Thiết bị không phải Android (${Platform.operatingSystem}), bỏ qua kiểm tra.');
      return initialSummary;
    }

    try {
      VersionCheckSummary? summary = initialSummary;
      if (summary != null) {
        _log(
          'Sử dụng dữ liệu kiểm tra phiên bản đã có: '
          'current=${summary.currentVersion}, '
          'server=${summary.serverVersion ?? 'n/a'}, '
          'update=${summary.updateAvailable}.',
        );
      } else {
        summary = await fetchVersionSummary();
      }

      if (summary == null) {
        _log('Không nhận được thông tin phiên bản từ server.');
        return null;
      }

      final VersionCheckSummary resolvedSummary = summary;

      if (!resolvedSummary.updateAvailable) {
        _log(
          'Không có bản cập nhật mới. Phiên bản hiện tại: '
          '${resolvedSummary.currentVersion}.',
        );
        return resolvedSummary;
      }

      final downloadUrl = resolvedSummary.downloadUrl;
      if (downloadUrl == null || downloadUrl.isEmpty) {
        _log('Server báo có cập nhật nhưng không có đường dẫn tải.');
        return resolvedSummary;
      }

      if (!_isContextMounted(context)) return resolvedSummary;

      final String? serverVersion = resolvedSummary.effectiveLatestVersion;
      final String changelog = resolvedSummary.releaseNotes ?? '';
      final String checksum = resolvedSummary.checksum ?? '';

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
                  Text('Phiên bản hiện tại: ${resolvedSummary.currentVersion}'),
                  if (serverVersion != null && serverVersion.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Phiên bản mới: $serverVersion',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                  ),
                  if (resolvedSummary.minSupported != null &&
                      resolvedSummary.minSupported!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Yêu cầu tối thiểu: ${resolvedSummary.minSupported}'),
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
        _log('Người dùng đồng ý cập nhật, bắt đầu tải file.');
        await _downloadAndInstall(context, downloadUrl);
      } else {
        _log('Người dùng từ chối cập nhật hoặc dialog bị đóng.');
      }

      _log('Hoàn tất quy trình kiểm tra cập nhật.');
      return resolvedSummary;
    } on Exception catch (error, stackTrace) {
      _log('Lỗi khi kiểm tra cập nhật: $error',
          error: error, stackTrace: stackTrace);
      // Bỏ qua lỗi kiểm tra phiên bản để không chặn luồng khởi động ứng dụng
      return initialSummary;
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

    final List<String?> candidates = <String?>[
      overrideCurrentVersion,
      info.version,
      info.buildNumber,
    ];
    String? rawCurrentVersion;
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        rawCurrentVersion = candidate.trim();
        break;
      }
    }

    final String sanitizedCurrentVersion = _coerceVersion(rawCurrentVersion);
    final String displayCurrentVersion =
        sanitizeVersionForDisplay(rawCurrentVersion);

    _log(
      'Chuẩn bị gọi API kiểm tra phiên bản: '
      'currentVersion=$sanitizedCurrentVersion (raw=${rawCurrentVersion ?? 'n/a'}), '
      'display=$displayCurrentVersion, '
      'platform=$resolvedPlatform',
    );

    if (!Platform.isAndroid && resolvedPlatform.toLowerCase() == 'android') {
      _log('Thiết bị không phải Android nhưng platform=android, trả về bản tóm tắt mặc định.');
      return VersionCheckSummary(
        currentVersion: displayCurrentVersion,
        platform: resolvedPlatform,
        updateAvailable: false,
        serverVersion: displayCurrentVersion,
        minSupported: null,
        notes: null,
        downloadUrl: null,
        latestRelease: null,
      );
    }

    final client = http.Client();
    try {
      final uri = _uri('/api/Control/check-app-version', {
        'appKey': ApiConfig.notificationAppKey,
        'currentVersion': sanitizedCurrentVersion,
        'platform': resolvedPlatform,
      });
      final stopwatch = Stopwatch()..start();
      _log('GET $uri');
      final response = await client
          .get(
            uri,
            headers: {HttpHeaders.acceptHeader: 'application/json'},
          )
          .timeout(const Duration(seconds: 20));
      stopwatch.stop();
      _log(
        'GET $uri trả về ${response.statusCode} sau '
        '${stopwatch.elapsedMilliseconds}ms',
      );

      if (response.statusCode != HttpStatus.ok) {
        _log(
          'Lỗi kiểm tra phiên bản (mã ${response.statusCode}). '
          'Body: ${_previewBody(response.body)}',
        );
        throw Exception(
          'Không thể kiểm tra cập nhật (mã ${response.statusCode}).',
        );
      }

      final body = response.body.trim();
      _log('Phản hồi kiểm tra phiên bản: ${_previewBody(body)}');

      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Dữ liệu phản hồi không hợp lệ');
      }

      var updateAvailable =
          _readBool(decoded, const ['updateAvailable', 'UpdateAvailable']);

      final NotificationAppVersion? latestRelease =
          NotificationAppVersion.maybeFrom(
        decoded['latestRelease'] ?? decoded['LatestRelease'],
      );

      final String? serverVersionRaw = _readString(
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

      final String? serverVersionCandidate =
          (serverVersionRaw != null && serverVersionRaw.trim().isNotEmpty)
              ? serverVersionRaw.trim()
              : latestRelease?.versionName;
      final String? normalizedServerVersion =
          _normalizeVersion(serverVersionCandidate);

      if (!updateAvailable && normalizedServerVersion != null) {
        final comparison = _compareVersions(
          sanitizedCurrentVersion,
          normalizedServerVersion,
        );
        _log(
          'Kết quả so sánh phiên bản: local=$sanitizedCurrentVersion, '
          'server=$normalizedServerVersion, compare=$comparison',
        );
        if (comparison < 0) {
          updateAvailable = true;
        }
      }

      return VersionCheckSummary(
        currentVersion: displayCurrentVersion,
        platform: resolvedPlatform,
        updateAvailable: updateAvailable,
        serverVersion:
            normalizedServerVersion ?? serverVersionCandidate ?? serverVersionRaw,
        minSupported: minSupported,
        notes: notes,
        downloadUrl: downloadUrl,
        latestRelease: latestRelease,
      );
    } on FormatException catch (e, stackTrace) {
      _log('Dữ liệu kiểm tra phiên bản không hợp lệ: ${e.message}',
          error: e, stackTrace: stackTrace);
      throw Exception('Dữ liệu phản hồi không hợp lệ: ${e.message}');
    } catch (error, stackTrace) {
      _log('Lỗi không xác định khi kiểm tra phiên bản: $error',
          error: error, stackTrace: stackTrace);
      rethrow;
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
      _log('Bắt đầu tải gói cập nhật từ $url tới $filePath');
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
      _log('Đã tải xong gói cập nhật: $filePath');
    } finally {
      if (_isContextMounted(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    _log('Mở file cài đặt: $filePath');
    await OpenFilex.open(filePath);
  }

  static void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'UpdateService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _coerceVersion(String? value) {
    final normalized = _normalizeVersion(value);
    return normalized ?? _defaultInitialVersion;
  }

  static String sanitizeVersionForDisplay(String? value) {
    final normalized = _normalizeVersion(value);
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return _defaultInitialVersion;
  }

  static String? _normalizeVersion(String? value) {
    if (value == null) return null;
    var trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('v') || trimmed.startsWith('V')) {
      trimmed = trimmed.substring(1).trim();
    }
    final plusIndex = trimmed.indexOf('+');
    if (plusIndex != -1) {
      trimmed = trimmed.substring(0, plusIndex).trim();
    }
    final dashIndex = trimmed.indexOf('-');
    if (dashIndex != -1) {
      trimmed = trimmed.substring(0, dashIndex).trim();
    }
    final match = RegExp(r'\d+(?:\.\d+)*').firstMatch(trimmed);
    if (match != null) {
      return match.group(0);
    }
    return trimmed.isNotEmpty ? trimmed : null;
  }

  static int _compareVersions(String a, String b) {
    final partsA = _versionParts(a);
    final partsB = _versionParts(b);
    final maxLength = partsA.length > partsB.length ? partsA.length : partsB.length;
    for (var i = 0; i < maxLength; i++) {
      final int partA = i < partsA.length ? partsA[i] : 0;
      final int partB = i < partsB.length ? partsB[i] : 0;
      if (partA != partB) {
        return partA.compareTo(partB);
      }
    }
    return 0;
  }

  static List<int> _versionParts(String version) {
    final matches = RegExp(r'\d+').allMatches(version);
    final parts = <int>[];
    for (final match in matches) {
      final value = match.group(0);
      if (value == null) continue;
      final parsed = int.tryParse(value);
      if (parsed != null) {
        parts.add(parsed);
      }
    }
    if (parts.isEmpty) {
      final fallback = int.tryParse(version);
      if (fallback != null) {
        parts.add(fallback);
      }
    }
    return parts;
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
