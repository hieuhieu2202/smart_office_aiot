import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';

import '../../config/global_color.dart';
import '../../generated/l10n.dart';
import '../../model/notification_message.dart';
import '../../model/notification_page.dart';
import '../../service/notification_service.dart';
import '../../widget/custom_app_bar.dart';

class NotificationTab extends StatefulWidget {
  const NotificationTab({super.key});

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  late final SettingController settingController;
  final List<NotificationMessage> _notifications = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final int _pageSize = 50;
  StreamSubscription<NotificationMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    settingController = Get.find<SettingController>();
    _load();
    _subscription = NotificationService.streamNotifications().listen((n) {
      debugPrint('[NotificationTab] Stream received: ${n.id}');
      if (mounted) {
        setState(() {
          _notifications.removeWhere((e) => e.id == n.id);
          _notifications.add(n);
          _sort();
        });
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _page = 1;
    final NotificationPage res = await NotificationService.getNotifications(
        page: _page, pageSize: _pageSize);
    debugPrint('[NotificationTab] Loaded ${res.items.length} notifications');
    setState(() {
      _notifications
        ..clear()
        ..addAll(res.items);
      _sort();
      _loading = false;
      _hasMore = _notifications.length < res.total;
      _page++;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final NotificationPage res = await NotificationService.getNotifications(
        page: _page, pageSize: _pageSize);
    debugPrint('[NotificationTab] Loaded more ${res.items.length} notifications');
    setState(() {
      for (final n in res.items) {
        if (_notifications.every((e) => e.id != n.id)) {
          _notifications.add(n);
        }
      }
      _sort();
      _hasMore = _notifications.length < res.total;
      _page++;
      _loadingMore = false;
    });
  }

  void _sort() {
    _notifications.sort((a, b) {
      final DateTime ta = a.timestampUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime tb = b.timestampUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
  }

  Future<void> _clear() async {
    final bool ok = await NotificationService.clearNotifications();
    if (ok) {
      debugPrint('[NotificationTab] Cleared notifications');
      await _load();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S text = S.of(context);
    return Obx(() {
      final bool isDark = settingController.isDarkMode.value;
      return Scaffold(
        appBar: CustomAppBar(
          title: Text(text.notification),
          isDark: isDark,
          accent: GlobalColors.accentByIsDark(isDark),
          titleAlign: TextAlign.left,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clear,
            )
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _notifications.isEmpty
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: const Text('No notifications'),
                            ),
                          )
                        ],
                      )
                    : ListView.builder(
                        itemCount:
                            _notifications.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _notifications.length) {
                            if (_loadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            return TextButton(
                              onPressed: _loadMore,
                              child: const Text('Load more'),
                            );
                          }
                          final NotificationMessage n = _notifications[index];
                          return ListTile(
                            title: Text(n.title),
                            subtitle: Text(n.body),
                            trailing: n.fileUrl != null
                                ? const Icon(Icons.attach_file)
                                : null,
                          );
                        },
                      ),
              ),
      );
    });
  }
}
