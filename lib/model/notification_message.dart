class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final String? fileUrl;
  final DateTime? timestampUtc;
  bool read;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    this.fileUrl,
    this.timestampUtc,
    this.read = false,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: json['title'] ?? json['Title'] ?? '',
      body: json['body'] ?? json['Body'] ?? '',
      fileUrl: json['fileUrl'] ?? json['FileUrl'],
      timestampUtc: _parseTimestamp(json),
      read: json['read'] == true,
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
