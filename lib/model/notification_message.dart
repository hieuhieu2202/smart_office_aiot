import 'package:flutter/foundation.dart';

@immutable
class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final DateTime timestampUtc;
  final String? fileUrl;
  final String? fileName;

  const NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.timestampUtc,
    this.fileUrl,
    this.fileName,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestampUtc: DateTime.parse(json['timestampUtc'].toString()),
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestampUtc': timestampUtc.toIso8601String(),
      'fileUrl': fileUrl,
      'fileName': fileName,
    };
  }
}
