import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../model/app_version_info.dart';
import '../model/notification_message.dart';

class AppUpdateService {
  static const String _baseUrl = 'https://localhost:7283/api/control/';
  static const String _root = 'https://localhost:7283';

  static final http.Client _client = IOClient(
    HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true,
  );

  static Future<AppVersionInfo?> fetchManifest() async {
    final Uri url = Uri.parse('${_baseUrl}app-version');
    debugPrint('[AppUpdateService] Fetching manifest…');
    final http.Response res = await _client.get(url);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return AppVersionInfo.fromJson(json.decode(res.body));
    }
    debugPrint('[AppUpdateService] Manifest fetch failed: ${res.statusCode}');
    return null;
  }

  static Future<void> downloadLatest(String platform) async {
    final Uri url =
        Uri.parse('${_baseUrl}app-version/download?platform=$platform');
    debugPrint('[AppUpdateService] Launching $url');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static bool isInstallable(String? pathOrUrl) {
    if (pathOrUrl == null) return false;
    final String lower = pathOrUrl.toLowerCase();
    return lower.endsWith('.apk') || lower.endsWith('.ipa');
  }

  static Uri resolveFileUrl(String fileUrl) {
    if (fileUrl.startsWith('http')) {
      return Uri.parse(fileUrl);
    }
    final String normalized = fileUrl.startsWith('/') ? fileUrl : '/$fileUrl';
    return Uri.parse('$_root$normalized');
  }

  /// Handle a notification that might contain an app update file.
  /// If an installable file is found, launch it and return true.
  static Future<File?> loadFile(NotificationMessage n) async {
    try {
      if (n.fileUrl != null && n.fileUrl!.isNotEmpty) {
        final Uri fileUri = resolveFileUrl(n.fileUrl!);
        final http.Response res = await _client.get(fileUri);
        if (res.statusCode != 200) {
          debugPrint('[AppUpdateService] Download failed: ${res.statusCode}');
          return null;
        }
        final dir = await getTemporaryDirectory();
        final String name = n.fileName ??
            (fileUri.pathSegments.isNotEmpty
                ? fileUri.pathSegments.last
                : 'file');
        final File file = File('${dir.path}/$name');
        await file.writeAsBytes(res.bodyBytes);
        return file;
      } else if (n.fileBase64 != null && n.fileBase64!.isNotEmpty) {
        final dir = await getTemporaryDirectory();
        final String name = n.fileName ?? 'file';
        final File file = File('${dir.path}/$name');
        String data = n.fileBase64!;
        final int comma = data.indexOf(',');
        if (data.startsWith('data:') && comma != -1) {
          data = data.substring(comma + 1);
        }
        await file.writeAsBytes(base64.decode(data));
        return file;
      }
    } catch (e) {
      debugPrint('[AppUpdateService] File fetch error: $e');
    }
    return null;
  }

  static Future<bool> handleNotification(NotificationMessage n) async {
    final String? source = n.fileUrl ?? n.fileName;
    if (!isInstallable(source)) return false;
    if (!Platform.isAndroid) return false;

    final File? file = await loadFile(n);
    if (file == null) return false;
    debugPrint('[AppUpdateService] Launching installer ${file.path}');
    final result = await OpenFilex.open(file.path);
    return result.type == ResultType.done;
  }
}
