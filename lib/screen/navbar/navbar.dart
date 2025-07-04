import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/navbar/controller/navbar_controller.dart';
import 'package:smart_factory/screen/history/history_tab.dart';
import 'package:smart_factory/screen/home/home_tab.dart';
import 'package:smart_factory/screen/notification/notification_tab.dart';
import 'package:smart_factory/screen/setting/setting_tab.dart';
import 'package:smart_factory/screen/stp/stp_tab.dart';
import '../home/controller/home_controller.dart';
import '../setting/controller/setting_controller.dart';
import 'package:smart_factory/generated/l10n.dart';

class NavbarScreen extends StatelessWidget {
  const NavbarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());
    final NavbarController navbarController = Get.put(NavbarController());
    final SettingController settingController = Get.find<SettingController>();
    final S text = S.of(context);

    // Đa ngôn ngữ cho label
    final List<String> tabLabels = [
      text.home ?? "Home",
      "WinSCP", // Nếu bạn muốn đa ngôn ngữ đổi sang text.sftp hoặc tương tự
      text.history ?? "History",
      text.notification ?? "Notification",
      text.settings ?? "Setting",
    ];

    return Scaffold(
      body: Obx(
            () => IndexedStack(
          index: navbarController.currentIndex.value,
          children:  [
            HomeTab(),
            SftpScreen(),
            HistoryTab(),
            NotificationTab(),
            SettingTab(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
            () {
          final isDark = settingController.isDarkMode.value;
          final accent = isDark ? Colors.blue[200] : Colors.blue;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.13) : Colors.grey.withOpacity(0.10),
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
              selectedItemColor: accent,
              unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
              currentIndex: navbarController.currentIndex.value,
              onTap: (index) => navbarController.changTab(index),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: tabLabels[0],
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.public_rounded),
                  label: tabLabels[1],
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: tabLabels[2],
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_active_rounded),
                  label: tabLabels[3],
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: tabLabels[4],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
