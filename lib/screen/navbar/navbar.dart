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
        final bool isDarkTheme = settingController.isDarkMode.value;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: isDarkTheme
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0B1220), Color(0xFF111D32)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF8FAFF), Color(0xFFE6EEFF)],
                    ),
            ),
            child: Row(
              children: [
                _DesktopSidebar(
                  isDark: isDarkTheme,
                  compact: !extendNavigationRail,
                  labels: tabLabels,
                  currentIndex: currentIndex,
                  unreadCount: unreadCount,
                  onDestinationSelected: navbarController.changTab,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 28.w,
                      vertical: 28.h,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkTheme
                            ? const Color(0xFF101B2D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(28.r),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkTheme
                                ? Colors.black.withOpacity(0.22)
                                : Colors.blueGrey.withOpacity(0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 24),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28.r),
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

class _DesktopSidebar extends StatelessWidget {
  final bool isDark;
  final bool compact;
  final List<String> labels;
  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onDestinationSelected;

  const _DesktopSidebar({
    required this.isDark,
    required this.compact,
    required this.labels,
    required this.currentIndex,
    required this.unreadCount,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double sidebarWidth = compact ? 240.w : 300.w;
    final double horizontalPadding = compact ? 20.w : 28.w;
    final double topPadding = 32.h;

    final List<_SidebarDestinationData> destinations = [
      _SidebarDestinationData(icon: Icons.home_rounded, label: labels[0]),
      _SidebarDestinationData(icon: Icons.cloud_outlined, label: labels[1]),
      _SidebarDestinationData(icon: Icons.qr_code_scanner, label: labels[2]),
      _SidebarDestinationData(
        icon: Icons.notifications_active_outlined,
        label: labels[3],
        badge: unreadCount,
      ),
      _SidebarDestinationData(icon: Icons.settings_suggest_rounded, label: labels[4]),
    ];

    final List<Color> gradient = isDark
        ? [const Color(0xFF0B0F2A), const Color(0xFF1C2A4A)]
        : [const Color(0xFF0047FF), const Color(0xFF091C54)];

    return SizedBox(
      width: sidebarWidth,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topPadding,
          horizontalPadding,
          28.h,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(32.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.25),
                blurRadius: 36,
                offset: const Offset(0, 20),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.18 : 0.28),
              width: 1.1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 16.w : 20.w,
                  vertical: 12.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: compact ? 48.w : 58.w,
                          height: compact ? 48.w : 58.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Image.asset('assets/images/logo.png'),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Factory',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 18.sp : 20.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'MBD-Factory Dashboard',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: compact ? 12.sp : 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Chọn một khu vực để theo dõi dữ liệu theo thời gian thực.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: compact ? 12.5.sp : 13.5.sp,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12.w : 18.w,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final destination = destinations[index];
                    return _SidebarMenuButton(
                      data: destination,
                      selected: currentIndex == index,
                      isDark: isDark,
                      compact: compact,
                      onTap: () => onDestinationSelected(index),
                    );
                  },
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemCount: destinations.length,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16.w : 20.w,
                  20.h,
                  compact ? 16.w : 20.w,
                  24.h,
                ),
                child: Container(
                  padding: EdgeInsets.all(compact ? 16.w : 20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trạng thái hệ thống',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 14.sp : 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Icon(
                            Icons.wifi_tethering,
                            color: Colors.lightGreenAccent.withOpacity(0.9),
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Online • Đồng bộ dữ liệu thành công',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.78),
                                fontSize: compact ? 12.sp : 12.5.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarDestinationData {
  final IconData icon;
  final String label;
  final int badge;

  const _SidebarDestinationData({
    required this.icon,
    required this.label,
    this.badge = 0,
  });
}

class _SidebarMenuButton extends StatelessWidget {
  final _SidebarDestinationData data;
  final bool selected;
  final bool isDark;
  final bool compact;
  final VoidCallback onTap;

  const _SidebarMenuButton({
    required this.data,
    required this.selected,
    required this.isDark,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.white;
    final Color iconColor = baseColor.withOpacity(selected ? 1 : 0.82);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16.w : 20.w,
            vertical: compact ? 12.h : 14.h,
          ),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(isDark ? 0.18 : 0.26)
                : Colors.white.withOpacity(isDark ? 0.08 : 0.14),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: selected
                  ? Colors.white.withOpacity(isDark ? 0.55 : 0.75)
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              Icon(
                data.icon,
                color: iconColor,
                size: compact ? 22.sp : 24.sp,
              ),
              SizedBox(width: compact ? 14.w : 16.w),
              Expanded(
                child: Text(
                  data.label,
                  style: TextStyle(
                    color: baseColor,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 14.sp : 15.sp,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (data.badge > 0)
                _SidebarBadge(
                  value: data.badge,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBadge extends StatelessWidget {
  final int value;

  const _SidebarBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final String label = value > 99 ? '99+' : '$value';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
