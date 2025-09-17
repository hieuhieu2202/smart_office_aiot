import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/Apiconfig.dart';
import '../../config/global_color.dart';
import '../../generated/l10n.dart';
import '../../model/notification_entry.dart';
import '../../model/notification_message.dart';
import '../../widget/custom_app_bar.dart';
import '../../widget/notification/notification_card.dart';
import '../setting/controller/setting_controller.dart';
import 'controller/notification_controller.dart';
import 'notification_detail_screen.dart';

class NotificationTab extends StatefulWidget {
  const NotificationTab({super.key});

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  late final SettingController settingController;
  late final NotificationController notificationController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    settingController = Get.find<SettingController>();
    notificationController = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 320) {
      notificationController.loadMore();
    }
  }

  Future<void> _onRefresh() {
    return notificationController.refreshNotifications(showLoader: false);
  }

  Future<void> _openDetails(NotificationEntry entry) async {
    final updated = notificationController.markAsRead(entry) ?? entry;
    await Get.to(() => NotificationDetailScreen(entry: updated));
  }

  Future<void> _openLink(String? rawUrl) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) return;
    final uri = _parseUri(rawUrl);
    if (uri == null) {
      Get.snackbar(
        'Liên kết không hợp lệ',
        rawUrl,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success) {
      Get.snackbar(
        'Không thể mở liên kết',
        uri.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.85),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _openAttachment(NotificationMessage message) async {
    final raw = message.fileUrl;
    if (raw == null || raw.isEmpty) {
      Get.snackbar(
        'Không có tệp đính kèm',
        message.fileName ?? '',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final resolved = _resolveResourceUrl(raw);
    final uri = Uri.tryParse(resolved);
    if (uri == null) {
      Get.snackbar(
        'Đường dẫn tệp không hợp lệ',
        resolved,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success) {
      Get.snackbar(
        'Không thể mở tệp đính kèm',
        message.fileName ?? uri.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.85),
        colorText: Colors.white,
      );
    }
  }

  Uri? _parseUri(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    Uri? uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$trimmed');
    }
    if (uri == null || !uri.hasScheme) return null;
    return uri;
  }

  String _resolveResourceUrl(String url) {
    return ApiConfig.normalizeNotificationUrl(url);
  }

  Widget _buildErrorBanner(bool isDark, String message, Color accent) {
    final bgColor = Colors.redAccent.withOpacity(isDark ? 0.18 : 0.12);
    final borderColor = Colors.redAccent.withOpacity(0.5);
    final textColor = isDark ? Colors.red[100]! : Colors.red[900]!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                notificationController.refreshNotifications(showLoader: true),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    String? errorMessage,
    Color accent,
  ) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return RefreshIndicator(
      color: accent,
      onRefresh: _onRefresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: screenHeight * 0.18),
          Icon(
            Icons.notifications_off_outlined,
            size: 72,
            color: accent.withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có thông báo nào',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? GlobalColors.darkPrimaryText
                  : GlobalColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              errorMessage?.isNotEmpty == true
                  ? errorMessage!
                  : 'Kéo xuống để làm mới và tải thông báo mới nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark
                    ? GlobalColors.darkSecondaryText
                    : GlobalColors.lightSecondaryText,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildList(
    bool isDark,
    Color accent,
    List<NotificationEntry> items,
    bool isLoadingMore,
  ) {
    return RefreshIndicator(
      color: accent,
      onRefresh: _onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 16, bottom: 120),
        itemCount: items.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: accent),
              ),
            );
          }

          final entry = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Dismissible(
              key: ValueKey(entry.key),
              direction: DismissDirection.horizontal,
              background: _buildSwipeBackground(
                alignLeft: true,
                color: accent,
                icon: Icons.markunread,
                label: 'Đánh dấu chưa đọc',
              ),
              secondaryBackground: _buildSwipeBackground(
                alignLeft: false,
                color: Colors.redAccent,
                icon: Icons.delete_outline,
                label: 'Xoá',
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  notificationController.markAsUnread(entry);
                  return false;
                }
                return true;
              },
              onDismissed: (_) {
                notificationController.remove(entry);
              },
              child: NotificationCard(
                message: entry.message,
                isDark: isDark,
                accent: accent,
                isUnread: !entry.isRead,
                onTap: () => _openDetails(entry),
                onToggleReadState: () {
                  if (entry.isRead) {
                    notificationController.markAsUnread(entry);
                  } else {
                    notificationController.markAsRead(entry);
                  }
                },
                onDelete: () => notificationController.remove(entry),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeBackground({
    required bool alignLeft,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    final content = <Widget>[
      Icon(icon, color: Colors.white),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: alignLeft
          ? const EdgeInsets.only(left: 24)
          : const EdgeInsets.only(right: 24),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignLeft ? content : content.reversed.toList(),
      ),
    );
  }

  Widget _buildIncomingBanner(
    bool isDark,
    Color accent,
    bool isVisible,
    NotificationEntry? entry,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isVisible && entry != null
          ? Padding(
              key: ValueKey(entry.key),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.22 : 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Thông báo mới',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? GlobalColors.darkPrimaryText
                                  : GlobalColors.lightPrimaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.message.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? GlobalColors.darkSecondaryText
                                  : GlobalColors.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openDetails(entry),
                      child: const Text('Xem'),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S text = S.of(context);
    return Obx(() {
      final bool isDark = settingController.isDarkMode.value;
      final Color accent = GlobalColors.accentByIsDark(isDark);
      final notifications = notificationController.notifications;
      final bool isLoading = notificationController.isLoading.value;
      final bool isLoadingMore = notificationController.isLoadingMore.value;
      final String? errorMessage = notificationController.error.value;
      final bool bannerVisible = notificationController.bannerVisible.value;
      final NotificationEntry? bannerEntry =
          notificationController.bannerEntry.value;

      Widget bodyContent;
      if (isLoading && notifications.isEmpty) {
        bodyContent = const Center(child: CircularProgressIndicator());
      } else if (notifications.isEmpty) {
        bodyContent =
            _buildEmptyState(context, isDark, errorMessage, accent);
      } else {
        bodyContent = _buildList(
          isDark,
          accent,
          notifications,
          isLoadingMore,
        );
      }

      return Scaffold(
        appBar: CustomAppBar(
          title: Text(text.notification),
          isDark: isDark,
          accent: accent,
          titleAlign: TextAlign.left,
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              onPressed: () =>
                  notificationController.refreshNotifications(showLoader: true),
              icon: const Icon(Icons.refresh),
              color: accent,
            ),
          ],
        ),
        body: Column(
          children: [
            if (errorMessage != null && errorMessage.trim().isNotEmpty)
              _buildErrorBanner(isDark, errorMessage, accent),
            _buildIncomingBanner(isDark, accent, bannerVisible, bannerEntry),
            Expanded(child: bodyContent),
          ],
        ),
      );
    });
  }
}
