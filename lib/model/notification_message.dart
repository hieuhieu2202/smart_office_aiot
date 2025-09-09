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
      timestamp: (json['timestamp'] ?? json['Timestamp']) != null
          ? DateTime.parse(json['timestamp'] ?? json['Timestamp'])
          : null,
    );
  }
}
