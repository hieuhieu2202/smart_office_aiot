import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

    return Obx(() {
      final currentIndex = navbarController.currentIndex.value;

      return Scaffold(
        body: IndexedStack(
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
                icon: const Icon(Icons.qr_code_scanner),
                label: tabLabels[2],
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
    });
  }
}
