import 'dart:async';

import 'package:get/get.dart';

import '../../../model/notification_message.dart';
import '../../../service/notification_service.dart';

class NotificationController extends GetxController {
  NotificationController({this.pageSize = 20});

  final int pageSize;

  final RxList<NotificationMessage> notifications = <NotificationMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxnString error = RxnString();

  int _currentPage = 1;
  bool _hasMore = true;
  bool _fetching = false;
  Timer? _pollTimer;

  bool get hasMore => _hasMore;
  bool get isFetching => _fetching;

  @override
  void onInit() {
    super.onInit();
    refreshNotifications(showLoader: true);
    _startPolling();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> refreshNotifications({bool showLoader = false}) async {
    if (_fetching) return;
    _currentPage = 1;
    _hasMore = true;
    await _load(page: 1, append: false, showLoader: showLoader);
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
      final result = await NotificationService.fetchNotifications(
        page: page,
        pageSize: pageSize,
      );

      if (!append) {
        notifications.assignAll(result);
      } else if (result.isNotEmpty) {
        final existingIds = notifications
            .map((item) => item.id)
            .whereType<String>()
            .toSet();
        for (final item in result) {
          final id = item.id;
          if (id != null && existingIds.contains(id)) {
            continue;
          }
          notifications.add(item);
        }
      }

      _currentPage = page;
      _hasMore = result.length >= pageSize;
      error.value = null;
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
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_fetching) return;
      await refreshNotifications(showLoader: false);
    });
  }
}
