import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/screen/home/controller/home_controller.dart';
import 'package:smart_factory/screen/home/home_tab.dart';
import 'package:smart_factory/screen/navbar/controller/navbar_controller.dart';
import 'package:smart_factory/screen/notification/controller/notification_controller.dart';
import 'package:smart_factory/screen/notification/notification_tab.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';
import 'package:smart_factory/screen/setting/setting_tab.dart';
import 'package:smart_factory/screen/stp/stp_tab.dart';

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

    final List<String> tabLabels = <String>[
      'Trang chủ',
      'WinSCP',
      'Thông báo',
      'Cài đặt',
    ];

    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        final bool useSideNavigation = sizingInfo.screenSize.width >= 900;

        return Obx(() {
          final int currentIndex = navbarController.currentIndex.value;

          final List<Widget> pages = <Widget>[
            const HomeTab(),
            const SftpScreen(),
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
                  boxShadow: <BoxShadow>[
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
                  onTap: navbarController.changTab,
                  items: <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_rounded),
                      label: tabLabels[0],
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.public_rounded),
                      label: tabLabels[1],
                    ),
                    BottomNavigationBarItem(
                      icon: Obx(() {
                        final int count = notificationController.unreadCount.value;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
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
                      label: tabLabels[2],
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.settings),
                      label: tabLabels[3],
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            body: Row(
              children: <Widget>[
                _SideNavigationBar(
                  tabLabels: tabLabels,
                  currentIndex: currentIndex,
                  onTap: navbarController.changTab,
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
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.22 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List<Widget>.generate(tabLabels.length, (int index) {
          final bool selected = index == currentIndex;
          Widget icon;

          switch (index) {
            case 0:
              icon = const Icon(Icons.home_rounded);
              break;
            case 1:
              icon = const Icon(Icons.public_rounded);
              break;
            case 2:
              icon = Obx(() {
                final int count = notificationController.unreadCount.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
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
              });
              break;
            default:
              icon = const Icon(Icons.settings);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 74,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? indicatorColor.withOpacity(isDarkMode ? 0.18 : 0.20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconTheme(
                      data: IconThemeData(
                        color: selected ? indicatorColor : inactiveColor,
                        size: 22,
                      ),
                      child: icon,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tabLabels[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? indicatorColor : inactiveColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
