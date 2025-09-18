import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
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
  static const int _maxStoredDismissedKeys = 200;

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
  final List<String> _dismissedOrder = <String>[];

  StreamSubscription<NotificationMessage>? _streamSubscription;
  Timer? _reconnectTimer;
  Timer? _bannerTimer;
  Timer? _autoRefreshTimer;
  Timer? _pollingTimer;

  bool _syncingLatest = false;

  static const Duration _pollingInterval = Duration(seconds: 5);

  bool get hasMore => _hasMore;
  bool get isFetching => _fetching;

  @override
  void onInit() {
    super.onInit();
    _log('Khởi tạo NotificationController (pageSize=$pageSize)');
    _loadDismissedKeys();
    refreshNotifications(showLoader: true);
    _connectStream();
    _startAutoPolling();
  }

  @override
  void onClose() {
    _log('Đóng NotificationController');
    _streamSubscription?.cancel();
    _reconnectTimer?.cancel();
    _bannerTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _pollingTimer?.cancel();
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
    _touchDismissedKey(entry.key);
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
    _log('Tải thông báo page=$page append=$append showLoader=$showLoader');
    if (showLoader) {
      isLoading.value = true;
    }

    try {
      final fetchResult = await NotificationService.fetchNotifications(
        page: page,
        pageSize: pageSize,
      );

      _log(
        'Nhận ${fetchResult.items.length} thông báo (page=${fetchResult.page}, '
        'pageSize=${fetchResult.pageSize}, total=${fetchResult.total}).',
      );

      final incoming =
          fetchResult.items.where((message) => !_isDismissed(message)).toList();

      if (!append) {
        final previousMap = {
          for (final entry in notifications) entry.key: entry,
        };
        final isInitialLoad = !_initialized;
        final rebuilt = <NotificationEntry>[];

        for (final message in incoming) {
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
      } else if (incoming.isNotEmpty) {
        var mutated = false;
        final additions = <NotificationEntry>[];

        for (final message in incoming) {
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

      final fetchedPage = fetchResult.page > 0 ? fetchResult.page : page;
      _currentPage = fetchedPage;
      _hasMore = fetchResult.hasMore;
      error.value = null;
      _initialized = true;
      _log('Hoàn tất tải trang $fetchedPage. hasMore=$_hasMore');
    } catch (e, stackTrace) {
      error.value = e.toString();
      _log('Lỗi khi tải thông báo: $e', error: e, stackTrace: stackTrace);
      if (!append && notifications.isEmpty) {
        notifications.clear();
      }
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
      _fetching = false;
      _recalculateUnread();
      _log('Kết thúc tải trang $page. Tổng thông báo hiện tại: '
          '${notifications.length}');
    }
  }

  void _connectStream() {
    _log('Đăng ký nhận realtime notifications');
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
    _log('Lên lịch kết nối lại realtime stream sau 1s');
    _reconnectTimer = Timer(const Duration(seconds: 1), () {
      if (!isClosed) {
        _connectStream();
      }
    });
  }

  void _handleIncoming(
    NotificationMessage message, {
    bool markUnread = true,
    bool triggerRefresh = true,
  }) {
    _log(
      'Xử lý thông báo realtime: id=${message.id ?? '-'} '
      'title=${message.title} markUnread=$markUnread '
      'triggerRefresh=$triggerRefresh',
    );
    if (_isDismissed(message)) {
      _log('Thông báo đã bị loại bỏ trước đó, bỏ qua.');
      return;
    }
    final entry = _upsert(message, markUnread: markUnread);
    if (entry != null) {
      if (markUnread) {
        _showBanner(entry);
        _showGlobalSnackbar(entry);
      }
      if (triggerRefresh) {
        _triggerSoftRefresh();
      }
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
      _log('Cập nhật thông báo hiện có: key=$key markUnread=$markUnread');
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
    _log('Thêm thông báo mới: key=$key markUnread=$markUnread');
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

  void _showGlobalSnackbar(NotificationEntry entry) {
    final BuildContext? context = Get.overlayContext ?? Get.context;
    if (context == null) {
      return;
    }

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent = theme.colorScheme.secondary;
    final Color background = isDark
        ? Colors.black.withOpacity(0.85)
        : Colors.white.withOpacity(0.94);
    final Color textColor = isDark ? Colors.white : Colors.black87;

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 16,
        backgroundColor: background,
        icon: Icon(Icons.notifications_active_rounded, color: accent),
        titleText: Text(
          'Thông báo mới',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        messageText: Text(
          entry.message.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        ),
      ),
    );
  }

  void _triggerSoftRefresh() {
    if (isClosed) return;
    _autoRefreshTimer?.cancel();
    _log('Đặt lịch làm mới nhẹ sau 600ms');
    _autoRefreshTimer = Timer(const Duration(milliseconds: 600), () async {
      _autoRefreshTimer = null;
      if (isClosed) return;
      if (_fetching) {
        _log('Đang tải dữ liệu, sẽ thử lại soft refresh');
        _triggerSoftRefresh();
        return;
      }
      _log('Thực thi soft refresh');
      await refreshNotifications(showLoader: false);
    });
  }

  void _startAutoPolling() {
    _pollingTimer?.cancel();
    _log('Bật auto polling mỗi ${_pollingInterval.inSeconds}s');
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (isClosed || !_initialized || _fetching || _syncingLatest) {
        _log('Bỏ qua auto polling tick (isClosed=$isClosed, '
            '_initialized=$_initialized, _fetching=$_fetching, '
            '_syncingLatest=$_syncingLatest)');
        return;
      }
      _log('Auto polling tick, đồng bộ trang đầu');
      unawaited(_syncLatest());
    });
  }

  Future<void> _syncLatest() async {
    if (_syncingLatest) {
      return;
    }
    _syncingLatest = true;
    _log('Bắt đầu đồng bộ trang đầu để tìm thông báo mới');
    try {
      final fetchResult = await NotificationService.fetchNotifications(
        page: 1,
        pageSize: pageSize,
      );

      if (fetchResult.isEmpty) {
        _log('Không có thông báo nào khi đồng bộ.');
        return;
      }

      final filtered = fetchResult.items
          .where((message) => !_isDismissed(message))
          .toList();
      if (filtered.isEmpty) {
        _log('Tất cả thông báo mới đều đã bị loại bỏ trước đó.');
        return;
      }

      final List<NotificationEntry> newlyAdded = <NotificationEntry>[];

      for (final message in filtered) {
        final key = _keyFor(message);
        final exists =
            notifications.indexWhere((item) => item.key == key) != -1;
        if (exists) {
          _log('Đã có thông báo $key, cập nhật nội dung.');
          _upsert(message, markUnread: false);
        } else {
          final entry = _upsert(message, markUnread: true);
          if (entry != null) {
            newlyAdded.add(entry);
          }
        }
      }

      if (newlyAdded.isNotEmpty) {
        _log('Có ${newlyAdded.length} thông báo mới từ đồng bộ.');
        newlyAdded.sort(_sortByTimestampDesc);
        for (final entry in newlyAdded) {
          if (!isClosed) {
            _showBanner(entry);
            _showGlobalSnackbar(entry);
          }
        }
      } else {
        _log('Không có thông báo mới cần hiển thị sau đồng bộ.');
      }
    } catch (error, stackTrace) {
      _log('Lỗi khi đồng bộ thông báo mới: $error',
          error: error, stackTrace: stackTrace);
      // Bỏ qua lỗi khi đồng bộ ngầm, lần sau sẽ thử lại.
    } finally {
      _log('Kết thúc đồng bộ thông báo mới.');
      _syncingLatest = false;
    }
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
      final keys = stored.whereType<String>().toList();
      _dismissedKeys
        ..clear()
        ..addAll(keys);
      _dismissedOrder
        ..clear()
        ..addAll(keys);
      _pruneDismissedKeys();
      _persistDismissedKeys();
    }
  }

  void _persistDismissedKeys() {
    _pruneDismissedKeys();
    _storage.write(_dismissedStorageKey, _dismissedOrder);
  }

  void _touchDismissedKey(String key) {
    _dismissedKeys.add(key);
    _dismissedOrder.remove(key);
    _dismissedOrder.add(key);
    _pruneDismissedKeys();
  }

  void _pruneDismissedKeys() {
    while (_dismissedOrder.length > _maxStoredDismissedKeys) {
      final removed = _dismissedOrder.removeAt(0);
      _dismissedKeys.remove(removed);
    }
  }

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'NotificationController',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
