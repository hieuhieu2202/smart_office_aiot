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
    this.appVersion,
  });

  final String? id;
  final String title;
  final String body;
  final String? link;
  final String? targetVersion;
  final DateTime? timestampUtc;
  final String? fileUrl;
  final String? fileName;
  final NotificationAppVersion? appVersion;

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTimestamp;
    for (final key in [
      'timestampUtc',
      'TimestampUtc',
      'timestamp',
      'createdAt',
      'CreatedAt',
      'created_at',
      'sentAt',
      'SentAt',
    ]) {
      final dynamic value = json[key];
      parsedTimestamp = _parseTimestamp(value);
      if (parsedTimestamp != null) {
        break;
      }
    }

    final appVersion = NotificationAppVersion.maybeFrom(json['appVersion']);

    final targetVersion = _firstNonEmpty(
      json,
      ['targetVersion', 'TargetVersion', 'version', 'Version', 'target_version'],
    );
    final fileUrl =
        _firstNonEmpty(json, ['fileUrl', 'FileUrl', 'fileURL', 'FileURL', 'attachment', 'Attachment']);
    final fileName = _firstNonEmpty(
      json,
      ['fileName', 'FileName', 'attachmentName', 'AttachmentName'],
    );

    return NotificationMessage(
      id: _firstNonEmpty(json,
          ['id', 'Id', 'notificationId', 'NotificationId', 'notificationID', 'NotificationID']),
      title: _firstNonEmpty(
            json,
            ['title', 'Title', 'subject', 'Subject', 'name', 'Name'],
          ) ??
          '',
      body: _firstNonEmpty(
            json,
            ['body', 'Body', 'message', 'Message', 'content', 'Content'],
          ) ??
          '',
      link: _firstNonEmpty(json,
          ['link', 'Link', 'url', 'URL', 'linkUrl', 'linkURL', 'LinkUrl', 'LinkURL', 'actionUrl', 'ActionUrl']),
      targetVersion: targetVersion ?? appVersion?.versionName,
      timestampUtc: parsedTimestamp,
      fileUrl: fileUrl ?? appVersion?.fileUrl,
      fileName: fileName ??
          appVersion?.fileName ??
          _fileNameFromUrl(fileUrl ?? appVersion?.fileUrl),
      appVersion: appVersion,
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

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toUtc();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toUtc();
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt()).toUtc();
    }
    return null;
  }

  static String? _firstNonEmpty(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (!json.containsKey(key)) continue;
      final normalized = _normalizeOptional(json[key]);
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  static String? _normalizeOptional(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString();
  }

  static String? _fileNameFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    final segments = uri?.pathSegments;
    if (segments != null && segments.isNotEmpty) {
      return segments.last;
    }
    final index = url.lastIndexOf('/');
    if (index != -1 && index < url.length - 1) {
      return url.substring(index + 1);
    }
    return null;
  }
}

class NotificationAppVersion {
  const NotificationAppVersion({
    this.appVersionId,
    this.versionName,
    this.releaseNotes,
    this.fileUrl,
    this.fileChecksum,
    this.releaseDate,
  });

  final int? appVersionId;
  final String? versionName;
  final String? releaseNotes;
  final String? fileUrl;
  final String? fileChecksum;
  final DateTime? releaseDate;

  String? get fileName => NotificationMessage._fileNameFromUrl(fileUrl);

  factory NotificationAppVersion.fromJson(Map<String, dynamic> json) {
    DateTime? parsedReleaseDate;
    final dynamic release =
        json['releaseDate'] ?? json['ReleaseDate'] ?? json['releasedAt'] ?? json['ReleasedAt'];
    if (release is String && release.isNotEmpty) {
      parsedReleaseDate = DateTime.tryParse(release)?.toUtc();
    } else if (release is int) {
      parsedReleaseDate = DateTime.fromMillisecondsSinceEpoch(release).toUtc();
    }

    return NotificationAppVersion(
      appVersionId: json['appVersionId'] is int
          ? json['appVersionId'] as int
          : json['AppVersionId'] is int
              ? json['AppVersionId'] as int
              : int.tryParse(
                  json['appVersionId']?.toString() ?? json['AppVersionId']?.toString() ?? '',
                ),
      versionName: NotificationMessage._normalizeOptional(
        json['versionName'] ?? json['VersionName'],
      ),
      releaseNotes: NotificationMessage._normalizeOptional(
        json['releaseNotes'] ?? json['ReleaseNotes'],
      ),
      fileUrl: NotificationMessage._normalizeOptional(
        json['fileUrl'] ?? json['FileUrl'],
      ),
      fileChecksum: NotificationMessage._normalizeOptional(
        json['fileChecksum'] ?? json['FileChecksum'],
      ),
      releaseDate: parsedReleaseDate,
    );
  }

  static NotificationAppVersion? maybeFrom(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.isEmpty) return null;
      return NotificationAppVersion.fromJson(data);
    }
    return null;
  }
}
