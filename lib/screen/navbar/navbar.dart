import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/screen/home/home_tab.dart';
import 'package:smart_factory/screen/home/widget/qr/qr_scan_screen.dart';
import 'package:smart_factory/screen/navbar/controller/navbar_controller.dart';
import 'package:smart_factory/screen/notification/controller/notification_controller.dart';
import 'package:smart_factory/screen/notification/notification_tab.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';
import 'package:smart_factory/screen/setting/setting_tab.dart';
import 'package:smart_factory/screen/stp/stp_tab.dart';

import '../home/controller/home_controller.dart';

final NavbarController navbarController = Get.put(NavbarController());

class NavbarScreen extends StatelessWidget {
  const NavbarScreen({super.key});

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

    final List<IconData> tabIcons = const [
      Icons.dashboard_rounded,
      Icons.storage_rounded,
      Icons.qr_code_scanner_rounded,
      Icons.notifications_rounded,
      Icons.settings_rounded,
    ];

    final ResponsiveBreakpointsData breakpoints =
        ResponsiveBreakpoints.of(context);
    final bool useNavigationRail = breakpoints.largerOrEqualTo(DESKTOP);
    final bool extendNavigationRail = breakpoints.largerOrEqualTo('XL');
    final bool showBottomLabels = breakpoints.largerOrEqualTo(TABLET);

    Widget? qrScreenCache;

    return Obx(() {
      final int currentIndex = navbarController.currentIndex.value;
      final int unreadCount = notificationController.unreadCount.value;

      final Widget stackedBody = IndexedStack(
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

      final bool isDark = settingController.isDarkMode.value;
      final Color accentColor =
          isDark ? Colors.cyanAccent : const Color(0xFF1E88E5);

      if (useNavigationRail) {
        return Scaffold(
          body: Container(
            color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF2F5FA),
            child: Row(
              children: [
                _AdaptiveRail(
                  currentIndex: currentIndex,
                  onDestinationSelected: navbarController.changTab,
                  labels: tabLabels,
                  icons: tabIcons,
                  extend: extendNavigationRail,
                  unreadCount: unreadCount,
                  isDark: isDark,
                  accentColor: accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 28.w,
                      vertical: 28.h,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF101B2E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(26.r),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.24)
                                : Colors.blueGrey.withOpacity(0.14),
                            blurRadius: 32,
                            offset: const Offset(0, 26),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26.r),
                        child: stackedBody,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        extendBody: true,
        body: stackedBody,
        bottomNavigationBar: _AdaptiveBottomBar(
          currentIndex: currentIndex,
          onDestinationSelected: navbarController.changTab,
          labels: tabLabels,
          icons: tabIcons,
          unreadCount: unreadCount,
          isDark: isDark,
          accentColor: accentColor,
          showLabels: showBottomLabels,
        ),
      );
    });
  }
}

class _AdaptiveRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<String> labels;
  final List<IconData> icons;
  final bool extend;
  final int unreadCount;
  final bool isDark;
  final Color accentColor;

  const _AdaptiveRail({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.labels,
    required this.icons,
    required this.extend,
    required this.unreadCount,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(28.r);

    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Container(
        width: extend ? 260.w : 84.w,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101B2E) : Colors.white,
          borderRadius: borderRadius,
          border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.08) : Colors.blueGrey.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.28)
                  : Colors.blueGrey.withOpacity(0.14),
              blurRadius: 32,
              offset: const Offset(0, 26),
            ),
          ],
        ),
        child: NavigationRail(
          backgroundColor: Colors.transparent,
          extended: extend,
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          labelType:
              extend ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
          minExtendedWidth: 240.w,
          leading: Padding(
            padding: EdgeInsets.only(top: 24.h, bottom: 16.h),
            child: extend
                ? ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    leading: CircleAvatar(
                      radius: 18.r,
                      backgroundColor: accentColor.withOpacity(0.12),
                      child: Icon(
                        Icons.factory_outlined,
                        color: accentColor,
                        size: 20.sp,
                      ),
                    ),
                    title: Text(
                      'Smart Office',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF153B65),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'MBD Platform',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.blueGrey,
                        fontSize: 12.sp,
                      ),
                    ),
                  )
                : Center(
                    child: CircleAvatar(
                      radius: 22.r,
                      backgroundColor: accentColor.withOpacity(0.16),
                      child: Icon(
                        Icons.factory_rounded,
                        color: accentColor,
                        size: 20.sp,
                      ),
                    ),
                  ),
          ),
            destinations: List.generate(labels.length, (index) {
              return NavigationRailDestination(
                icon: _NavIcon(
                  icon: icons[index],
                  accentColor: accentColor,
                  unreadCount: index == 3 ? unreadCount : 0,
                  selected: false,
                ),
                selectedIcon: _NavIcon(
                  icon: icons[index],
                  accentColor: accentColor,
                  unreadCount: index == 3 ? unreadCount : 0,
                  selected: true,
                ),
                label: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
        ),
      ),
    );
  }
}

class _AdaptiveBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<String> labels;
  final List<IconData> icons;
  final int unreadCount;
  final bool isDark;
  final Color accentColor;
  final bool showLabels;

  const _AdaptiveBottomBar({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.labels,
    required this.icons,
    required this.unreadCount,
    required this.isDark,
    required this.accentColor,
    required this.showLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h + MediaQuery.of(context).padding.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101B2E) : Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.24)
                  : Colors.blueGrey.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: onDestinationSelected,
            backgroundColor: Colors.transparent,
            selectedItemColor: accentColor,
            unselectedItemColor:
                isDark ? Colors.white70 : Colors.blueGrey,
            showSelectedLabels: showLabels,
            showUnselectedLabels: showLabels,
            items: List.generate(labels.length, (index) {
              return BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: icons[index],
                  accentColor: accentColor,
                  unreadCount: index == 3 ? unreadCount : 0,
                  selected: false,
                ),
                activeIcon: _NavIcon(
                  icon: icons[index],
                  accentColor: accentColor,
                  unreadCount: index == 3 ? unreadCount : 0,
                  selected: true,
                ),
                label: labels[index],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final int unreadCount;
  final bool selected;

  const _NavIcon({
    required this.icon,
    required this.accentColor,
    required this.unreadCount,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final Widget baseIcon = Icon(
      icon,
      size: selected ? 24.sp : 22.sp,
      color: selected ? accentColor : null,
    );

    if (unreadCount <= 0) {
      return baseIcon;
    }

    final String badgeText = unreadCount > 99 ? '99+' : '$unreadCount';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        baseIcon,
        Positioned(
          right: -10.w,
          top: -6.h,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6.w,
              vertical: 2.h,
            ),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
