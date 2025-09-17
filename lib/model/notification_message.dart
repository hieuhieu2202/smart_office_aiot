import 'package:intl/intl.dart';

class NotificationMessage {
  const NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    this.link,
    this.targetVersion,
    this.timestampUtc,
    this.fileUrl,
    this.fileName,
  });

  final String? id;
  final String title;
  final String body;
  final String? link;
  final String? targetVersion;
  final DateTime? timestampUtc;
  final String? fileUrl;
  final String? fileName;

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTimestamp;
    final dynamic ts = json['timestampUtc'] ?? json['timestamp'];
    if (ts is String && ts.isNotEmpty) {
      parsedTimestamp = DateTime.tryParse(ts)?.toUtc();
    } else if (ts is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(ts).toUtc();
    }

    return NotificationMessage(
      id: json['id']?.toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      link: _normalizeOptional(json['link']),
      targetVersion: _normalizeOptional(json['targetVersion']),
      timestampUtc: parsedTimestamp,
      fileUrl: _normalizeOptional(json['fileUrl']),
      fileName: _normalizeOptional(json['fileName']),
    );
  }

  static List<NotificationMessage> listFrom(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(NotificationMessage.fromJson)
          .toList();
    }
    if (data is Map<String, dynamic>) {
      for (final key in ['items', 'data', 'notifications', 'results']) {
        final value = data[key];
        if (value is List) {
          return value
              .whereType<Map<String, dynamic>>()
              .map(NotificationMessage.fromJson)
              .toList();
        }
      }
      if (data.containsKey('id') && data.containsKey('title')) {
        return [NotificationMessage.fromJson(data)];
      }
    }
    return const <NotificationMessage>[];
  }

  DateTime? get timestampLocal => timestampUtc?.toLocal();

  String? get formattedTimestamp {
    final local = timestampLocal;
    if (local == null) return null;
    return DateFormat('dd/MM/yyyy HH:mm').format(local);
  }

  bool get hasLink => link != null && link!.trim().isNotEmpty;
  bool get hasAttachment {
    final hasUrl = fileUrl != null && fileUrl!.trim().isNotEmpty;
    final hasName = fileName != null && fileName!.trim().isNotEmpty;
    return hasUrl || hasName;
  }

  static String? _normalizeOptional(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString();
  }
}
