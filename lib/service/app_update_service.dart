import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../model/app_version_info.dart';
import '../model/notification_message.dart';

class AppUpdateService {
  static const String _baseUrl =
      'http://10.220.130.117:2222/SendNoti/api/Control/';
  static const String _root = 'http://10.220.130.117:2222/SendNoti';

  static Future<AppVersionInfo?> fetchManifest() async {
    final Uri url = Uri.parse('${_baseUrl}app-version');
    debugPrint('[AppUpdateService] Fetching manifest…');
    final http.Response res = await http.get(url);
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

  static bool _isInstallable(String? url) {
    if (url == null) return false;
    return url.toLowerCase().endsWith('.apk') || url.toLowerCase().endsWith('.ipa');
  }

  static Uri _resolve(String fileUrl) {
    if (fileUrl.startsWith('http')) {
      return Uri.parse(fileUrl);
    }
    final String normalized = fileUrl.startsWith('/') ? fileUrl : '/$fileUrl';
    return Uri.parse('$_root$normalized');
  }

  /// Handle a notification that might contain an app update file.
  /// If an installable file is found, launch it and return true.
  static Future<bool> handleNotification(NotificationMessage n) async {
    final String? url = n.fileUrl;
    if (!_isInstallable(url)) return false;
    if (!Platform.isAndroid) return false;

    final Uri fileUri = _resolve(url!);
    debugPrint('[AppUpdateService] Downloading update ${fileUri.toString()}');
    try {
      final http.Response res = await http.get(fileUri);
      if (res.statusCode != 200) {
        debugPrint('[AppUpdateService] Download failed: ${res.statusCode}');
        return false;
      }
      final dir = await getTemporaryDirectory();
      final name = fileUri.pathSegments.isNotEmpty
          ? fileUri.pathSegments.last
          : 'update.apk';
      final File file = File('${dir.path}/$name');
      await file.writeAsBytes(res.bodyBytes);
      final Uri launchUri = Uri.file(file.path);
      debugPrint('[AppUpdateService] Launching installer ${launchUri.toString()}');
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Error: $e');
    }
    return false;
  }
}
