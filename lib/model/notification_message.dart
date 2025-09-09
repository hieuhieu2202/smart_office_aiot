class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final String? fileUrl;
  final DateTime? timestamp;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    this.fileUrl,
    this.timestamp,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: json['title'] ?? json['Title'] ?? '',
      body: json['body'] ?? json['Body'] ?? '',
      fileUrl: json['fileUrl'] ?? json['FileUrl'],
      timestamp: _parseTimestamp(json),
    );
  }

  static DateTime? _parseTimestamp(Map<String, dynamic> json) {
    final dynamic ts =
        json['timestampUtc'] ?? json['timestamp'] ?? json['TimestampUtc'] ?? json['Timestamp'];
    if (ts == null) return null;
    try {
      return DateTime.parse(ts.toString());
    } catch (_) {
      return null;
    }
  }
}
