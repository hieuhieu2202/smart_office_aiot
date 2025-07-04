import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';
import 'package:smart_factory/screen/home/controller/home_controller.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/screen/login/controller/login_controller.dart';
import '../../util/dashboard_labels.dart';
import '../setting/controller/setting_controller.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final HomeController homeController = Get.find<HomeController>();
  final LoginController loginController = Get.find<LoginController>();
  final SettingController settingController = Get.find<SettingController>();

  // Map để lưu PageController cho từng module
  final Map<int, PageController> _pageControllers = {};
  final Map<int, int> _currentPageIndexes = {};

  // Helper: chia subProjects thành các "trang", mỗi trang tối đa 4 cái
  List<List<T>> chunk<T>(List<T> list, int size) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  @override
  void dispose() {
    for (final controller in _pageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S text = S.of(context);
    final bool isDark = settingController.isDarkMode.value;

    return Obx(() {
      return Scaffold(
        backgroundColor: isDark
            ? GlobalColors.bodyDarkBg
            : GlobalColors.bodyLightBg,
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          itemCount: homeController.projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, idx) {
            final project = homeController.projects[idx];
            final subProjects = project.subProjects;
            final pages = chunk(subProjects, 4); // Mỗi page 4 con
            final pageController = _pageControllers.putIfAbsent(idx, () => PageController());
            final currentPageIndex = _currentPageIndexes[idx] ?? 0;

            return Card(
              elevation: 3,
              color: isDark
                  ? GlobalColors.cardDarkBg
                  : GlobalColors.cardLightBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Module header
                    Row(
                      children: [
                        Icon(
                          project.icon ?? Icons.dashboard,
                          size: 36,
                          color: isDark
                              ? GlobalColors.primaryButtonDark
                              : GlobalColors.primaryButtonLight,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            getModuleLabel(context, project.name),
                            style: GlobalTextStyles.bodyLarge(isDark: isDark).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? GlobalColors.primaryButtonDark.withOpacity(0.16)
                                : GlobalColors.primaryButtonLight.withOpacity(0.11),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            getStatusText(context, project.status),
                            style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                              color: isDark
                                  ? GlobalColors.primaryButtonDark
                                  : GlobalColors.primaryButtonLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Subprojects PageView + indicator
                    subProjects.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          text.no_id,
                          style: GlobalTextStyles.bodySmall(isDark: isDark),
                        ),
                      ),
                    )
                        : Column(
                      children: [
                        SizedBox(
                          height: 120,
                          child: PageView.builder(
                            controller: pageController,
                            itemCount: pages.length,
                            onPageChanged: (page) {
                              setState(() {
                                _currentPageIndexes[idx] = page;
                              });
                            },
                            itemBuilder: (context, pageIdx) {
                              final pageSubs = pages[pageIdx];
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(4, (i) {
                                  if (i >= pageSubs.length) {
                                    // chỗ rỗng
                                    return Expanded(child: SizedBox());
                                  }
                                  final sub = pageSubs[i];
                                  return Expanded(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? GlobalColors.cardDarkBg.withOpacity(0.94)
                                            : GlobalColors.cardLightBg.withOpacity(0.96),
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: isDark
                                              ? GlobalColors.primaryButtonDark.withOpacity(0.14)
                                              : GlobalColors.primaryButtonLight.withOpacity(0.12),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? Colors.black.withOpacity(0.06)
                                                : Colors.black12,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          Get.snackbar(
                                            getModuleLabel(context, project.name),
                                            '${getCardLabel(context, sub.name)} - ${getStatusText(context, sub.status)}',
                                            snackPosition: SnackPosition.BOTTOM,
                                            duration: const Duration(seconds: 2),
                                            backgroundColor: isDark
                                                ? GlobalColors.cardDarkBg.withOpacity(0.97)
                                                : GlobalColors.cardLightBg.withOpacity(0.97),
                                            colorText: isDark
                                                ? GlobalColors.darkPrimaryText
                                                : GlobalColors.lightPrimaryText,
                                            borderRadius: 12,
                                          );
                                        },
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              sub.icon ?? Icons.widgets,
                                              size: 29,
                                              color: isDark
                                                  ? GlobalColors.primaryButtonDark
                                                  : GlobalColors.primaryButtonLight,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              getCardLabel(context, sub.name),
                                              style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? GlobalColors.darkPrimaryText
                                                    : GlobalColors.lightPrimaryText,
                                                fontSize: 12.5,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (sub.status.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                getStatusText(context, sub.status),
                                                style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 10.2,
                                                  color: isDark
                                                      ? GlobalColors.primaryButtonDark
                                                      : GlobalColors.primaryButtonLight,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ]
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SmoothPageIndicator(
                          controller: pageController,
                          count: pages.length,
                          effect: WormEffect(
                            dotColor: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                            activeDotColor: isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight,
                            dotHeight: 8,
                            dotWidth: 8,
                            spacing: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
