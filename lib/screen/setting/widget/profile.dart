import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';
import 'package:smart_factory/screen/login/controller/user_profile_manager.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';
import 'package:smart_factory/generated/l10n.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileManager = Get.find<UserProfileManager>();
    final settingController = Get.find<SettingController>();
    final S text = S.of(context);

    return Obx(() {
      final isDark = settingController.isDarkMode.value;
      final accentColor =
          isDark
              ? GlobalColors.primaryButtonDark
              : GlobalColors.primaryButtonLight;

      return Scaffold(
        backgroundColor:
            isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
        body: SafeArea(
          child: Column(
            children: [
              // AppBar tùy biến
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color:
                            isDark
                                ? GlobalColors.darkPrimaryText
                                : GlobalColors.lightPrimaryText,
                        size: 28,
                      ),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Text(
                        text.personal_info, // đa ngôn ngữ
                        style: GlobalTextStyles.bodyLarge(
                          isDark: isDark,
                        ).copyWith(
                          color:
                              isDark
                                  ? GlobalColors.darkPrimaryText
                                  : GlobalColors.lightPrimaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 46), // Giữ đối xứng AppBar
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Avatar + Name Card
                      Container(
                        margin: const EdgeInsets.only(top: 16, bottom: 10),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow ngoài avatar
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      accentColor.withOpacity(0.18),
                                      accentColor.withOpacity(0.02),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.32),
                                      blurRadius: 22,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: accentColor,
                                backgroundImage:
                                    userProfileManager
                                            .avatarUrl
                                            .value
                                            .isNotEmpty
                                        ? NetworkImage(
                                          userProfileManager.avatarUrl.value,
                                        )
                                        : null,
                                child:
                                    userProfileManager.avatarUrl.value.isEmpty
                                        ? Text(
                                          userProfileManager
                                                  .civetUserno
                                                  .value
                                                  .isNotEmpty
                                              ? userProfileManager
                                                  .civetUserno
                                                  .value[0]
                                              : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28,
                                          ),
                                        )
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        color:
                            isDark
                                ? GlobalColors.cardDarkBg.withOpacity(0.99)
                                : GlobalColors.cardLightBg.withOpacity(0.99),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 17,
                            horizontal: 18,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                userProfileManager.cnName.value.isNotEmpty
                                    ? userProfileManager.cnName.value
                                    : text.username,
                                style: GlobalTextStyles.bodyLarge(
                                  isDark: isDark,
                                ).copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.badge,
                                    size: 18,
                                    color: accentColor.withOpacity(0.65),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    userProfileManager
                                            .civetUserno
                                            .value
                                            .isNotEmpty
                                        ? "ID: ${userProfileManager.civetUserno.value}"
                                        : text.no_id,
                                    style: GlobalTextStyles.bodySmall(
                                      isDark: isDark,
                                    ).copyWith(
                                      color:
                                          isDark
                                              ? GlobalColors.labelDark
                                              : GlobalColors.labelLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Các thông tin chi tiết
                      ProfileDetailItem(
                        icon: Icons.person_outline,
                        label: text.fullname ?? "Fullname",
                        value: userProfileManager.vnName.value,
                        isDark: isDark,
                      ),
                      ProfileDetailItem(
                        icon: Icons.assignment_ind,
                        label: text.job_title ?? "Job title",
                        value: userProfileManager.jobTitle.value,
                        isDark: isDark,
                      ),
                      ProfileDetailItem(
                        icon: Icons.account_tree_outlined,
                        label: text.department ?? "Department",
                        value: userProfileManager.department.value,
                        isDark: isDark,
                      ),
                      ProfileDetailItem(
                        icon: Icons.info_outline_rounded,
                        label: text.department_detail ?? "Department Detail",
                        value: userProfileManager.departmentDetail.value,
                        isDark: isDark,
                      ),
                      ProfileDetailItem(
                        icon: Icons.location_on,
                        label: text.location ?? "Location",
                        value: userProfileManager.location.value,
                        isDark: isDark,
                      ),
                      ProfileDetailItem(
                        icon: Icons.groups_3_outlined,
                        label: text.managers ?? "Managers",
                        value: userProfileManager.managers.value,
                        isDark: isDark,
                      ),
                      ProfileDetailItem(
                        icon: Icons.event,
                        label: text.hire_date ?? "Hire Date",
                        value: userProfileManager.hireDate.value,
                        isDark: isDark,
                      ),
                      ProfileDetailItem(
                        icon: Icons.email,
                        label: text.email ?? "Email",
                        value: userProfileManager.email.value,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 26),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// Widget info row đẹp từng dòng
class ProfileDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const ProfileDetailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isDark
            ? GlobalColors.primaryButtonDark
            : GlobalColors.primaryButtonLight;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color:
          isDark
              ? GlobalColors.cardDarkBg.withOpacity(0.97)
              : GlobalColors.cardLightBg.withOpacity(0.98),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: accent, size: 28),
        title: Text(
          label,
          style: GlobalTextStyles.bodyMedium(
            isDark: isDark,
          ).copyWith(color: accent, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          value.isNotEmpty ? value : S.of(context).not_updated ?? "N/A",
          style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
            color: isDark ? GlobalColors.labelDark : GlobalColors.labelLight,
            fontSize: 15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
