import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:smart_factory/screen/navbar/controller/navbar_controller.dart';
import 'package:smart_factory/screen/home/home_tab.dart';
import 'package:smart_factory/screen/notification/notification_tab.dart';
import 'package:smart_factory/screen/setting/setting_tab.dart';
import 'package:smart_factory/screen/stp/stp_tab.dart';
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
    Get.put(HomeController());
    final SettingController settingController = Get.find<SettingController>();
    final NotificationController notificationController =
        Get.find<NotificationController>();
    final S text = S.of(context);

    final ResponsiveBreakpointsData breakpoints =
        ResponsiveBreakpoints.of(context);
    final bool useNavigationRail = breakpoints.largerOrEqualTo(DESKTOP);
    final bool isTabletLayout = breakpoints.largerOrEqualTo(TABLET);
    final bool extendNavigationRail = breakpoints.largerOrEqualTo('XL');

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

    return Obx(() {
      final int currentIndex = navbarController.currentIndex.value;
      final int unreadCount = notificationController.unreadCount.value;

      Widget buildNotificationIcon() {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_active_rounded),
            if (unreadCount > 0)
              Positioned(
                right: -8.w,
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
                    unreadCount > 99 ? '99+' : '$unreadCount',
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

      final Color selectedColor = settingController.isDarkMode.value
          ? Colors.blue[200]!
          : Colors.blue;
      final Color unselectedColor = settingController.isDarkMode.value
          ? Colors.grey[400]!
          : Colors.grey[600]!;

      if (useNavigationRail) {
        final Color railBackground = settingController.isDarkMode.value
            ? const Color(0xFF111827)
            : Colors.white;

        return Scaffold(
          body: Row(
            children: [
              Container(
                width: extendNavigationRail ? 220.w : 96.w,
                decoration: BoxDecoration(
                  color: railBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: NavigationRail(
                  selectedIndex: currentIndex,
                  extended: extendNavigationRail,
                  backgroundColor: Colors.transparent,
                  minWidth: 72.w,
                  minExtendedWidth: 220.w,
                  groupAlignment: -0.1,
                  onDestinationSelected: (index) {
                    navbarController.changTab(index);
                  },
                  labelType: extendNavigationRail
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  leading: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: extendNavigationRail ? 72.w : 40.w,
                        ),
                        SizedBox(height: 12.h),
                        if (extendNavigationRail)
                          Text(
                            'Smart Factory',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: selectedColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                  selectedIconTheme: IconThemeData(
                    size: 28.sp,
                    color: selectedColor,
                  ),
                  unselectedIconTheme: IconThemeData(
                    size: 26.sp,
                    color: unselectedColor,
                  ),
                  selectedLabelTextStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: selectedColor,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    fontSize: 12.sp,
                    color: unselectedColor,
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.home_rounded),
                      label: Text(tabLabels[0]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.public_rounded),
                      label: Text(tabLabels[1]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(tabLabels[2]),
                    ),
                    NavigationRailDestination(
                      icon: buildNotificationIcon(),
                      label: Text(tabLabels[3]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings),
                      label: Text(tabLabels[4]),
                    ),
                  ],
                ),
              ),
              Expanded(child: stackedBody),
            ],
          ),
        );
      }

      final Color navBackground = settingController.isDarkMode.value
          ? Colors.grey[900]!
          : Colors.white;

      return Scaffold(
        body: stackedBody,
        bottomNavigationBar: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTabletLayout ? 32.w : 0,
            vertical: isTabletLayout ? 12.h : 8.h,
          ),
          decoration: BoxDecoration(
            color: navBackground,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(18.r)),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Colors.transparent,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedItemColor: selectedColor,
              unselectedItemColor: unselectedColor,
              selectedLabelStyle: TextStyle(
                fontSize: isTabletLayout ? 14.sp : 12.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: isTabletLayout ? 12.sp : 11.sp,
              ),
              selectedIconTheme: IconThemeData(
                size: isTabletLayout ? 28.sp : 24.sp,
              ),
              unselectedIconTheme: IconThemeData(
                size: isTabletLayout ? 26.sp : 22.sp,
              ),
              currentIndex: currentIndex,
              onTap: (index) {
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
                  icon: buildNotificationIcon(),
                  label: tabLabels[3],
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings),
                  label: tabLabels[4],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
