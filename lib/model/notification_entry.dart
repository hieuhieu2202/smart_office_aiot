import 'notification_message.dart';

class NotificationEntry {
  const NotificationEntry({
    required this.key,
    required this.message,
    this.isRead = true,
  });

  final String key;
  final NotificationMessage message;
  final bool isRead;

  NotificationEntry copyWith({
    String? key,
    NotificationMessage? message,
    bool? isRead,
  }) {
    return NotificationEntry(
      key: key ?? this.key,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
    );
  }
}
