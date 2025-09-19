import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/global_color.dart';
import '../../generated/l10n.dart';
import '../../model/notification_entry.dart';
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

enum _NotificationSwipeAction { toggleRead, delete }

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
    BuildContext context,
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
              direction: DismissDirection.endToStart,
              movementDuration: const Duration(milliseconds: 220),
              background: const SizedBox.shrink(),
              secondaryBackground: _buildSwipeBackground(
                isDark: isDark,
                accent: accent,
                entry: entry,
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  await _handleSwipeAction(
                    context,
                    entry,
                    accent,
                    isDark,
                    index,
                  );
                }
                return false;
              },
              child: NotificationCard(
                message: entry.message,
                isDark: isDark,
                accent: accent,
                isUnread: !entry.isRead,
                onTap: () => _openDetails(entry),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeBackground({
    required bool isDark,
    required Color accent,
    required NotificationEntry entry,
  }) {
    final Color readColor = entry.isRead ? Colors.orangeAccent : accent;
    final gradient = LinearGradient(
      colors: [
        readColor.withOpacity(isDark ? 0.24 : 0.16),
        Colors.redAccent.withOpacity(isDark ? 0.28 : 0.18),
      ],
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
    );

    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwipePill(
            icon: entry.isRead ? Icons.markunread : Icons.mark_email_read_outlined,
            label: entry.isRead ? 'Chưa đọc' : 'Đã đọc',
            color: readColor,
          ),
          const SizedBox(width: 12),
          _buildSwipePill(
            icon: Icons.delete_outline,
            label: 'Xoá',
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSwipeAction(
    BuildContext context,
    NotificationEntry entry,
    Color accent,
    bool isDark,
    int index,
  ) async {
    final action = await _showSwipeActionSheet(
      context,
      entry,
      accent,
      isDark,
    );

    switch (action) {
      case _NotificationSwipeAction.toggleRead:
        await _confirmToggleReadState(context, entry, accent, isDark);
        break;
      case _NotificationSwipeAction.delete:
        await _confirmDeleteNotification(context, entry, index, accent, isDark);
        break;
      case null:
        break;
    }
  }

  Future<_NotificationSwipeAction?> _showSwipeActionSheet(
    BuildContext context,
    NotificationEntry entry,
    Color accent,
    bool isDark,
  ) {
    final Color background = isDark ? const Color(0xFF1C1F25) : Colors.white;
    final Color dividerColor =
        (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.08 : 0.06);
    final bool markUnread = entry.isRead;

    return showModalBottomSheet<_NotificationSwipeAction>(
      context: context,
      backgroundColor: background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: accent.withOpacity(isDark ? 0.25 : 0.18),
                    child: Icon(
                      markUnread ? Icons.markunread : Icons.mark_email_read_outlined,
                      color: accent,
                    ),
                  ),
                  title: Text(
                    markUnread ? 'Đánh dấu chưa đọc' : 'Đánh dấu đã đọc',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? GlobalColors.darkPrimaryText
                          : GlobalColors.lightPrimaryText,
                    ),
                  ),
                  subtitle: Text(
                    'Áp dụng cho "${entry.message.title}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? GlobalColors.darkSecondaryText
                          : GlobalColors.lightSecondaryText,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(_NotificationSwipeAction.toggleRead),
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        Colors.redAccent.withOpacity(isDark ? 0.28 : 0.16),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'Xoá thông báo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? GlobalColors.darkPrimaryText
                          : GlobalColors.lightPrimaryText,
                    ),
                  ),
                  subtitle: Text(
                    'Bỏ "${entry.message.title}" khỏi danh sách',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? GlobalColors.darkSecondaryText
                          : GlobalColors.lightSecondaryText,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(_NotificationSwipeAction.delete),
                ),
                Divider(height: 1, color: dividerColor),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Huỷ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? GlobalColors.darkSecondaryText
                          : GlobalColors.lightSecondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmToggleReadState(
    BuildContext context,
    NotificationEntry entry,
    Color accent,
    bool isDark,
  ) async {
    final bool markUnread = entry.isRead;
    final bool confirmed = await _showConfirmationDialog(
      context,
      title: markUnread ? 'Đánh dấu chưa đọc?' : 'Đánh dấu đã đọc?',
      message:
          'Bạn có chắc muốn ${markUnread ? 'đánh dấu lại là chưa đọc' : 'đánh dấu là đã đọc'} "${entry.message.title}"?',
      confirmLabel: markUnread ? 'Chưa đọc' : 'Đã đọc',
      accent: accent,
      isDark: isDark,
    );
    if (!confirmed) return;

    _performToggleReadState(context, entry, accent);
  }

  void _performToggleReadState(
    BuildContext context,
    NotificationEntry entry,
    Color accent,
  ) {
    final bool markUnread = entry.isRead;
    final updated = markUnread
        ? notificationController.markAsUnread(entry)
        : notificationController.markAsRead(entry);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          markUnread
              ? 'Đã đánh dấu "${entry.message.title}" là chưa đọc'
              : 'Đã đánh dấu "${entry.message.title}" là đã đọc',
        ),
        action: SnackBarAction(
          label: 'HOÀN TÁC',
          textColor: accent,
          onPressed: () {
            if (markUnread) {
              notificationController.markAsRead(updated ?? entry);
            } else {
              notificationController.markAsUnread(updated ?? entry);
            }
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteNotification(
    BuildContext context,
    NotificationEntry entry,
    int index,
    Color accent,
    bool isDark,
  ) async {
    final bool confirmed = await _showConfirmationDialog(
      context,
      title: 'Xoá thông báo?',
      message: 'Bạn có chắc muốn xoá "${entry.message.title}" khỏi danh sách?',
      confirmLabel: 'Xoá',
      accent: Colors.redAccent,
      isDark: isDark,
    );
    if (!confirmed) return;

    _performDeleteNotification(context, entry, index, accent);
  }

  void _performDeleteNotification(
    BuildContext context,
    NotificationEntry entry,
    int index,
    Color accent,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    final removed = notificationController.remove(entry);
    if (!removed) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đã xoá "${entry.message.title}"'),
        action: SnackBarAction(
          label: 'HOÀN TÁC',
          textColor: accent,
          onPressed: () {
            notificationController.restore(entry, index: index);
          },
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color accent,
    required bool isDark,
  }) {
    final Color background = isDark ? const Color(0xFF1C1F25) : Colors.white;
    final Color titleColor =
        isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText;
    final Color messageColor =
        isDark ? GlobalColors.darkSecondaryText : GlobalColors.lightSecondaryText;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: messageColor,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel.toUpperCase()),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  Widget _buildSwipePill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
          context,
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
