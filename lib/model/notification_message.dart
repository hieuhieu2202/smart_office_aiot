import 'package:flutter/foundation.dart';

@immutable
class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final DateTime timestampUtc;
  final String? fileUrl;
  final String? fileName;
  final String? fileBase64;

  const NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.timestampUtc,
    this.fileUrl,
    this.fileName,
    this.fileBase64,
  });

  NotificationMessage copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestampUtc,
    String? fileUrl,
    String? fileName,
    String? fileBase64,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestampUtc: timestampUtc ?? this.timestampUtc,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileBase64: fileBase64 ?? this.fileBase64,
    );
  }

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTime;
    final rawTime = json['timestampUtc'];
    if (rawTime is int) {
      // Assume milliseconds-since-epoch if an integer is provided.
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime, isUtc: true);
    } else if (rawTime != null) {
      parsedTime = DateTime.tryParse(rawTime.toString());
    }

    return NotificationMessage(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestampUtc: parsedTime ?? DateTime.now().toUtc(),
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileBase64: json['fileBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson({bool includeFileBase64 = true}) {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestampUtc': timestampUtc.toIso8601String(),
      'fileUrl': fileUrl,
      'fileName': fileName,
      if (includeFileBase64) 'fileBase64': fileBase64,
    };
  }
}
