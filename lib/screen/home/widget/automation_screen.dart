import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';
import '../../../model/AppModel.dart';
import 'automation_screen/avi_screen.dart';
import 'automation_screen/project_detail_screen.dart';

class AutomationScreen extends StatelessWidget {
  final AppProject project;

  const AutomationScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Get.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? GlobalColors.bodyDarkBg
          : GlobalColors.bodyLightBg,
      appBar: AppBar(
        title: Text(
          project.name,
          style: GlobalTextStyles.bodyLarge(isDark: isDark).copyWith(
            color: isDark
                ? GlobalColors.appBarDarkText
                : GlobalColors.appBarLightText,
          ),
        ),
        backgroundColor: isDark
            ? GlobalColors.appBarDarkBg
            : GlobalColors.appBarLightBg,
        iconTheme: IconThemeData(
          color: isDark
              ? GlobalColors.appBarDarkText
              : GlobalColors.appBarLightText,
        ),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Danh sách dự án Automation',
                style: GlobalTextStyles.bodyLarge(isDark: isDark).copyWith(
                  color: isDark
                      ? GlobalColors.darkPrimaryText
                      : GlobalColors.lightPrimaryText,
                ),
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final subProject = project.subProjects[index];
                return InkWell(
                  onTap: () {
                    switch (subProject.screenType) {
                      case 'automation':
                        Get.to(() => ProjectDetailScreen(project: subProject));
                        break;
                      case 'avi':
                        Get.to(() => AVIScreen(project: subProject));
                        break;
                      default:
                        Get.snackbar('Lỗi', 'Giao diện không được hỗ trợ');
                    }
                  },
                  child: Card(
                    elevation: 2,
                    color: isDark
                        ? GlobalColors.cardDarkBg
                        : GlobalColors.cardLightBg,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          subProject.icon ?? Icons.error,
                          size: 60,
                          color: isDark
                              ? GlobalColors.primaryButtonDark
                              : GlobalColors.primaryButtonLight,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          subProject.name,
                          style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
                            color: isDark
                                ? GlobalColors.darkPrimaryText
                                : GlobalColors.lightPrimaryText,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: project.subProjects.length,
            ),
          ),
        ],
      ),
    );
  }
}
