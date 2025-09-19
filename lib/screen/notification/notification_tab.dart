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

class _NotificationTabState extends State<NotificationTab> {
  late final SettingController settingController;
  late final NotificationController notificationController;
  late final ScrollController _scrollController;
  String? _openSwipeKey;

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
            child: _SwipeableNotificationCard(
              key: ValueKey(entry.key),
              entry: entry,
              isDark: isDark,
              accent: accent,
              isOpen: _openSwipeKey == entry.key,
              onOpenChanged: (isOpen) {
                setState(() {
                  if (isOpen) {
                    _openSwipeKey = entry.key;
                  } else if (_openSwipeKey == entry.key) {
                    _openSwipeKey = null;
                  }
                });
              },
              onTap: () => _openDetails(entry),
              onToggleRead: () {
                setState(() {
                  if (_openSwipeKey == entry.key) {
                    _openSwipeKey = null;
                  }
                });
                _performToggleReadState(context, entry, accent);
              },
              onDelete: () {
                setState(() {
                  if (_openSwipeKey == entry.key) {
                    _openSwipeKey = null;
                  }
                });
                _performDeleteNotification(context, entry, index, accent);
              },
            ),
          );
        },
      ),
    );
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

class _SwipeableNotificationCard extends StatefulWidget {
  const _SwipeableNotificationCard({
    super.key,
    required this.entry,
    required this.isDark,
    required this.accent,
    required this.isOpen,
    required this.onOpenChanged,
    required this.onTap,
    required this.onToggleRead,
    required this.onDelete,
  });

  final NotificationEntry entry;
  final bool isDark;
  final Color accent;
  final bool isOpen;
  final ValueChanged<bool> onOpenChanged;
  final VoidCallback onTap;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  @override
  State<_SwipeableNotificationCard> createState() =>
      _SwipeableNotificationCardState();
}

class _SwipeableNotificationCardState extends State<_SwipeableNotificationCard>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 168;
  late final AnimationController _controller;
  late final Animation<double> _animation;
  double _dragExtent = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    if (widget.isOpen) {
      _controller.value = 1;
      _dragExtent = -_actionWidth;
    }
  }

  @override
  void didUpdateWidget(covariant _SwipeableNotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.key != oldWidget.entry.key) {
      if (widget.isOpen) {
        _controller.value = 1;
        _dragExtent = -_actionWidth;
      } else {
        _controller.value = 0;
        _dragExtent = 0;
      }
      return;
    }
    if (widget.isOpen && !oldWidget.isOpen) {
      _open();
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _close();
    }
  }

  void _open() {
    _controller.animateTo(1, curve: Curves.easeOut);
    _dragExtent = -_actionWidth;
  }

  void _close() {
    _controller.animateTo(0, curve: Curves.easeOut);
    _dragExtent = 0;
  }

  void _handleDragStart(DragStartDetails details) {
    _dragExtent = -_controller.value * _actionWidth;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragExtent += details.delta.dx;
    final double progress = (-_dragExtent / _actionWidth).clamp(0.0, 1.0);
    _controller.value = progress;
  }

  void _handleDragEnd(DragEndDetails details) {
    final bool shouldOpen =
        _controller.value > 0.4 || (details.primaryVelocity ?? 0) < -260;
    if (shouldOpen) {
      widget.onOpenChanged(true);
      _open();
    } else {
      widget.onOpenChanged(false);
      _close();
    }
  }

  void _handleCardTap() {
    if (_controller.value > 0.05) {
      widget.onOpenChanged(false);
      _close();
    } else {
      widget.onTap();
    }
  }

  void _handleToggleRead() {
    widget.onOpenChanged(false);
    _close();
    widget.onToggleRead();
  }

  void _handleDelete() {
    widget.onOpenChanged(false);
    _close();
    widget.onDelete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool markUnread = widget.entry.isRead;
    final Color markColor = markUnread ? Colors.orangeAccent : widget.accent;
    final Color deleteColor = Colors.redAccent;
    final Color paneBackground = widget.isDark
        ? const Color(0xFF1C1F25)
        : const Color(0xFFF2F4F8);

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: _actionWidth,
                decoration: BoxDecoration(
                  color: paneBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _SwipeActionButton(
                        color: markColor,
                        label: markUnread ? 'Chưa đọc' : 'Đã đọc',
                        icon: markUnread
                            ? Icons.markunread
                            : Icons.mark_email_read_outlined,
                        onTap: _handleToggleRead,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SwipeActionButton(
                        color: deleteColor,
                        label: 'Xoá',
                        icon: Icons.delete_outline,
                        onTap: _handleDelete,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final double offset = -_animation.value * _actionWidth;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: NotificationCard(
              message: widget.entry.message,
              isDark: widget.isDark,
              accent: widget.accent,
              isUnread: !widget.entry.isRead,
              onTap: _handleCardTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.color,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
