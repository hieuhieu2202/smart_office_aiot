import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../model/notification_message.dart';
import '../../../service/notification_service.dart';

class NavbarController extends GetxController {
  var currentIndex = 0.obs;
  var unreadCount = 0.obs;

  StreamSubscription<NotificationMessage>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = NotificationService.notificationsStream.listen((n) {
      if (currentIndex.value != 3) {
        Get.snackbar(
          n.title,
          n.body,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          onTap: (_) => changTab(3),
        );
        unreadCount.value++;
      }
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void changTab(int index) {
    currentIndex.value = index;
    if (index == 3) {
      clearUnread();
    }
  }

  void clearUnread() {
    unreadCount.value = 0;
  }
}

