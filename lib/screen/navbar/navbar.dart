import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/screen/home/home_tab.dart';
import 'package:smart_factory/screen/home/widget/qr/qr_scan_screen.dart';
import 'package:smart_factory/screen/navbar/controller/navbar_controller.dart';
import 'package:smart_factory/screen/notification/notification_tab.dart';
import 'package:smart_factory/screen/setting/setting_tab.dart';
import 'package:smart_factory/screen/stp/stp_tab.dart';

import '../home/controller/home_controller.dart';
import '../notification/controller/notification_controller.dart';
import '../setting/controller/setting_controller.dart';

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
      'QR Scan',
      text.notification,
      text.settings,
    ];

    // Lazy cache cho QRScreen để tránh rebuild liên tục
    Widget? qrScreenCache;

    final navItems = [
      _NavItem(
        icon: Icons.home_rounded,
        label: tabLabels[0],
      ),
      _NavItem(
        icon: Icons.public_rounded,
        label: tabLabels[1],
      ),
      _NavItem(
        icon: Icons.qr_code_scanner,
        label: tabLabels[2],
      ),
      _NavItem(
        icon: Icons.notifications_active_rounded,
        label: tabLabels[3],
        isNotification: true,
      ),
      _NavItem(
        icon: Icons.settings,
        label: tabLabels[4],
      ),
    ];

    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        final bool isDesktop = sizingInfo.deviceScreenType == DeviceScreenType.desktop;
        final bool isTablet = sizingInfo.deviceScreenType == DeviceScreenType.tablet;
        final bool useRail = isDesktop || isTablet;
        final double railWidth = isDesktop ? 260 : 220;
        final double margin = isDesktop ? 24 : 16;

        return Obx(() {
          final currentIndex = navbarController.currentIndex.value;
          final bool isDark = settingController.isDarkMode.value;
          final Color activeColor = isDark ? Colors.blue[200]! : Colors.blue;
          final Color inactiveColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
          final int notificationCount = notificationController.unreadCount.value;

          final Widget stackBody = IndexedStack(
            index: currentIndex,
            children: [
              HomeTab(),
              SftpScreen(),
              currentIndex == 2
                  ? (qrScreenCache ??= QRScanScreen())
                  : const SizedBox.shrink(),
              NotificationTab(),
              SettingTab(),
            ],
          );

          if (!useRail) {
            return Scaffold(
              body: stackBody,
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
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
                  selectedItemColor: activeColor,
                  unselectedItemColor: inactiveColor,
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
                      icon: const Icon(Icons.qr_code_scanner),
                      label: tabLabels[2],
                    ),
                    BottomNavigationBarItem(
                      icon: _NotificationBadgeIcon(
                        icon: Icons.notifications_active_rounded,
                        color: inactiveColor,
                        activeColor: activeColor,
                        count: notificationCount,
                        isSelected: false,
                      ),
                      activeIcon: _NotificationBadgeIcon(
                        icon: Icons.notifications_active_rounded,
                        color: activeColor,
                        activeColor: activeColor,
                        count: notificationCount,
                        isSelected: true,
                      ),
                      label: tabLabels[3],
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.settings),
                      label: tabLabels[4],
                    ),
                  ],
                ),
              ),
            );
          }

          final navigationDestinations = navItems
              .map(
                (item) => NavigationRailDestination(
                  icon: item.isNotification
                      ? _NotificationBadgeIcon(
                          icon: item.icon,
                          color: inactiveColor,
                          activeColor: activeColor,
                          count: notificationCount,
                          isSelected: false,
                        )
                      : Icon(
                          item.icon,
                          color: inactiveColor,
                        ),
                  selectedIcon: item.isNotification
                      ? _NotificationBadgeIcon(
                          icon: item.icon,
                          color: activeColor,
                          activeColor: activeColor,
                          count: notificationCount,
                          isSelected: true,
                        )
                      : Icon(
                          item.icon,
                          color: activeColor,
                        ),
                  label: Text(item.label),
                ),
              )
              .toList();

          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        colors: [
                          Colors.black,
                          Colors.blueGrey.shade900,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.blueGrey.shade50,
                          Colors.blue.shade50,
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: railWidth,
                      margin: EdgeInsets.all(margin),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.55)
                            : Colors.white.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.blueGrey.withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.35)
                                : Colors.blueGrey.withOpacity(0.16),
                            blurRadius: 26,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: NavigationRail(
                        backgroundColor: Colors.transparent,
                        labelType: NavigationRailLabelType.all,
                        selectedIndex: currentIndex,
                        selectedLabelTextStyle: TextStyle(
                          color: activeColor,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelTextStyle: TextStyle(
                          color: inactiveColor,
                          fontWeight: FontWeight.w500,
                        ),
                        onDestinationSelected: (index) {
                          navbarController.changTab(index);
                        },
                        leading: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text.home,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: activeColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                text.welcome_factory,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isDark
                                          ? Colors.grey[300]
                                          : Colors.blueGrey,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        destinations: navigationDestinations,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: margin,
                          top: margin,
                          bottom: margin,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blueGrey.shade900.withOpacity(0.55)
                                  : Colors.white.withOpacity(0.86),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.24)
                                      : Colors.blueGrey.withOpacity(0.16),
                                  blurRadius: 32,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: stackBody,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    this.isNotification = false,
  });

  final IconData icon;
  final String label;
  final bool isNotification;
}

class _NotificationBadgeIcon extends StatelessWidget {
  const _NotificationBadgeIcon({
    required this.icon,
    required this.color,
    required this.activeColor,
    required this.count,
    required this.isSelected,
  });

  final IconData icon;
  final Color color;
  final Color activeColor;
  final int count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor = isSelected ? activeColor : color;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: resolvedColor),
        if (count > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
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
  }
}
