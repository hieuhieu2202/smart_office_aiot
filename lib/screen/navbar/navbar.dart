import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
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

  Color _selectedColor(bool isDark) =>
      isDark ? Colors.blue[200]! : Colors.blueAccent;

  Color _unselectedColor(bool isDark) =>
      isDark ? Colors.grey[400]! : Colors.grey[600]!;

  Widget _buildNotificationIcon({
    required bool isDark,
    required int count,
    required Color color,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.notifications_active_rounded, color: color),
        if (count > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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

  Widget _buildBodyContent({
    required Widget child,
    required bool isDark,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double padding = isDesktop
        ? 64
        : isTablet
            ? 32
            : 16;
    final double maxWidth = isDesktop ? 1600 : 1100;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  Colors.grey.shade900,
                  Colors.blueGrey.shade800,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : LinearGradient(
                colors: [
                  Colors.grey.shade100,
                  Colors.blue.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.35)
                      : Colors.white.withOpacity(0.75),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.45 : 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());
    final SettingController settingController = Get.find<SettingController>();
    final NotificationController notificationController =
        Get.find<NotificationController>();
    final S text = S.of(context);

    final List<String> tabLabels = [
      text.home,
      'WinSCP',
      'QR Scan',
      text.notification,
      text.settings,
    ];

    Widget? qrScreenCache;

    return Obx(() {
      final currentIndex = navbarController.currentIndex.value;
      final bool isDark = settingController.isDarkMode.value;
      final breakpoints = ResponsiveBreakpoints.of(context);
      final bool isMobile = breakpoints.smallerThan(TABLET);
      final bool isTablet = breakpoints.between(TABLET, DESKTOP);
      final bool isDesktop = breakpoints.largerOrEqualTo(DESKTOP);
      final int unread = notificationController.unreadCount.value;

      final Widget stack = IndexedStack(
        index: currentIndex,
        children: [
          const HomeTab(),
          const SftpScreen(),
          currentIndex == 2
              ? (qrScreenCache ??= const QRScanScreen())
              : const SizedBox.shrink(),
          const NotificationTab(),
          const SettingTab(),
        ],
      );

      if (isMobile) {
        return Scaffold(
          body: stack,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color:
                      isDark ? Colors.black.withOpacity(0.18) : Colors.black12,
                  blurRadius: 18,
                  offset: const Offset(0, -6),
                ),
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
              selectedItemColor: _selectedColor(isDark),
              unselectedItemColor: _unselectedColor(isDark),
              currentIndex: currentIndex,
              onTap: navbarController.changTab,
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
                  icon: _buildNotificationIcon(
                    isDark: isDark,
                    count: unread,
                    color: _unselectedColor(isDark),
                  ),
                  activeIcon: _buildNotificationIcon(
                    isDark: isDark,
                    count: unread,
                    color: _selectedColor(isDark),
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

      final navigationDestinations = <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.home_rounded, color: _unselectedColor(isDark)),
          selectedIcon: Icon(Icons.home_rounded, color: _selectedColor(isDark)),
          label: Text(tabLabels[0]),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.public_rounded, color: _unselectedColor(isDark)),
          selectedIcon:
              Icon(Icons.public_rounded, color: _selectedColor(isDark)),
          label: Text(tabLabels[1]),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.qr_code_scanner, color: _unselectedColor(isDark)),
          selectedIcon:
              Icon(Icons.qr_code_scanner, color: _selectedColor(isDark)),
          label: Text(tabLabels[2]),
        ),
        NavigationRailDestination(
          icon: _buildNotificationIcon(
            isDark: isDark,
            count: unread,
            color: _unselectedColor(isDark),
          ),
          selectedIcon: _buildNotificationIcon(
            isDark: isDark,
            count: unread,
            color: _selectedColor(isDark),
          ),
          label: Text(tabLabels[3]),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings, color: _unselectedColor(isDark)),
          selectedIcon: Icon(Icons.settings, color: _selectedColor(isDark)),
          label: Text(tabLabels[4]),
        ),
      ];

      return Scaffold(
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isDesktop ? 240 : 96,
              padding: EdgeInsets.symmetric(vertical: isDesktop ? 32 : 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.black.withOpacity(0.3) : Colors.white70,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                      blurRadius: 20,
                      offset: const Offset(6, 0),
                    ),
                  ],
                ),
                child: NavigationRail(
                  selectedIndex: currentIndex,
                  extended: isDesktop,
                  labelType:
                      isDesktop ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
                  useIndicator: true,
                  indicatorColor:
                      _selectedColor(isDark).withOpacity(isDark ? 0.25 : 0.18),
                  onDestinationSelected: navbarController.changTab,
                  destinations: navigationDestinations,
                  selectedIconTheme: IconThemeData(color: _selectedColor(isDark)),
                  unselectedIconTheme:
                      IconThemeData(color: _unselectedColor(isDark)),
                  selectedLabelTextStyle: TextStyle(
                    color: _selectedColor(isDark),
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: _unselectedColor(isDark),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<bool>(isDesktop),
                  child: _buildBodyContent(
                    child: stack,
                    isDark: isDark,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
