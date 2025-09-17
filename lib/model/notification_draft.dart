import 'dart:convert';

class NotificationDraft {
  NotificationDraft({
    this.id,
    required this.title,
    required this.body,
    this.link,
    this.targetVersion,
    DateTime? timestampUtc,
    this.attachment,
  }) : timestampUtc = (timestampUtc ?? DateTime.now().toUtc());

  final String? id;
  final String title;
  final String body;
  final String? link;
  final String? targetVersion;
  final DateTime timestampUtc;
  final NotificationAttachment? attachment;

  bool get hasAttachment => attachment != null;

  Map<String, dynamic> toJsonPayload() {
    final payload = <String, dynamic>{
      'id': id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'link': link ?? '',
      'targetVersion': targetVersion ?? '',
      'timestampUtc': timestampUtc.toIso8601String(),
      'fileUrl': '',
      'fileBase64': '',
      'fileName': '',
    };

    if (hasAttachment && attachment!.bytes != null) {
      payload['fileBase64'] = base64Encode(attachment!.bytes!);
      payload['fileName'] = attachment!.fileName;
    }

    return payload;
  }
}

class NotificationAttachment {
  const NotificationAttachment({
    required this.fileName,
    this.bytes,
    this.filePath,
    this.size,
  });

  final String fileName;
  final List<int>? bytes;
  final String? filePath;
  final int? size;

  bool get hasBytes => bytes != null;
}
