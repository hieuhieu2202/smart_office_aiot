import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../model/notification_message.dart';
import '../../../service/notification_service.dart';
import '../notification_detail_page.dart';

class NotificationController extends GetxController {
  var notifications = <NotificationMessage>[].obs;
  var isLoading = false.obs;
  final readIds = <String>{}.obs;
  final downloadedFiles = <String, String>{}.obs; // id -> file path
  final downloadProgress = <String, double>{}.obs; // id -> 0..1
  StreamSubscription<NotificationMessage>? _sub;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    _sub = NotificationService.streamNotifications().listen((msg) {
      print('Received notification: ' + msg.title);
      notifications.insert(0, msg);
    }, onError: (err) {
      print('Notification stream error: $err');
    });
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final data = await NotificationService.getNotifications();
      notifications.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void openNotification(NotificationMessage msg) {
    readIds.add(msg.id);
    Get.to(() => NotificationDetailPage(message: msg));
  }

  bool isRead(String id) => readIds.contains(id);

  Future<void> downloadAttachment(NotificationMessage msg) async {
    final url = msg.fileUrl;
    if (url == null) return;
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      if (response.statusCode != 200) {
        Get.snackbar('Error', 'Download failed');
        return;
      }
      final total = response.contentLength ?? 0;
      final dir = await getApplicationDocumentsDirectory();
      final filename = msg.fileName ?? msg.id;
      final file = File('${dir.path}/$filename');
      final sink = file.openWrite();
      int received = 0;
      downloadProgress[msg.id] = 0;
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) {
          downloadProgress[msg.id] = received / total;
        }
      }
      await sink.close();
      downloadedFiles[msg.id] = file.path;
      downloadProgress.remove(msg.id);
    } catch (e) {
      downloadProgress.remove(msg.id);
      Get.snackbar('Error', e.toString());
    }
  }
}
