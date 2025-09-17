import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/Apiconfig.dart';
import '../../config/global_color.dart';
import '../../generated/l10n.dart';
import '../../model/notification_draft.dart';
import '../../model/notification_message.dart';
import '../../widget/custom_app_bar.dart';
import '../../widget/notification/notification_card.dart';
import '../../widget/notification/notification_compose_dialog.dart';
import '../setting/controller/setting_controller.dart';
import 'controller/notification_controller.dart';

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

  Future<void> _openComposer() async {
    final isDark = settingController.isDarkMode.value;
    final draft = await showDialog<NotificationDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NotificationComposeDialog(isDark: isDark),
    );

    if (draft == null) return;

    try {
      await notificationController.sendNotification(draft);
      if (!mounted) return;
      Get.snackbar(
        'Thành công',
        'Thông báo đã được gửi tới các thiết bị.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.85),
        colorText: Colors.white,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Gửi thông báo thất bại',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.85),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _confirmClear() async {
    final isDark = settingController.isDarkMode.value;
    final accent = GlobalColors.accentByIsDark(isDark);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xoá toàn bộ thông báo?'),
        content: const Text(
          'Thao tác này sẽ xoá toàn bộ thông báo đã gửi đi. Bạn có chắc chắn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xoá hết'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await notificationController.clearAll();
      if (!mounted) return;
      Get.snackbar(
        'Đã xoá',
        'Danh sách thông báo đã được dọn sạch.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.85),
        colorText: Colors.white,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Không thể xoá thông báo',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.85),
        colorText: Colors.white,
      );
    }
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
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    if (url.startsWith('/')) {
      return '$base$url';
    }
    return '$base/$url';
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
          SizedBox(height: screenHeight * 0.15),
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
                  : 'Nhấn nút “Gửi thông báo” để đẩy thông báo tới thiết bị.',
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
    List<NotificationMessage> notifications,
    bool isLoadingMore,
  ) {
    return RefreshIndicator(
      color: accent,
      onRefresh: _onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: notifications.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index >= notifications.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: accent),
              ),
            );
          }
          final message = notifications[index];
          return NotificationCard(
            message: message,
            isDark: isDark,
            accent: accent,
            onOpenLink: message.hasLink ? () => _openLink(message.link) : null,
            onOpenAttachment:
                message.hasAttachment ? () => _openAttachment(message) : null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S text = S.of(context);
    return Obx(() {
      final bool isDark = settingController.isDarkMode.value;
      final Color accent = GlobalColors.accentByIsDark(isDark);
      final notifications = notificationController.notifications;
      final isLoading = notificationController.isLoading.value;
      final isSending = notificationController.isSending.value;
      final isLoadingMore = notificationController.isLoadingMore.value;
      final errorMessage = notificationController.error.value;

      Widget bodyContent;
      if (isLoading && notifications.isEmpty) {
        bodyContent = const Center(child: CircularProgressIndicator());
      } else if (notifications.isEmpty) {
        bodyContent = _buildEmptyState(context, isDark, errorMessage, accent);
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
            IconButton(
              tooltip: 'Xoá toàn bộ',
              onPressed:
                  notifications.isEmpty ? null : () => _confirmClear(),
              icon: const Icon(Icons.delete_sweep_outlined),
              color: notifications.isEmpty
                  ? accent.withOpacity(0.3)
                  : accent,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: isSending ? null : _openComposer,
          icon: isSending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.add),
          label:
              Text(isSending ? 'Đang gửi...' : 'Gửi thông báo'),
          backgroundColor:
              isSending ? accent.withOpacity(0.6) : accent,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            if (errorMessage != null && errorMessage.trim().isNotEmpty)
              _buildErrorBanner(isDark, errorMessage, accent),
            Expanded(child: bodyContent),
          ],
        ),
      );
    });
  }
}
