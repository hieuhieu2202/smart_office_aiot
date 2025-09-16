import 'package:flutter/foundation.dart';

@immutable
class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final DateTime timestampUtc;
  final String? link;
  final String? targetVersion;
  final String? fileUrl;
  final String? fileName;
  final String? fileBase64;

  const NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.timestampUtc,
    this.link,
    this.targetVersion,
    this.fileUrl,
    this.fileName,
    this.fileBase64,
  });

  NotificationMessage copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestampUtc,
    String? link,
    String? targetVersion,
    String? fileUrl,
    String? fileName,
    String? fileBase64,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestampUtc: timestampUtc ?? this.timestampUtc,
      link: link ?? this.link,
      targetVersion: targetVersion ?? this.targetVersion,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileBase64: fileBase64 ?? this.fileBase64,
    );
  }

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    // Convert keys to lowercase so we handle both "Title" and "title".
    final map = json.map((k, v) => MapEntry(k.toString().toLowerCase(), v));

    DateTime? parsedTime;
    final rawTime = map['timestamputc'];
    if (rawTime is int) {
      // Assume milliseconds-since-epoch if an integer is provided.
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime, isUtc: true);
    } else if (rawTime != null) {
      parsedTime = DateTime.tryParse(rawTime.toString());
    }

    final id = _trimOrNull(map['id']) ?? '';
    final title = _trimOrNull(map['title']) ?? '';
    final body = _trimOrNull(map['body']) ?? '';

    return NotificationMessage(
      id: id,
      title: title,
      body: body,
      timestampUtc: parsedTime ?? DateTime.now().toUtc(),
      link: _trimOrNull(map['link']),
      targetVersion: _trimOrNull(map['targetversion']),
      fileUrl: _trimOrNull(map['fileurl']),
      fileName: _trimOrNull(map['filename']),
      fileBase64: _trimOrNull(map['filebase64']),
    );
  }

  Map<String, dynamic> toJson({bool includeFileBase64 = true}) {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'timestampUtc': timestampUtc.toIso8601String(),
    };
    if (link != null) {
      map['link'] = link;
    }
    if (targetVersion != null) {
      map['targetVersion'] = targetVersion;
    }
    if (fileUrl != null) {
      map['fileUrl'] = fileUrl;
    }
    if (fileName != null) {
      map['fileName'] = fileName;
    }
    if (includeFileBase64 && fileBase64 != null) {
      map['fileBase64'] = fileBase64;
    }
    return map;
  }
}

String? _trimOrNull(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}
