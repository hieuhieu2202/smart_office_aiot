import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';
import '../../../model/AppModel.dart';

class MonitoringScreen extends StatelessWidget {
  final AppProject project;

  const MonitoringScreen({super.key, required this.project});

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
        backgroundColor:
        isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
        iconTheme: IconThemeData(
          color: isDark
              ? GlobalColors.appBarDarkText
              : GlobalColors.appBarLightText,
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              project.icon ?? Icons.error,
              size: 100,
              color: isDark
                  ? GlobalColors.primaryButtonDark
                  : GlobalColors.primaryButtonLight,
            ),
            const SizedBox(height: 20),
            Text(
              'Tên: ${project.name}',
              style: GlobalTextStyles.bodyLarge(isDark: isDark).copyWith(
                color: isDark
                    ? GlobalColors.darkPrimaryText
                    : GlobalColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tiến độ: ${(project.progress * 100).toStringAsFixed(0)}%',
              style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
                color: isDark
                    ? GlobalColors.darkPrimaryText
                    : GlobalColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Trạng thái: ${project.status}',
              style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
                color: isDark
                    ? GlobalColors.labelDark
                    : GlobalColors.labelLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Đây là giao diện Giám sát',
              style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
                color: isDark
                    ? GlobalColors.darkPrimaryText
                    : GlobalColors.lightPrimaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
