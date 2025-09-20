import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../config/Apiconfig.dart';
import '../model/notification_message.dart';
import '../model/version_check_summary.dart';

class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

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
    // _log('Bắt đầu kiểm tra cập nhật và hiển thị thông báo nếu cần.');
    if (!Platform.isAndroid) {
      // Luồng cài đặt hiện tại chỉ hỗ trợ Android (APK)
      // _log('Thiết bị không phải Android (${Platform.operatingSystem}), bỏ qua kiểm tra.');
      return initialSummary;
    }

    try {
      VersionCheckSummary? summary = initialSummary;
      if (summary != null) {
        // _log(
        //   'Sử dụng dữ liệu kiểm tra phiên bản đã có: '
        //   'display=${summary.displayVersion}, '
        //   'installed=${summary.installedVersion}, '
        //   'server=${summary.serverVersion ?? 'n/a'}, '
        //   'update=${summary.updateAvailable}.',
        // );
      } else {
        summary = await fetchVersionSummary();
      }

      if (summary == null) {
        // _log('Không nhận được thông tin phiên bản từ server.');
        return null;
      }

      final VersionCheckSummary resolvedSummary = summary;

      if (!resolvedSummary.updateAvailable) {
        // _log(
        //   'Không có bản cập nhật mới. Phiên bản hiện tại: '
        //   '${resolvedSummary.installedVersion}.',
        // );
        return resolvedSummary;
      }

      final downloadUrl = resolvedSummary.downloadUrl;
      if (downloadUrl == null || downloadUrl.isEmpty) {
        // _log('Server báo có cập nhật nhưng không có đường dẫn tải.');
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
                  Text(
                    'Phiên bản trên máy: ${resolvedSummary.installedVersion}',
                  ),
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
        final _UpdateCache promptCache =
            _UpdateCache(ApiConfig.notificationAppKey, resolvedSummary.platform);
        final String? expectedVersion = resolvedSummary.effectiveLatestVersion ??
            resolvedSummary.serverVersion ??
            resolvedSummary.serverCurrentVersion;
        if (expectedVersion != null && expectedVersion.trim().isNotEmpty) {
          try {
            await promptCache.writePendingVersion(expectedVersion);
          } catch (error, stackTrace) {
            // _log('Không thể lưu phiên bản dự kiến: $error',
            //     error: error, stackTrace: stackTrace);
          }
        }
        // _log('Người dùng đồng ý cập nhật, bắt đầu tải file.');
        await _downloadAndInstall(context, downloadUrl);
      } else {
        // _log('Người dùng từ chối cập nhật hoặc dialog bị đóng.');
      }

      // _log('Hoàn tất quy trình kiểm tra cập nhật.');
      return resolvedSummary;
    } on UpdateCheckException catch (error, stackTrace) {
      // _log('Lỗi khi kiểm tra cập nhật: ${error.message}',
      //     error: error.cause ?? error, stackTrace: stackTrace);
      // Bỏ qua lỗi kiểm tra phiên bản để không chặn luồng khởi động ứng dụng
      return initialSummary;
    } on Exception catch (error, stackTrace) {
      // _log('Lỗi khi kiểm tra cập nhật: $error',
      //     error: error, stackTrace: stackTrace);
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

    final _UpdateCache cache =
        _UpdateCache(ApiConfig.notificationAppKey, resolvedPlatform);
    final String? cachedInstalled = cache.readInstalledVersion();
    final String? cachedPending =
        cache.readPendingVersion(); // phiên bản đã tải nhưng chưa xác nhận
    final int? cachedBuildNumber = cache.readBuildNumber();
    final int? currentBuildNumber = _tryParseInt(info.buildNumber);

    final List<String?> candidates = <String?>[
      overrideCurrentVersion,
      info.version,
      info.buildNumber,
      cachedInstalled,
    ];
    String? rawCurrentVersion;
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        rawCurrentVersion = candidate.trim();
        break;
      }
    }

    var sanitizedCurrentVersion = _coerceVersion(rawCurrentVersion);
    var initialDisplayVersion = sanitizeVersionForDisplay(rawCurrentVersion);

    final String? normalizedCachedInstalled =
        _normalizeVersion(cachedInstalled);
    final String? normalizedPendingVersion = _normalizeVersion(cachedPending);
    if (normalizedCachedInstalled != null &&
        normalizedCachedInstalled.isNotEmpty &&
        _compareVersions(normalizedCachedInstalled, sanitizedCurrentVersion) >
            0) {
      sanitizedCurrentVersion = normalizedCachedInstalled;
      initialDisplayVersion = sanitizeVersionForDisplay(normalizedCachedInstalled);
    }

    if (normalizedPendingVersion != null &&
        normalizedPendingVersion.isNotEmpty &&
        _compareVersions(normalizedPendingVersion, sanitizedCurrentVersion) >
            0) {
      sanitizedCurrentVersion = normalizedPendingVersion;
      initialDisplayVersion = sanitizeVersionForDisplay(normalizedPendingVersion);
    }

    // _log(
    //   'Chuẩn bị gọi API kiểm tra phiên bản: '
    //   'currentVersion=$sanitizedCurrentVersion (raw=${rawCurrentVersion ?? 'n/a'}), '
    //   'display=$initialDisplayVersion, '
    //   'platform=$resolvedPlatform, '
    //   'build=${currentBuildNumber ?? 'n/a'}, '
    //   'cachedInstalled=${normalizedCachedInstalled ?? cachedInstalled ?? 'n/a'}, '
    //   'pending=${normalizedPendingVersion ?? cachedPending ?? 'n/a'}, '
    //   'cachedBuild=${cachedBuildNumber ?? 'n/a'}',
    // );

    if (!Platform.isAndroid && resolvedPlatform.toLowerCase() == 'android') {
      // _log('Thiết bị không phải Android nhưng platform=android, trả về bản tóm tắt mặc định.');
      return VersionCheckSummary(
        currentVersion: initialDisplayVersion,
        installedVersion: sanitizedCurrentVersion,
        platform: resolvedPlatform,
        updateAvailable: false,
        serverVersion: initialDisplayVersion,
        serverCurrentVersion: initialDisplayVersion,
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
        final preview = _previewBody(response.body);
        final message =
            'Không thể kiểm tra cập nhật: máy chủ trả về mã ${response.statusCode}.';
        // _log(
        //   'Lỗi kiểm tra phiên bản (mã ${response.statusCode}). Body: $preview',
        // );
        throw UpdateCheckException(message);
      }

      final body = response.body.trim();
      // _log('Phản hồi kiểm tra phiên bản: ${_previewBody(body)}');

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

      final String? serverCurrentVersionRaw = _readString(
        decoded,
        const [
          'currentVersion',
          'CurrentVersion',
          'installedVersion',
          'InstalledVersion',
          'appVersion',
          'AppVersion',
        ],
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

      final String? serverVersionCandidate = _firstNonEmpty([
        serverVersionRaw,
        latestRelease?.versionName,
      ]);
      final String? normalizedServerVersion =
          _normalizeVersion(serverVersionCandidate);
      final String? normalizedReleaseVersion = latestRelease?.versionName != null
          ? _normalizeVersion(latestRelease!.versionName)
          : null;

      final String? normalizedServerCurrentVersion =
          _normalizeVersion(serverCurrentVersionRaw);
      final String? comparisonTarget = _firstNonEmpty([
        normalizedServerVersion,
        normalizedReleaseVersion,
        normalizedServerCurrentVersion,
      ]);

      int? versionComparison;
      if (comparisonTarget != null && comparisonTarget.isNotEmpty) {
        versionComparison =
            _compareVersions(sanitizedCurrentVersion, comparisonTarget);
        _log(
          'Kết quả so sánh phiên bản: local=$sanitizedCurrentVersion, '
          'target=$comparisonTarget, compare=$versionComparison',
        );
      }

      var effectiveUpdateAvailable = updateAvailable;
      if (versionComparison != null) {
        if (versionComparison < 0) {
          if (!updateAvailable) {
            // _log(
            //   'Phiên bản hiện tại ($sanitizedCurrentVersion) nhỏ hơn '
            //   '$comparisonTarget, bật cờ cập nhật.',
            // );
          }
          effectiveUpdateAvailable = true;
        } else {
          if (updateAvailable) {
            // _log(
            //   'Server báo có cập nhật nhưng phiên bản hiện tại '
            //   '($sanitizedCurrentVersion) không nhỏ hơn $comparisonTarget. '
            //   'Bỏ qua cờ cập nhật.',
            // );
          }
          effectiveUpdateAvailable = false;
        }
      }

      final String? normalizedMinSupported = _normalizeVersion(minSupported);
      if (normalizedMinSupported != null) {
        final minComparison =
            _compareVersions(sanitizedCurrentVersion, normalizedMinSupported);
        if (minComparison < 0 && !effectiveUpdateAvailable) {
          // _log(
          //   'Phiên bản hiện tại ($sanitizedCurrentVersion) thấp hơn mức tối thiểu '
          //   '$normalizedMinSupported, bật cờ cập nhật.',
          // );
          effectiveUpdateAvailable = true;
        }
      }

      var resolvedInstalledVersion = sanitizedCurrentVersion;
      var resolvedDisplayVersion =
          sanitizeVersionForDisplay(resolvedInstalledVersion);

      if (!effectiveUpdateAvailable) {
        final bool preferServerDisplay =
            versionComparison == null || versionComparison <= 0;
        if (preferServerDisplay) {
          final String? displayCandidate = _firstNonEmpty([
            serverCurrentVersionRaw,
            serverVersionCandidate,
            latestRelease?.versionName,
          ]);
          if (displayCandidate != null) {
            resolvedDisplayVersion =
                sanitizeVersionForDisplay(displayCandidate);
          }
        }
      }

      final String? serverVersionDisplay = _sanitizeVersionOrNull(
            serverVersionCandidate,
          ) ??
          _sanitizeVersionOrNull(latestRelease?.versionName) ??
          _sanitizeVersionOrNull(normalizedServerVersion) ??
          _sanitizeVersionOrNull(comparisonTarget);

      final String? serverCurrentDisplay =
          _sanitizeVersionOrNull(serverCurrentVersionRaw) ??
              _sanitizeVersionOrNull(normalizedServerCurrentVersion);

      final bool buildAdvanced = cachedBuildNumber != null &&
          currentBuildNumber != null &&
          currentBuildNumber > cachedBuildNumber;

      if (buildAdvanced && effectiveUpdateAvailable) {
        // _log(
        //   'Build number đã tăng từ $cachedBuildNumber lên $currentBuildNumber, '
        //   'coi như bản cập nhật đã được cài đặt.',
        // );
        effectiveUpdateAvailable = false;
        final String? promotedVersion = normalizedServerVersion ??
            normalizedReleaseVersion ??
            normalizedServerCurrentVersion ??
            _normalizeVersion(serverVersionCandidate) ??
            resolvedInstalledVersion;
        if (promotedVersion != null && promotedVersion.isNotEmpty) {
          resolvedInstalledVersion = promotedVersion;
        }
        resolvedDisplayVersion = sanitizeVersionForDisplay(
          latestRelease?.versionName ??
              serverCurrentVersionRaw ??
              serverVersionCandidate ??
              promotedVersion ??
              resolvedInstalledVersion,
        );
      }

      // _log(
      //   'Tổng hợp phiên bản: installed=$resolvedInstalledVersion, '
      //   'display=$resolvedDisplayVersion, server=${serverVersionDisplay ?? 'n/a'}, '
      //   'update=$effectiveUpdateAvailable, compare=${versionComparison ?? 'n/a'}, '
      //   'build=${currentBuildNumber ?? 'n/a'} (cache=${cachedBuildNumber ?? 'n/a'})',
      // );

      final summary = VersionCheckSummary(
        currentVersion: resolvedDisplayVersion,
        installedVersion: resolvedInstalledVersion,
        platform: resolvedPlatform,
        updateAvailable: effectiveUpdateAvailable,
        serverVersion: serverVersionDisplay,
        serverCurrentVersion: serverCurrentDisplay,
        minSupported: minSupported,
        notes: notes,
        downloadUrl: downloadUrl,
        latestRelease: latestRelease,
      );

      try {
        final String? resolvedNormalized =
            _normalizeVersion(resolvedInstalledVersion) ??
                (resolvedInstalledVersion.isNotEmpty
                    ? resolvedInstalledVersion
                    : null);
        String? installedCandidate = resolvedNormalized;
        if (normalizedPendingVersion != null &&
            normalizedPendingVersion.isNotEmpty &&
            installedCandidate != null &&
            _compareVersions(normalizedPendingVersion, installedCandidate) >
                0) {
          installedCandidate = normalizedPendingVersion;
        }

        await cache.writeInstalledVersion(installedCandidate);
        if (!effectiveUpdateAvailable) {
          await cache.clearPendingVersion();
        }
        if (currentBuildNumber != null) {
          await cache.writeBuildNumber(currentBuildNumber);
        }
      } catch (error, stackTrace) {
        // _log('Không thể lưu cache phiên bản: $error',
        //     error: error, stackTrace: stackTrace);
      }

      return summary;
    } on TimeoutException catch (error, stackTrace) {
      const message =
          'Hết thời gian chờ (20s) khi kết nối tới máy chủ kiểm tra phiên bản.';
      // _log(message, error: error, stackTrace: stackTrace);
      throw const UpdateCheckException(message);
    } on SocketException catch (error, stackTrace) {
      const message =
          'Không thể kết nối tới máy chủ kiểm tra cập nhật. Vui lòng kiểm tra mạng.';
      // _log(message, error: error, stackTrace: stackTrace);
      throw const UpdateCheckException(message);
    } on http.ClientException catch (error, stackTrace) {
      final detail = error.message.isNotEmpty
          ? error.message
          : 'Lỗi kết nối không xác định.';
      final message = 'Kết nối kiểm tra cập nhật gặp sự cố: $detail';
      // _log(message, error: error, stackTrace: stackTrace);
      throw UpdateCheckException(message, error);
    } on HttpException catch (error, stackTrace) {
      final message =
          'Máy chủ từ chối yêu cầu kiểm tra cập nhật: ${error.message}';
      // _log(message, error: error, stackTrace: stackTrace);
      throw UpdateCheckException(message, error);
    } on FormatException catch (error, stackTrace) {
      final message = 'Dữ liệu phản hồi không hợp lệ: ${error.message}';
      // _log(message, error: error, stackTrace: stackTrace);
      throw UpdateCheckException(message, error);
    } catch (error, stackTrace) {
      const message = 'Đã xảy ra lỗi không xác định khi kiểm tra phiên bản.';
      // _log(message, error: error, stackTrace: stackTrace);
      throw UpdateCheckException(message, error);
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
      // _log('Bắt đầu tải gói cập nhật từ $url tới $filePath');
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
      // _log('Đã tải xong gói cập nhật: $filePath');
    } finally {
      if (_isContextMounted(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    // _log('Mở file cài đặt: $filePath');
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

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  static String? _sanitizeVersionOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final normalized = _normalizeVersion(trimmed);
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    return trimmed;
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

  static int? _tryParseInt(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
}

class _UpdateCache {
  _UpdateCache(this.appKey, this.platform)
      : _platformKey = platform.toLowerCase().trim();

  final String appKey;
  final String platform;
  final String _platformKey;

  static final GetStorage _box = GetStorage();

  String _key(String suffix) =>
      'update_cache:$appKey:${_platformKey.isEmpty ? 'default' : _platformKey}:$suffix';

  String? readInstalledVersion() {
    final dynamic value = _box.read(_key('installed'));
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  int? readBuildNumber() {
    final dynamic value = _box.read(_key('build'));
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Future<void> writeInstalledVersion(String? version) async {
    final String? normalized = UpdateService._normalizeVersion(version);
    if (normalized == null || normalized.isEmpty) {
      await _box.remove(_key('installed'));
      return;
    }

    final String? current = readInstalledVersion();
    if (current != null) {
      final String? currentNormalized =
          UpdateService._normalizeVersion(current);
      if (currentNormalized != null &&
          UpdateService._compareVersions(currentNormalized, normalized) >= 0) {
        return;
      }
    }

    await _box.write(_key('installed'), normalized);
  }

  /// Phiên bản mới nhất mà người dùng đã đồng ý cài đặt trong phiên hiện tại.
  ///
  /// Được dùng để hiển thị chính xác số phiên bản ngay cả khi app chưa cập nhật
  /// được `PackageInfo` (ví dụ build mới có cùng versionName).
  String? readPendingVersion() {
    final dynamic value = _box.read(_key('pending'));
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  Future<void> writePendingVersion(String? version) async {
    final String? normalized = UpdateService._normalizeVersion(version);
    if (normalized == null || normalized.isEmpty) {
      await clearPendingVersion();
      return;
    }

    final String? current = readPendingVersion();
    if (current != null) {
      final String? currentNormalized =
          UpdateService._normalizeVersion(current);
      if (currentNormalized != null &&
          UpdateService._compareVersions(currentNormalized, normalized) >= 0) {
        return;
      }
    }

    await _box.write(_key('pending'), normalized);
  }

  Future<void> clearPendingVersion() async {
    await _box.remove(_key('pending'));
  }

  Future<void> writeBuildNumber(int? buildNumber) async {
    if (buildNumber == null) return;
    await _box.write(_key('build'), buildNumber);
  }
}
