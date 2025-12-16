import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';

class ImageHelper {
  /// Convert ảnh XFile → Base64
  static Future<String> toBase64(XFile file) async {
    final bytes = await File(file.path).readAsBytes();
    return base64Encode(bytes);
  }
}
