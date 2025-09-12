import 'dart:async';

import 'package:get/get.dart';
import '../../../model/notification_message.dart';
import '../../../service/notification_service.dart';

class NotificationController extends GetxController {
  var notifications = <NotificationMessage>[].obs;
  var isLoading = false.obs;
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
}
