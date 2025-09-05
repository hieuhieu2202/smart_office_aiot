import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static const String versionUrl =
      'https://10.220.130.117:5555/AppUpdate/Version';

  /// Gọi ở Splash kiểm tra và hỏi người dùng có muốn cập nhật không
  Future<void> checkAndPrompt(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;

      final resp = await http.get(Uri.parse(versionUrl));
      if (resp.statusCode != 200) return;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final latestCode = (data['versionCode'] as num?)?.toInt() ?? 0;
      final apkUrl = data['apkUrl'] as String?;
      final changelog = (data['changelog'] as String?) ?? '';

      if (apkUrl != null && latestCode > currentCode) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Có bản cập nhật mới'),
            content: SingleChildScrollView(child: Text(changelog)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cập nhật')),
            ],
          ),
        );
        if (confirm == true) {
          await _downloadAndInstall(context, apkUrl);
        }
      }
    } catch (_) {
    }
  }

  /// Tải file APK về thư mục app và mở trình cài đặt
  Future<void> _downloadAndInstall(BuildContext context, String url) async {
    final dir = await getExternalStorageDirectory(); // app-specific external dir
    final savedDir = dir?.path ?? '/sdcard/Download';
    final fileName = Uri.parse(url).pathSegments.last;
    final filePath = '$savedDir/$fileName';

    final dio = Dio();

    double progress = 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Đang tải cập nhật'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: progress == 0 ? null : progress),
              const SizedBox(height: 12),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ),
    );

    try {
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (recv, total) {
          if (total > 0) {
            progress = recv / total;
            // ignore: use_build_context_synchronously
            (Navigator.of(context).overlay!.context as Element).markNeedsBuild();
          }
        },
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 2),
        ),
      );
    } finally {
      Navigator.of(context, rootNavigator: true).pop();
    }

    await OpenFilex.open(filePath);
  }
}
