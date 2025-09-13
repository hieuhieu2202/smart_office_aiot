import 'package:flutter/foundation.dart';

@immutable
class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final DateTime timestampUtc;
  final String? link;
  final String? fileUrl;
  final String? fileName;
  final String? fileBase64;

  const NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.timestampUtc,
    this.link,
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

    return NotificationMessage(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestampUtc: parsedTime ?? DateTime.now().toUtc(),
      link: map['link'] as String?,
      fileUrl: map['fileurl'] as String?,
      fileName: map['filename'] as String?,
      fileBase64: map['filebase64'] as String?,
    );
  }

  Map<String, dynamic> toJson({bool includeFileBase64 = true}) {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestampUtc': timestampUtc.toIso8601String(),
      'link': link,
      'fileUrl': fileUrl,
      'fileName': fileName,
      if (includeFileBase64) 'fileBase64': fileBase64,
    };
  }
}
