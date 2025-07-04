import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_factory/lang/controller/language_controller.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LanguageController languageController = Get.find<LanguageController>();
    final S text = S.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, String>> languages = [
      {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
      {'name': 'Vietnamese', 'code': 'vi', 'flag': '🇻🇳'},
      {'name': 'Chinese', 'code': 'zh', 'flag': '🇨🇳'},
    ];

    return Obx(() {
      final String currentLanguageCode = languageController.currentLanguageCode;
      return Scaffold(
        backgroundColor: isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
        appBar: AppBar(
          backgroundColor: isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
          elevation: 0,
          title: Text(
            text.select_language,
            style: GlobalTextStyles.bodyLarge(isDark: isDark).copyWith(
              color: isDark ? GlobalColors.appBarDarkText : GlobalColors.appBarLightText,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () async {
                if (currentLanguageCode.isEmpty) {
                  Get.snackbar(text.select_language, 'Please choose a language first');
                  return;
                }
                await languageController.setLanguage(currentLanguageCode);
                if (Get.arguments?['fromSettings'] == true) {
                  Get.back();
                } else {
                  final isLoggedIn = GetStorage().read('isLoggedIn') ?? false;
                  Get.offNamed(isLoggedIn ? '/navbar' : '/login');
                }
              },
            ),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: languages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final lang = languages[index];
            final isSelected = lang['code'] == currentLanguageCode;

            return InkWell(
              onTap: () {
                // ✅ Gọi setLanguage sẽ tự động update và lưu vào box
                languageController.setLanguage(lang['code']!);
              },
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight)
                            : (isDark ? GlobalColors.darkSecondaryText : GlobalColors.lightSecondaryText),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.22)
                              : Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lang['name']!,
                            style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
                              color: isDark
                                  ? GlobalColors.darkPrimaryText
                                  : GlobalColors.lightPrimaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
