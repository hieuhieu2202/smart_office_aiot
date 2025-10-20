import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:screen_capturer/screen_capturer.dart';

class ScreenCaptureException implements Exception {
  ScreenCaptureException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ScreenCaptureException($code, $message)';
}

class ScreenCaptureService {
  ScreenCaptureService({ScreenCapturer? capturer})
      : _capturer = capturer ?? ScreenCapturer.instance;

  final ScreenCapturer _capturer;

  Future<File> captureJpeg({required String fileName}) async {
    final sanitized = fileName.trim().isEmpty ? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg' : fileName.trim();
    final directory = await getTemporaryDirectory();
    final jpgPath = p.join(directory.path, sanitized);
    final pngPath = p.setExtension(jpgPath, '.png');

    try {
      final captured = await _capturer.capture(
        mode: CaptureMode.screen,
        imagePath: pngPath,
        copyToClipboard: false,
        silent: true,
      );

      if (captured == null || captured.imageBytes == null) {
        throw ScreenCaptureException('capture_failed', 'Không thể chụp màn hình');
      }

      final decoded = img.decodeImage(captured.imageBytes!);
      if (decoded == null) {
        throw ScreenCaptureException('decode_failed', 'Không thể đọc dữ liệu màn hình');
      }

      final jpgBytes = img.encodeJpg(decoded, quality: 90);
      final file = File(jpgPath);
      await file.writeAsBytes(jpgBytes);

      final pngFile = File(pngPath);
      if (pngFile.existsSync()) {
        await pngFile.delete();
      }

      return file;
    } on PlatformException catch (error) {
      throw ScreenCaptureException(
        error.code ?? 'platform_error',
        error.message ?? 'Không thể chụp màn hình',
      );
    } on ScreenCaptureException {
      rethrow;
    } catch (error) {
      throw ScreenCaptureException('capture_failed', '$error');
    }
  }
}
