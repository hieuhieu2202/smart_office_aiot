import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:smart_factory/screen/navbar/controller/navbar_controller.dart';
import 'package:smart_factory/screen/home/home_tab.dart';
import 'package:smart_factory/screen/notification/notification_tab.dart';
import 'package:smart_factory/screen/setting/setting_tab.dart';
import 'package:smart_factory/screen/stp/stp_tab.dart';
import 'package:smart_factory/screen/camera/camera_capture_page.dart';
import 'package:smart_factory/screen/camera/camera_menu_screen.dart';
import '../home/controller/home_controller.dart';
import '../setting/controller/setting_controller.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/screen/home/widget/qr/qr_scan_screen.dart';
import '../notification/controller/notification_controller.dart';

final NavbarController navbarController = Get.put(NavbarController());

class NavbarScreen extends StatelessWidget {
  const NavbarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🟢 QRScanScreen được dựng lại!');
    Get.put(HomeController());
    final SettingController settingController = Get.find<SettingController>();
    final NotificationController notificationController =
        Get.find<NotificationController>();
    final S text = S.of(context);

    // Danh sách nhãn (hỗ trợ đa ngôn ngữ)
    final List<String> tabLabels = [
      text.home,
      "WinSCP",
      'Capture',
      'QR Scan',
      text.notification,
      text.settings,
    ];

    // Lazy cache cho QRScreen để tránh rebuild liên tục
    Widget? qrScreenCache;
    Widget? cameraScreenCache;

    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        final bool useSideNavigation = sizingInfo.screenSize.width >= 900;

        return Obx(() {
          final currentIndex = navbarController.currentIndex.value;

          final pages = [
            const HomeTab(),
            const SftpScreen(),
            currentIndex == 2
                ? (cameraScreenCache ??= const CameraMenuScreen())
                : const SizedBox.shrink(),
            currentIndex == 3
                ? (qrScreenCache ??= const QRScanScreen())
                : const SizedBox.shrink(),
            const NotificationTab(),
            const SettingTab(),
          ];

          if (!useSideNavigation) {
            return Scaffold(
              body: IndexedStack(
                index: currentIndex,
                children: pages,
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: settingController.isDarkMode.value
                      ? Colors.grey[900]
                      : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: settingController.isDarkMode.value
                          ? Colors.black.withOpacity(0.13)
                          : Colors.grey.withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    )
                  ],
                ),
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedFontSize: 13,
                  unselectedFontSize: 12,
                  selectedItemColor: settingController.isDarkMode.value
                      ? Colors.blue[200]
                      : Colors.blue,
                  unselectedItemColor: settingController.isDarkMode.value
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  currentIndex: currentIndex,
                  onTap: (index) {
                    print('🟦 Chuyển tab sang index: $index');
                    navbarController.changTab(index);
                  },
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_rounded),
                      label: tabLabels[0],
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.public_rounded),
                      label: tabLabels[1],
                    ),
                    BottomNavigationBarItem(
                      icon: const Text(
                        '📸',
                        style: TextStyle(fontSize: 22),
                      ),
                      label: tabLabels[2],
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: tabLabels[3],
                    ),
                    BottomNavigationBarItem(
                      icon: Obx(() {
                        final count = notificationController.unreadCount.value;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_active_rounded),
                            if (count > 0)
                              Positioned(
                                right: -6,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                      label: tabLabels[4],
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.settings),
                      label: tabLabels[5],
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            body: Row(
              children: [
                _SideNavigationBar(
                  tabLabels: tabLabels,
                  currentIndex: currentIndex,
                  onTap: (index) {
                    print('🟦 Chuyển tab sang index: $index');
                    navbarController.changTab(index);
                  },
                  isDarkMode: settingController.isDarkMode.value,
                  notificationController: notificationController,
                ),
                Expanded(
                  child: IndexedStack(
                    index: currentIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _SideNavigationBar extends StatelessWidget {
  const _SideNavigationBar({
    required this.tabLabels,
    required this.currentIndex,
    required this.onTap,
    required this.isDarkMode,
    required this.notificationController,
  });

  final List<String> tabLabels;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDarkMode;
  final NotificationController notificationController;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color indicatorColor =
        isDarkMode ? Colors.blue[200]! : Colors.blueAccent.shade200;
    final Color inactiveColor =
        isDarkMode ? Colors.grey[400]! : Colors.grey[500]!;

    return Container(
      width: 96,
      height: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(isDarkMode ? 0.92 : 0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.22 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < tabLabels.length; i++)
            _SideNavItem(
              label: tabLabels[i],
              icon: _iconForIndex(i),
              isSelected: currentIndex == i,
              onTap: () => onTap(i),
              indicatorColor: indicatorColor,
              inactiveColor: inactiveColor,
              badgeCount: i == 4
                  ? notificationController.unreadCount.value
                  : 0,
            ),
        ],
      ),
    );
  }

  Widget _iconForIndex(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.home_rounded);
      case 1:
        return const Icon(Icons.public_rounded);
      case 2:
        return const Text(
          '📸',
          style: TextStyle(fontSize: 24),
        );
      case 3:
        return const Icon(Icons.qr_code_scanner);
      case 4:
        return const Icon(Icons.notifications_active_rounded);
      case 5:
      default:
        return const Icon(Icons.settings);
    }
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.indicatorColor,
    required this.inactiveColor,
    this.badgeCount = 0,
  });

  final String label;
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color indicatorColor;
  final Color inactiveColor;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = isSelected ? indicatorColor : inactiveColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? indicatorColor.withOpacity(0.16) : null,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        color: baseColor,
                        size: 28,
                      ),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: baseColor, fontSize: 24),
                        child: icon,
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: baseColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
