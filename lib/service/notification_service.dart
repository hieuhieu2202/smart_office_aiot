// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:http/io_client.dart';
//
// class NotificationService {
//   static final String _baseUrl = "https://localhost:7283/api/Control/";
//
//   static IOClient _getInsecureClient() {
//     final httpClient = HttpClient()
//       ..badCertificateCallback = (cert, host, port) => true;
//     return IOClient(httpClient);
//   }
//
//   static Future<List<NotificationMessage>> getAllNotifications() async {
//     final url = Uri.parse("${_baseUrl}get-notifications");
//     final client = _getInsecureClient();
//     final res = await client.get(url);
//
//     print('[DEBUG] GET $url');
//     print('[DEBUG] Status: ${res.statusCode}');
//     print('[DEBUG] Body: ${res.body}');
//
//     if (res.statusCode == 200 && res.body.isNotEmpty) {
//       final List<dynamic> data = json.decode(res.body);
//       return data
//           .map((e) => NotificationMessage.fromJson(e))
//           .toList();
//     } else if (res.statusCode == 204) {
//       return [];
//     } else {
//       throw Exception('Failed to fetch notifications (${res.statusCode})');
//     }
//   }
//
//   static Future<bool> sendNotification({
//     required String title,
//     required String body,
//   }) async {
//     final url = Uri.parse("${_baseUrl}send-notification");
//     final client = _getInsecureClient();
//     final payload = json.encode({
//       "title": title,
//       "body": body,
//     });
//
//     print('[DEBUG] POST $url');
//     print('[DEBUG] Body: $payload');
//
//     final res = await client.post(url,
//         headers: {"Content-Type": "application/json"}, body: payload);
//
//     print('[DEBUG] Status: ${res.statusCode}');
//     print('[DEBUG] Body: ${res.body}');
//
//     return res.statusCode == 200;
//   }
//
//   static Future<bool> clearNotifications() async {
//     final url = Uri.parse("${_baseUrl}clear-notifications");
//     final client = _getInsecureClient();
//     final res = await client.post(url);
//     return res.statusCode == 200;
//   }
// }
//
// class NotificationMessage {
//   final String title;
//   final String body;
//   final DateTime timestamp;
//
//   NotificationMessage({
//     required this.title,
//     required this.body,
//     required this.timestamp,
//   });
//
//   factory NotificationMessage.fromJson(Map<String, dynamic> json) {
//     return NotificationMessage(
//       title: json['title'],
//       body: json['body'],
//       timestamp: DateTime.parse(json['timestamp']),
//     );
//   }
// }
