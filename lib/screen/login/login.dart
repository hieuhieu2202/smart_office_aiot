import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';
import 'package:smart_factory/screen/login/controller/login_controller.dart';

import '../../widget/login_logo.dart';
import '../../widget/login_title.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();
    final SettingController settingController = Get.find<SettingController>();
    final S text = S.of(context);

    final bool isDark = settingController.isDarkMode.value;

    final List<Color> cardGradient = isDark
        ? [
      Colors.black.withOpacity(0.7),
      Colors.blueGrey.shade900.withOpacity(0.74),
      Colors.blueGrey.shade800.withOpacity(0.66),
    ]
        : [
      const Color(0xFFB0E0FF).withOpacity(0.73),
      const Color(0xFF6FC6FF).withOpacity(0.74),
      const Color(0xFF2196F3).withOpacity(0.65),
    ];
    final Color borderColor = isDark
        ? Colors.cyanAccent.withOpacity(0.37)
        : const Color(0xFF5BC2FF).withOpacity(0.65);
    final Color labelColor = isDark
        ? Colors.cyanAccent
        : const Color(0xFF174076);
    final Color inputFill = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.blue[50]!.withOpacity(0.24);
    final Color textColor = isDark
        ? Colors.white
        : const Color(0xFF13293D);

    // Icon màu nổi bật theo theme
    final Color iconColor = isDark
        ? Colors.cyanAccent
        : Colors.blueAccent;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ẢNH NỀN GỐC
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    isDark
                        ? 'assets/images/background_dark.png'
                        : 'assets/images/background_light.png',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    isDark
                        ? Colors.black.withOpacity(0.33)
                        : Colors.white.withOpacity(0.05),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 440),
                  child: FractionallySizedBox(
                    widthFactor: 0.9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: cardGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: borderColor,
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.cyanAccent.withOpacity(0.18)
                                    : Colors.lightBlueAccent.withOpacity(0.11),
                                blurRadius: 22,
                                spreadRadius: 1,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(22.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LoginLogo(isDark: isDark),
                                  const SizedBox(height: 4),
                                  LoginTitle(isDark: isDark),
                                  const SizedBox(height: 17),
                                  // Username
                                  TextField(
                                    decoration: InputDecoration(
                                      labelText: text.username,
                                      labelStyle: TextStyle(
                                        color: labelColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        shadows: [
                                          Shadow(
                                            color: Colors.white.withOpacity(isDark ? 0.18 : 0.11),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      filled: true,
                                      fillColor: inputFill,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: borderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: borderColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      shadows: [
                                        Shadow(
                                          color: isDark
                                              ? Colors.cyanAccent.withOpacity(0.07)
                                              : Colors.blueAccent.withOpacity(0.05),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    onChanged: controller.setUsername,
                                  ),
                                  const SizedBox(height: 15),
                                  // Password
                                  Obx(() => TextField(
                                    decoration: InputDecoration(
                                      labelText: text.password,
                                      labelStyle: TextStyle(
                                        color: labelColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        shadows: [
                                          Shadow(
                                            color: Colors.white.withOpacity(isDark ? 0.16 : 0.08),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      filled: true,
                                      fillColor: inputFill,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: borderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: borderColor,
                                          width: 2,
                                        ),
                                      ),
                                      suffixIcon: GestureDetector(
                                        onTap: () {
                                          controller.showPassword.value =
                                          !controller.showPassword.value;
                                        },
                                        child: Icon(
                                          controller.showPassword.value
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: iconColor,
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      shadows: [
                                        Shadow(
                                          color: isDark
                                              ? Colors.cyanAccent.withOpacity(0.07)
                                              : Colors.blueAccent.withOpacity(0.05),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    obscureText: !controller.showPassword.value,
                                    onChanged: controller.setPassword,
                                  )),
                                  const SizedBox(height: 23),
                                  // Login button
                                  Obx(() => controller.isLoading.value
                                      ? CircularProgressIndicator(
                                    color: borderColor,
                                  )
                                      : ElevatedButton(
                                    onPressed: controller.login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isDark
                                              ? [
                                            Colors.cyanAccent,
                                            Colors.blueAccent,
                                          ]
                                              : [
                                            Colors.lightBlueAccent,
                                            Colors.blueAccent,
                                            Colors.blue[600]!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? Colors.cyanAccent.withOpacity(0.20)
                                                : Colors.lightBlueAccent.withOpacity(0.12),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 35,
                                        vertical: 10,
                                      ),
                                      child: Text(
                                        text.login,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
