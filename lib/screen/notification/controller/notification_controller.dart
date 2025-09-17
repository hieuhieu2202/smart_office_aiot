import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../model/notification_entry.dart';
import '../../../model/notification_message.dart';
import '../../../service/notification_service.dart';

class NotificationController extends GetxController {
  NotificationController({this.pageSize = 20});

  final int pageSize;
  static const int _maxAutoAdvancePages = 10;
  static const String _dismissedStorageKey = 'notification_dismissed_keys';

  final RxList<NotificationEntry> notifications = <NotificationEntry>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxnString error = RxnString();
  final RxInt unreadCount = 0.obs;
  final Rxn<NotificationEntry> bannerEntry = Rxn<NotificationEntry>();
  final RxBool bannerVisible = false.obs;

  int _currentPage = 1;
  bool _hasMore = true;
  bool _fetching = false;
  bool _initialized = false;
  final GetStorage _storage = GetStorage();
  final Set<String> _dismissedKeys = <String>{};

  StreamSubscription<NotificationMessage>? _streamSubscription;
  Timer? _reconnectTimer;
  Timer? _bannerTimer;

  bool get hasMore => _hasMore;
  bool get isFetching => _fetching;

  @override
  void onInit() {
    super.onInit();
    _loadDismissedKeys();
    refreshNotifications(showLoader: true);
    _connectStream();
  }

  @override
  void onClose() {
    _streamSubscription?.cancel();
    _reconnectTimer?.cancel();
    _bannerTimer?.cancel();
    super.onClose();
  }

  Future<void> refreshNotifications({bool showLoader = false}) async {
    if (_fetching) return;
    _currentPage = 1;
    _hasMore = true;
    await _load(page: 1, append: false, showLoader: showLoader);
    var attempts = 0;
    while (notifications.isEmpty && _hasMore && attempts < _maxAutoAdvancePages) {
      attempts++;
      await _load(page: _currentPage + 1, append: true);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _fetching) return;
    isLoadingMore.value = true;
    try {
      await _load(page: _currentPage + 1, append: true);
    } finally {
      isLoadingMore.value = false;
    }
  }

  NotificationEntry? markAsRead(NotificationEntry entry) {
    return _updateEntry(entry, isRead: true);
  }

  NotificationEntry? markAsUnread(NotificationEntry entry) {
    return _updateEntry(entry, isRead: false);
  }

  bool remove(NotificationEntry entry) {
    final index = notifications.indexWhere((item) => item.key == entry.key);
    if (index == -1) return false;
    notifications.removeAt(index);
    _dismissedKeys.add(entry.key);
    _persistDismissedKeys();
    _recalculateUnread();
    return true;
  }

  Future<void> _load({
    required int page,
    required bool append,
    bool showLoader = false,
  }) async {
    if (_fetching) return;
    _fetching = true;
    if (showLoader) {
      isLoading.value = true;
    }

    try {
      final rawResult = await NotificationService.fetchNotifications(
        page: page,
        pageSize: pageSize,
      );

      final result =
          rawResult.where((message) => !_isDismissed(message)).toList();

      if (!append) {
        final previousMap = {
          for (final entry in notifications) entry.key: entry,
        };
        final isInitialLoad = !_initialized;
        final rebuilt = <NotificationEntry>[];

        for (final message in result) {
          final key = _keyFor(message);
          final existing = previousMap[key];
          final bool isRead;
          if (existing != null) {
            isRead = existing.isRead;
          } else if (isInitialLoad) {
            isRead = true;
          } else {
            isRead = false;
          }
          rebuilt.add(
            NotificationEntry(key: key, message: message, isRead: isRead),
          );
        }

        rebuilt.sort(_sortByTimestampDesc);
        notifications.assignAll(rebuilt);
      } else if (result.isNotEmpty) {
        var mutated = false;
        final additions = <NotificationEntry>[];

        for (final message in result) {
          final key = _keyFor(message);
          final index = notifications.indexWhere((item) => item.key == key);
          if (index != -1) {
            notifications[index] = notifications[index].copyWith(message: message);
            mutated = true;
          } else {
            additions.add(
              NotificationEntry(key: key, message: message, isRead: true),
            );
          }
        }

        if (additions.isNotEmpty) {
          notifications.addAll(additions);
          mutated = true;
        }

        if (mutated) {
          notifications.sort(_sortByTimestampDesc);
          notifications.refresh();
        }
      }

      _currentPage = page;
      _hasMore = rawResult.length >= pageSize;
      error.value = null;
      _initialized = true;
    } catch (e) {
      error.value = e.toString();
      if (!append && notifications.isEmpty) {
        notifications.clear();
      }
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
      _fetching = false;
      _recalculateUnread();
    }
  }

  void _connectStream() {
    _streamSubscription?.cancel();
    _streamSubscription = NotificationService.realtimeNotifications().listen(
      (message) {
        _handleIncoming(message);
      },
      onError: (error, stackTrace) {
        _scheduleReconnect();
      },
      onDone: () {
        _scheduleReconnect();
      },
      cancelOnError: false,
    );
  }

  void _scheduleReconnect() {
    if (isClosed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!isClosed) {
        _connectStream();
      }
    });
  }

  void _handleIncoming(NotificationMessage message) {
    if (_isDismissed(message)) {
      return;
    }
    final entry = _upsert(message, markUnread: true);
    if (entry != null) {
      _showBanner(entry);
    }
  }

  NotificationEntry? _upsert(NotificationMessage message, {bool markUnread = false}) {
    if (_isDismissed(message)) {
      return null;
    }
    final key = _keyFor(message);
    final index = notifications.indexWhere((item) => item.key == key);

    if (index != -1) {
      final existing = notifications[index];
      final updated = existing.copyWith(
        message: message,
        isRead: markUnread ? false : existing.isRead,
      );
      notifications[index] = updated;
      notifications.sort(_sortByTimestampDesc);
      notifications.refresh();
      _recalculateUnread();
      return updated;
    }

    final entry = NotificationEntry(
      key: key,
      message: message,
      isRead: !markUnread ? true : false,
    );
    notifications.insert(0, entry);
    notifications.sort(_sortByTimestampDesc);
    notifications.refresh();
    _recalculateUnread();
    return entry;
  }

  NotificationEntry? _updateEntry(
    NotificationEntry entry, {
    NotificationMessage? message,
    bool? isRead,
  }) {
    final index = notifications.indexWhere((item) => item.key == entry.key);
    if (index == -1) return null;
    final current = notifications[index];
    final updated = current.copyWith(
      message: message ?? current.message,
      isRead: isRead ?? current.isRead,
    );
    notifications[index] = updated;
    notifications.refresh();
    _recalculateUnread();
    return updated;
  }

  int _sortByTimestampDesc(NotificationEntry a, NotificationEntry b) {
    final DateTime at = a.message.timestampUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime bt = b.message.timestampUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bt.compareTo(at);
  }

  void _recalculateUnread() {
    unreadCount.value =
        notifications.where((entry) => !entry.isRead).length;
  }

  void _showBanner(NotificationEntry entry) {
    bannerEntry.value = entry;
    bannerVisible.value = true;
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 2), () {
      bannerVisible.value = false;
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (!bannerVisible.value) {
          bannerEntry.value = null;
        }
      });
    });
  }

  String _keyFor(NotificationMessage message) {
    final id = message.id;
    if (id != null && id.isNotEmpty) {
      return id;
    }
    final timestamp = message.timestampUtc?.millisecondsSinceEpoch;
    final buffer = StringBuffer()
      ..write(message.title)
      ..write('::')
      ..write(message.body.hashCode);
    if (timestamp != null) {
      buffer
        ..write('::')
        ..write(timestamp);
    }
    if (message.link != null) {
      buffer
        ..write('::')
        ..write(message.link);
    }
    if (message.fileUrl != null) {
      buffer
        ..write('::')
        ..write(message.fileUrl);
    }
    return buffer.toString();
  }

  bool _isDismissed(NotificationMessage message) {
    final key = _keyFor(message);
    return _dismissedKeys.contains(key);
  }

  void _loadDismissedKeys() {
    final dynamic stored = _storage.read(_dismissedStorageKey);
    if (stored is List) {
      _dismissedKeys
        ..clear()
        ..addAll(stored.whereType<String>());
    }
  }

  void _persistDismissedKeys() {
    _storage.write(_dismissedStorageKey, _dismissedKeys.toList());
  }
}
