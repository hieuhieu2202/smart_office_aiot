import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
    _subscription = NotificationService.notificationsStream.listen((n) {
      debugPrint('[NotificationTab] Stream received: ${n.id}');
      if (!mounted) return;
      setState(() {
        _insertNotification(n);
      });
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
      _notifications.sort((a, b) {
        final DateTime ta =
            a.timestampUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime tb =
            b.timestampUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
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
        _insertNotification(n, dedupe: true);
      }
      _hasMore = _notifications.length < res.total;
      _page++;
      _loadingMore = false;
    });
  }

  void _insertNotification(NotificationMessage n, {bool dedupe = false}) {
    if (dedupe) {
      _notifications.removeWhere((e) =>
          e.id.isNotEmpty &&
          n.id.isNotEmpty &&
          e.id == n.id &&
          e.timestampUtc == n.timestampUtc);
    }
    _notifications.insert(0, n);
    _notifications.sort((a, b) {
      final DateTime ta = a.timestampUtc ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime tb = b.timestampUtc ??
          DateTime.fromMillisecondsSinceEpoch(0);
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
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount:
                            _notifications.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index >= _notifications.length) {
                            if (_loadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            return Center(
                              child: TextButton(
                                onPressed: _loadMore,
                                child: const Text('Load more'),
                              ),
                            );
                          }
                          final NotificationMessage n = _notifications[index];
                          final String time = n.timestampUtc != null
                              ? DateFormat('yyyy-MM-dd HH:mm')
                                  .format(n.timestampUtc!.toLocal())
                              : '';
                          return Card(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: ListTile(
                              leading: const Icon(Icons.notifications),
                              title: Text(n.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.body),
                                  if (time.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        time,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: n.fileUrl != null
                                  ? const Icon(Icons.attach_file)
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
      );
    });
  }
}
