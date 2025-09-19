import 'dart:io';
import 'dart:typed_data';

class NotificationAttachmentPayload {
  const NotificationAttachmentPayload.inline({
    required this.file,
    required this.bytes,
    required this.fileName,
    this.mimeType,
  })  : remoteUri = null;

  const NotificationAttachmentPayload.remote({
    required this.remoteUri,
    required this.fileName,
    this.mimeType,
  })  : file = null,
        bytes = null;

  final File? file;
  final Uint8List? bytes;
  final Uri? remoteUri;
  final String fileName;
  final String? mimeType;

  bool get isInline => file != null && bytes != null;
  bool get isRemote => remoteUri != null;

  bool get hasInlineImage => isInline && isImage;

  bool get isImage {
    final lowerMime = mimeType?.toLowerCase();
    if (lowerMime != null && lowerMime.startsWith('image/')) {
      return true;
    }
    final ext = extension?.toLowerCase();
    if (ext == null) return false;
    const imageExts = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'heic',
      'heif',
    };
    return imageExts.contains(ext);
  }

  String? get extension {
    final index = fileName.lastIndexOf('.');
    if (index == -1 || index == fileName.length - 1) {
      return null;
    }
    return fileName.substring(index + 1);
  }
}
