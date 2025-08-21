import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';
import 'package:smart_factory/screen/login/controller/login_controller.dart';
import 'package:smart_factory/screen/login/controller/user_profile_manager.dart';
import 'package:smart_factory/lang/controller/language_controller.dart';
import 'package:smart_factory/screen/setting/widget/profile.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';
import 'package:smart_factory/lang/language_selection_screen.dart';
import 'package:smart_factory/generated/l10n.dart';

import '../../widget/custom_app_bar.dart';

class SettingTab extends StatelessWidget {
  const SettingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loginController = Get.find<LoginController>();
    final settingController = Get.find<SettingController>();
    final userProfileManager = Get.find<UserProfileManager>();
    final languageController = Get.find<LanguageController>();
    final S text = S.of(context);

    String _getLanguageName(String code) {
      switch (code) {
        case 'en':
          return 'English';
        case 'vi':
          return 'Tiếng Việt';
        case 'zh':
          return '中文';
        case 'ja':
          return '日本語';
        default:
          return 'Tiếng Việt';
      }
    }

    // Đảm bảo load trạng thái FaceID khi mở SettingTab
    loginController.loadFaceIdSetting();

    return Obx(() {
      final bool isDark = settingController.isDarkMode.value;
      final accent = isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight;
      final String languageName = _getLanguageName(languageController.currentLanguageCode);

      return Scaffold(
        backgroundColor: isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
        appBar: CustomAppBar(
          title: Text(text.settings),
          isDark: isDark,
          accent: GlobalColors.accentByIsDark(isDark),
          titleAlign: TextAlign.left,
        ),
        body: ListView(
          padding: const EdgeInsets.all(18.0),
          children: [
            // User info card
            Card(
              elevation: 5,
              color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 16),
                child: Row(
                  children: [
                    // Avatar với hiệu ứng glow
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [accent.withOpacity(0.20), accent.withOpacity(0.06)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.18),
                            blurRadius: 13,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: accent,
                        backgroundImage: userProfileManager.avatarUrl.value.isNotEmpty
                            ? NetworkImage(userProfileManager.avatarUrl.value)
                            : null,
                        child: userProfileManager.avatarUrl.value.isEmpty
                            ? Text(
                          userProfileManager.civetUserno.value.isNotEmpty
                              ? userProfileManager.civetUserno.value[0]
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProfileManager.cnName.value.isNotEmpty
                                ? userProfileManager.cnName.value
                                : text.username,
                            style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            userProfileManager.civetUserno.value.isNotEmpty
                                ? 'ID: ${userProfileManager.civetUserno.value}'
                                : text.no_id,
                            style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
                              color: isDark ? GlobalColors.labelDark : GlobalColors.labelLight,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: accent, size: 25),
                      onPressed: () => Get.to(() => const ProfileScreen()),
                      tooltip: text.personal_info,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Cài đặt cá nhân
            _settingTile(
              icon: Icons.person_outline,
              color: accent,
              title: text.personal_info,
              isDark: isDark,
              onTap: () => Get.to(() => const ProfileScreen()),
              trailing: Icons.arrow_forward_ios_rounded,
            ),

            // DARK MODE
            _settingTile(
              icon: Icons.brightness_6,
              color: accent,
              title: text.dark_mode,
              isDark: isDark,
              trailingWidget: Switch(
                value: settingController.isDarkMode.value,
                onChanged: (value) => settingController.toggleTheme(),
                activeColor: accent,
                inactiveThumbColor: Colors.grey,
              ),
            ),
            // BẬT/TẮT NHẬN DIỆN KHUÔN MẶT
            Obx(() => _settingTile(
              icon: Icons.face_retouching_natural,
              color: accent,
              title: text.quick_login_faceid,
              isDark: isDark,
              trailingWidget: Switch(
                value: loginController.isFaceIdEnabled.value,
                onChanged: (value) {
                  loginController.saveFaceIdSetting(value);
                  if (value) {
                    // Chỉ thông báo khi bật
                    Get.snackbar(
                      text.settings,
                      text.quick_login_faceid,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: accent.withOpacity(0.7),
                      colorText: Colors.white,
                    );
                  }
                },
                activeColor: accent,
                inactiveThumbColor: Colors.grey,
              ),
            )),

            // Đổi ngôn ngữ
            _settingTile(
              icon: Icons.language,
              color: accent,
              title: text.language,
              isDark: isDark,
              subtitle: languageName,
              trailing: Icons.arrow_forward_ios_rounded,
              onTap: () => Get.to(
                    () => const LanguageSelectionScreen(),
                arguments: {'fromSettings': true},
              ),
            ),

            // Phiên bản
            _settingTile(
              icon: Icons.info_outline,
              color: accent,
              title: text.version,
              isDark: isDark,
              subtitle: '1.0.0',
            ),

            // Đăng xuất
            _settingTile(
              icon: Icons.logout,
              color: Colors.red,
              title: text.logout,
              isDark: isDark,
              titleColor: Colors.red,
              onTap: () => loginController.logout(),
            ),

            const SizedBox(height: 26),
          ],
        ),
      );
    });
  }

  // Widget tile setting hiện đại
  Widget _settingTile({
    required IconData icon,
    required Color color,
    required String title,
    bool isDark = false,
    String? subtitle,
    IconData? trailing,
    Widget? trailingWidget,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return Card(
      elevation: 1.7,
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      margin: const EdgeInsets.symmetric(vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 26),
        title: Text(
          title,
          style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
            color: titleColor ??
                (isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText),
            fontWeight: FontWeight.w600,
            fontSize: 16.5,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
            color: isDark ? GlobalColors.labelDark : GlobalColors.labelLight,
          ),
        )
            : null,
        trailing: trailingWidget ??
            (trailing != null
                ? Icon(trailing,
                color: isDark
                    ? GlobalColors.darkSecondaryText
                    : GlobalColors.lightSecondaryText,
                size: 17)
                : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
        minLeadingWidth: 30,
      ),
    );
  }
}
