import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';
import 'package:smart_factory/screen/login/controller/login_controller.dart';

import '../../widget/login_logo.dart';
import '../../widget/login_title.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Xác thực sinh trắc học (FaceID/Fingerprint)
  Future<void> _faceIdLogin(BuildContext context, LoginController controller) async {
    final localAuth = LocalAuthentication();
    final S text = S.of(context);
    bool didAuth = false;
    try {
      didAuth = await localAuth.authenticate(
        localizedReason: text.quick_login_faceid,
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      Get.snackbar('Error', text.activate_faceid_note, backgroundColor: Colors.redAccent);
      return;
    }
    if (didAuth) {
      controller.quickLoginWithFaceId();
    }
  }

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();
    final SettingController settingController = Get.find<SettingController>();
    final S text = S.of(context);

    final bool isDark = settingController.isDarkMode.value;

    // Style
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
    final Color labelColor = isDark ? Colors.cyanAccent : const Color(0xFF174076);
    final Color inputFill = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.blue[50]!.withOpacity(0.24);
    final Color textColor = isDark ? Colors.white : const Color(0xFF13293D);
    final Color iconColor = isDark ? Colors.cyanAccent : Colors.blueAccent;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Nền
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
                    isDark ? Colors.black.withOpacity(0.33) : Colors.white.withOpacity(0.05),
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
                  constraints: const BoxConstraints(maxWidth: 430, maxHeight: 500),
                  child: FractionallySizedBox(
                    widthFactor: 0.97,
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
                          child: Padding(
                            padding: const EdgeInsets.all(22.0),
                            child: Obx(() {
                              final bool hasUsername = controller.username.value.isNotEmpty;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LoginLogo(isDark: isDark),
                                  const SizedBox(height: 4),
                                  LoginTitle(isDark: isDark),
                                  const SizedBox(height: 17),
                                  // Hiện field nhập username/mật khẩu nếu chưa có username lưu
                                  if (!hasUsername) ...[
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: text.username,
                                        labelStyle: TextStyle(
                                          color: labelColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        filled: true,
                                        fillColor: inputFill,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: borderColor),
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
                                      ),
                                      onChanged: controller.setUsername,
                                    ),
                                    const SizedBox(height: 15),
                                    Obx(() => TextField(
                                      decoration: InputDecoration(
                                        labelText: text.password,
                                        labelStyle: TextStyle(
                                          color: labelColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        filled: true,
                                        fillColor: inputFill,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: borderColor),
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
                                      ),
                                      obscureText: !controller.showPassword.value,
                                      onChanged: controller.setPassword,
                                    )),
                                    const SizedBox(height: 24),
                                  ],
                                  // Nếu đã có username, hiện text disable + nút đổi tài khoản
                                  if (hasUsername) ...[
                                    Row(
                                      children: [
                                        Icon(Icons.person, color: iconColor, size: 22),
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: Text(
                                            controller.username.value,
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.cyanAccent
                                                  : Colors.blueAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  // --- Nút Đăng nhập + icon FaceID ngang hàng ---
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Nút Đăng nhập
                                      Expanded(
                                        child: Obx(() => controller.isLoading.value
                                            ? Center(
                                          child: CircularProgressIndicator(
                                            color: borderColor,
                                          ),
                                        )
                                            : SizedBox(
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed: controller.login,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              minimumSize: const Size.fromHeight(50),
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(25),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: isDark
                                                      ? [
                                                    Colors.cyanAccent,
                                                    Colors.blueAccent
                                                  ]
                                                      : [
                                                    Colors.lightBlueAccent,
                                                    Colors.blueAccent,
                                                    Colors.blue[600]!
                                                  ],
                                                ),
                                                borderRadius:
                                                BorderRadius.circular(25),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                text.login,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )),
                                      ),
                                      const SizedBox(width: 12),
                                      // Icon FaceID
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.cyanAccent.withOpacity(0.45)
                                                : Colors.blue.withOpacity(0.5),
                                            width: 1.7,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          color: isDark
                                              ? Colors.white.withOpacity(0.08)
                                              : Colors.blue[50]!.withOpacity(0.19),
                                        ),
                                        child: IconButton(
                                          splashRadius: 23,
                                          onPressed: () {
                                            if (controller.isFaceIdEnabled.value) {
                                              _faceIdLogin(context, controller);
                                            } else {
                                              if (controller.username.value.isEmpty ||
                                                  controller.password.value.isEmpty) {
                                                Get.snackbar(
                                                  text.login,
                                                  text.need_login_first_to_activate_faceid,
                                                  backgroundColor: Colors.redAccent,
                                                  colorText: Colors.white,
                                                  snackPosition: SnackPosition.BOTTOM,
                                                );
                                              } else {
                                                Get.snackbar(
                                                  text.login,
                                                  text.activate_faceid_note,
                                                  backgroundColor: Colors.blueAccent,
                                                  colorText: Colors.white,
                                                  snackPosition: SnackPosition.BOTTOM,
                                                );
                                              }
                                            }
                                          },
                                          icon: Image.asset(
                                            'assets/icons/faceid.png',
                                            width: 29,
                                            height: 29,
                                            color: isDark
                                                ? Colors.cyanAccent
                                                : Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Dòng "Đăng nhập bằng tài khoản khác"
                                  if (hasUsername)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 24),
                                      child: GestureDetector(
                                        onTap: () => controller.clearUserForNewLogin(),
                                        child: Text(
                                          'Đăng nhập bằng tài khoản khác',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.cyanAccent
                                                : Colors.blueAccent,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }),
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
