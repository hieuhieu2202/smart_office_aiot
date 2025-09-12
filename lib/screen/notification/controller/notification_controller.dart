import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:get_storage/get_storage.dart';
import '../../../model/notification_message.dart';
import '../../../service/notification_service.dart';
import '../notification_detail_page.dart';

class NotificationController extends GetxController {
  var notifications = <NotificationMessage>[].obs;
  var isLoading = false.obs;
  final readIds = <String>{}.obs;
  final downloadedFiles = <String, String>{}.obs; // id -> file path
  final downloadProgress = <String, double>{}.obs; // id -> 0..1
  final unreadCount = 0.obs;
  StreamSubscription<NotificationMessage>? _sub;
  Timer? _reconnectTimer;
  final _box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _loadLocal();
    fetchNotifications();
    _connectStream();
    ever<List<NotificationMessage>>(notifications, (_) => _updateUnread());
    ever<Set<String>>(readIds, (_) => _updateUnread());
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final data = await NotificationService.getNotifications();
      print('[NotificationController] fetched ${data.length} notifications');
      for (final msg in data.reversed) {
        if (!notifications.any((n) => n.id == msg.id)) {
          notifications.insert(0, msg);
          print('[NotificationController] added notification ${msg.id}');
        }
      }
      _saveLocal();
      _updateUnread();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    _reconnectTimer?.cancel();
    super.onClose();
  }

  void openNotification(NotificationMessage msg) {
    readIds.add(msg.id);
    _saveLocal();
    print('[NotificationController] openNotification ${msg.id}');
    Get.to(() => NotificationDetailPage(message: msg));
  }

  bool isRead(String id) => readIds.contains(id);

  void _connectStream() {
    _sub?.cancel();
    _sub = NotificationService.streamNotifications().listen((msg) {
      print('[NotificationController] stream received ${msg.id}');
      notifications.insert(0, msg);
      _saveLocal();
      _updateUnread();
      Get.showSnackbar(
        GetSnackBar(
          title: msg.title,
          message: msg.body,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
          onTap: (_) => openNotification(msg),
        ),
      );
    }, onError: (err) {
      print('Notification stream error: $err');
      _scheduleReconnect();
    }, onDone: _scheduleReconnect);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('Reconnecting to notification stream...');
      fetchNotifications();
      _connectStream();
    });
  }

  Future<void> downloadAttachment(NotificationMessage msg) async {
    final url = msg.fileUrl;
    if (msg.fileBase64 != null && msg.fileBase64!.isNotEmpty) {
      try {
      final bytes = NotificationService.decryptBase64(msg.fileBase64!);
      final dir = await getApplicationDocumentsDirectory();
      final filename = msg.fileName ?? msg.id;
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      downloadedFiles[msg.id] = file.path;
        print('[NotificationController] saved attachment ${msg.id} to ${file.path}');
        _saveLocal();
      } catch (e) {
        Get.snackbar('Error', e.toString());
      }
      return;
    }
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
      print('[NotificationController] downloaded ${msg.id} to ${file.path}');
      _saveLocal();
    } catch (e) {
      downloadProgress.remove(msg.id);
      Get.snackbar('Error', e.toString());
    }
  }

  void _updateUnread() {
    unreadCount.value =
        notifications.where((n) => !readIds.contains(n.id)).length;
    _saveLocal();
  }

  void _loadLocal() {
    final storedList = _box.read<List>('notifications') ?? [];
    notifications.assignAll(storedList
        .map((e) => NotificationMessage.fromJson(Map<String, dynamic>.from(e))));
    final storedRead = _box.read<List>('readIds') ?? [];
    readIds.addAll(storedRead.cast<String>());
    final storedFiles = Map<String, String>.from(_box.read('files') ?? {});
    downloadedFiles.assignAll(storedFiles);
  }

  void _saveLocal() {
    _box.write('notifications',
        notifications.map((e) => e.toJson()).toList());
    _box.write('readIds', readIds.toList());
    _box.write('files', downloadedFiles);
  }

  void showActions(NotificationMessage msg) {
    Get.bottomSheet(SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: Icon(isRead(msg.id)
                ? Icons.mark_email_unread
                : Icons.mark_email_read),
            title: Text(isRead(msg.id)
                ? 'Mark as unread'
                : 'Mark as read'),
            onTap: () {
              if (isRead(msg.id)) {
                readIds.remove(msg.id);
              } else {
                readIds.add(msg.id);
              }
              _saveLocal();
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              notifications.removeWhere((n) => n.id == msg.id);
              readIds.remove(msg.id);
              downloadedFiles.remove(msg.id);
              _saveLocal();
              Get.back();
            },
          ),
        ],
      ),
    ));
  }
}
