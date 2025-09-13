import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:get_storage/get_storage.dart';
import 'package:open_filex/open_filex.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../navbar/controller/navbar_controller.dart';
import '../../../model/notification_message.dart';
import '../../../service/notification_service.dart';
import '../notification_detail_page.dart';
import '../notification_files_page.dart';

class NotificationController extends GetxController {
  var notifications = <NotificationMessage>[].obs;
  var isLoading = false.obs;
  final readIds = <String>{}.obs;
  final downloadedFiles = <String, String>{}.obs; // id -> file path
  final downloadProgress = <String, double>{}.obs; // id -> 0..1
  final unreadCount = 0.obs;
  StreamSubscription<NotificationMessage>? _sub;
  // Since connectivity_plus v6, onConnectivityChanged emits a list of
  // ConnectivityResult values reflecting all active interfaces. Track the
  // subscription with the matching generic type.
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _reconnectTimer;
  Timer? _saveTimer;
  final _box = GetStorage();
  DateTime? _lastTimestamp;
  static const int _maxCache = 200;

  @override
  void onInit() {
    super.onInit();
    _loadLocal();
    print(
        '[NotificationController] loaded ${notifications.length} cached notifications');
    _updateUnread();
    fetchNotifications();
    _connectStream();
    _listenConnectivity();
    ever<List<NotificationMessage>>(notifications, (_) => _updateUnread());
    ever<Set<String>>(readIds, (_) => _updateUnread());
  }

  Future<void> fetchNotifications() async {
    try {
      if (notifications.isEmpty) {
        isLoading.value = true;
      }
      final data = await NotificationService.getNotifications();
      print('[NotificationController] fetched ${data.length} notifications');
      for (final msg in data.reversed) {
        final newer =
            _lastTimestamp == null || msg.timestampUtc.isAfter(_lastTimestamp!);
        if (newer && !notifications.any((n) => n.id == msg.id)) {
          notifications.insert(0, msg);
          if (_lastTimestamp == null ||
              msg.timestampUtc.isAfter(_lastTimestamp!)) {
            _lastTimestamp = msg.timestampUtc;
          }
          print('[NotificationController] added notification ${msg.id}');
        }
      }
      _trimCache();
      _scheduleSave();
      _updateUnread();
    } catch (e) {
      print('[NotificationController] fetchNotifications error: $e');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    _connSub?.cancel();
    _reconnectTimer?.cancel();
    _saveTimer?.cancel();
    _saveLocal();
    super.onClose();
  }

  void openNotification(NotificationMessage msg) {
    readIds.add(msg.id);
    _scheduleSave();
    print('[NotificationController] openNotification ${msg.id}');
    Get.to(() => NotificationDetailPage(message: msg));
  }

  bool isRead(String id) => readIds.contains(id);

  void openFiles() {
    Get.to(() => const NotificationFilesPage());
  }

  void deleteFile(String id) {
    final path = downloadedFiles[id];
    if (path != null) {
      File(path).delete().catchError((_) {});
    }
    downloadedFiles.remove(id);
    _scheduleSave();
  }

  void toggleRead(NotificationMessage msg) {
    if (isRead(msg.id)) {
      readIds.remove(msg.id);
      print('[NotificationController] mark ${msg.id} as unread');
    } else {
      readIds.add(msg.id);
      print('[NotificationController] mark ${msg.id} as read');
    }
    _scheduleSave();
  }

  void deleteNotification(NotificationMessage msg) {
    notifications.removeWhere((n) => n.id == msg.id);
    readIds.remove(msg.id);
    downloadedFiles.remove(msg.id);
    print('[NotificationController] deleted notification ${msg.id}');
    _scheduleSave();
  }

  void _connectStream() {
    _sub?.cancel();
    _sub = NotificationService.streamNotifications().listen((msg) {
      print('[NotificationController] stream received ${msg.id}');
      notifications.insert(0, msg);
      if (_lastTimestamp == null || msg.timestampUtc.isAfter(_lastTimestamp!)) {
        _lastTimestamp = msg.timestampUtc;
      }
      _trimCache();
      _scheduleSave();
      _updateUnread();
      final snackTitle =
          (msg.title.isNotEmpty) ? msg.title : 'Thông báo mới';
      final snackBody =
          (msg.body.isNotEmpty) ? msg.body : 'Không có nội dung';
      Get.showSnackbar(
        GetSnackBar(
          title: snackTitle,
          messageText: Text(snackBody),
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
          onTap: (_) => _openFromBanner(msg),
        ),
      );
    }, onError: (err) {
      print('Notification stream error: $err');
      _scheduleReconnect();
    }, onDone: _scheduleReconnect);
  }

  void _openFromBanner(NotificationMessage msg) {
    final nav = Get.find<NavbarController>();
    nav.changTab(3);
    Future.delayed(const Duration(milliseconds: 300), () => openNotification(msg));
  }

  void _listenConnectivity() {
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      // When at least one interface is available and none of them is `none`,
      // consider the device online.
      final online =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      print('[NotificationController] connectivity: $results');
      if (online) {
        fetchNotifications();
        _connectStream();
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('Reconnecting to notification stream...');
      fetchNotifications();
      _connectStream();
    });
  }

  Future<void> openAttachment(NotificationMessage msg) async {
    try {
      final dir = await _resolveSaveDir();
      final filename = msg.fileName ?? msg.id;
      final file = File('${dir.path}/$filename');

      if (msg.fileBase64 != null && msg.fileBase64!.isNotEmpty) {
        print('[NotificationController] decoding base64 for ${msg.id}');
        final bytes = await NotificationService.decryptBase64(msg.fileBase64!);
        await file.writeAsBytes(bytes);
        downloadedFiles[msg.id] = file.path;
        print('[NotificationController] saved attachment ${msg.id} to ${file.path}');
        final idx = notifications.indexWhere((n) => n.id == msg.id);
        if (idx != -1) {
          notifications[idx] = notifications[idx].copyWith(fileBase64: null);
        }
        _scheduleSave();
        await _openFile(file);
        return;
      }

      final url = msg.fileUrl;
      if (url == null) return;

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      if (response.statusCode != 200) {
        Get.snackbar('Error', 'Download failed');
        return;
      }
      final total = response.contentLength ?? 0;
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
      _scheduleSave();
      await _openFile(file);
    } catch (e) {
      downloadProgress.remove(msg.id);
      Get.snackbar('Error', e.toString());
    }
  }

  Future<Directory> _resolveSaveDir() async {
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      if (ext != null) return ext;
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _openFile(File file) async {
    print('[NotificationController] opening file ${file.path}');
    try {
      await OpenFilex.open(file.path);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  void _updateUnread() {
    unreadCount.value =
        notifications.where((n) => !readIds.contains(n.id)).length;
    _scheduleSave();
  }

  void _loadLocal() {
    final storedList = _box.read<List>('notifications') ?? [];
    notifications.assignAll(storedList
        .map((e) => NotificationMessage.fromJson(Map<String, dynamic>.from(e))));
    final storedRead = _box.read<List>('readIds') ?? [];
    readIds.addAll(storedRead.cast<String>());
    final storedFiles = Map<String, String>.from(_box.read('files') ?? {});
    downloadedFiles.assignAll(storedFiles);
    final ts = _box.read<String>('lastTimestamp');
    if (ts != null) {
      _lastTimestamp = DateTime.tryParse(ts);
    } else if (notifications.isNotEmpty) {
      _lastTimestamp = notifications.first.timestampUtc;
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveLocal);
  }

  Future<void> _saveLocal() async {
    await _box.write('notifications',
        notifications.map((e) => e.toJson(includeFileBase64: false)).toList());
    await _box.write('readIds', readIds.toList());
    await _box.write('files', downloadedFiles);
    await _box.write('lastTimestamp', _lastTimestamp?.toIso8601String());
  }

  void _trimCache() {
    if (notifications.length > _maxCache) {
      notifications.removeRange(_maxCache, notifications.length);
    }
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
              toggleRead(msg);
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              deleteNotification(msg);
              Get.back();
            },
          ),
        ],
      ),
    ));
  }
}
