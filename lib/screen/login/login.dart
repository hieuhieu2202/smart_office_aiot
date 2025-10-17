import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/screen/login/controller/login_controller.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';

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
    final ResponsiveBreakpointsData breakpoints =
        ResponsiveBreakpoints.of(context);
    final bool isTablet = breakpoints.largerOrEqualTo(TABLET);
    final bool isDesktop = breakpoints.largerOrEqualTo(DESKTOP);

    final double maxCardWidth = isDesktop
        ? 580
        : isTablet
            ? 500
            : 430;
    final double maxCardHeight = isDesktop
        ? 560
        : isTablet
            ? 520
            : 470;
    final double horizontalInset = isDesktop
        ? 180
        : isTablet
            ? 80
            : 20;
    final double verticalInset = isDesktop
        ? 80
        : isTablet
            ? 60
            : 40;

    // Style
    final List<Color> cardGradient = isDark
        ? [
      Colors.black.withOpacity(0.7),
      Colors.blueGrey.shade900.withOpacity(0.74),
      Colors.blueGrey.shade800.withOpacity(0.66),
    ]
        : [
      Colors.blue.withOpacity(0.98),
      Colors.grey[50]!.withOpacity(0.95),
      Colors.blue[50]!.withOpacity(0.92),
    ];
    final Color borderColor = isDark
        ? Colors.cyanAccent.withOpacity(0.37)
        : Colors.blue[700]!;
    final Color labelColor = isDark ? Colors.cyanAccent : Colors.grey[800]!;
    final Color inputFill = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.9);
    final Color textColor = isDark ? Colors.white : Colors.grey[900]!;
    final Color iconColor = isDark ? Colors.cyanAccent : Colors.blue[700]!;
    final Color buttonGradientStart = isDark ? Colors.cyanAccent : Colors.blue[600]!;
    final Color buttonGradientEnd = isDark ? Colors.blueAccent : Colors.blue[900]!;

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
                    isDark ? Colors.black.withOpacity(0.33) : Colors.white.withOpacity(0.1),
                    BlendMode.srcOver,
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
                padding: EdgeInsets.fromLTRB(
                  horizontalInset,
                  verticalInset,
                  horizontalInset,
                  verticalInset + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxCardWidth,
                    maxHeight: maxCardHeight,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: isDesktop
                        ? 0.65
                        : isTablet
                            ? 0.75
                            : 0.97,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
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
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(
                              color: borderColor,
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.cyanAccent.withOpacity(0.18)
                                    : Colors.grey[300]!.withOpacity(0.2),
                                blurRadius: 22,
                                spreadRadius: 1,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              isDesktop
                                  ? 32.w
                                  : isTablet
                                      ? 28.w
                                      : 22.w,
                            ),
                            child: Obx(() {
                              final bool loginFrozen = controller.isLoginFrozen.value;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LoginLogo(isDark: isDark),
                                  SizedBox(height: 6.h),
                                  LoginTitle(isDark: isDark),
                                  SizedBox(
                                    height: isDesktop
                                        ? 28.h
                                        : isTablet
                                            ? 22.h
                                            : 17.h,
                                  ),
                                  // Username field or stored username label
                                  if (!loginFrozen) ...[
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: text.username,
                                        labelStyle: TextStyle(
                                          color: labelColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16.sp,
                                        ),
                                        filled: true,
                                        fillColor: inputFill,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                          borderSide: BorderSide(color: borderColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16.sp,
                                      ),
                                      onChanged: controller.setUsername,
                                    ),
                                    SizedBox(
                                      height: isDesktop
                                          ? 24.h
                                          : isTablet
                                              ? 20.h
                                              : 15.h,
                                    ),
                                  ] else ...[
                                    Row(
                                      children: [
                                        Icon(Icons.person,
                                            color: iconColor, size: 22.sp),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(
                                            controller.username.value,
                                            style: TextStyle(
                                              color: iconColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18.sp,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: isDesktop
                                          ? 26.h
                                          : isTablet
                                              ? 22.h
                                              : 18.h,
                                    ),
                                  ],
                                  Obx(() => TextField(
                                    decoration: InputDecoration(
                                      labelText: text.password,
                                      labelStyle: TextStyle(
                                        color: labelColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16.sp,
                                      ),
                                      filled: true,
                                      fillColor: inputFill,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12.r),
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
                                          size: 22.sp,
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                    ),
                                    obscureText: !controller.showPassword.value,
                                    onChanged: controller.setPassword,
                                  )),
                                  SizedBox(
                                    height: isDesktop
                                        ? 34.h
                                        : isTablet
                                            ? 28.h
                                            : 24.h,
                                  ),
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
                                              ))
                                            : SizedBox(
                                                height: isDesktop
                                                    ? 58.h
                                                    : isTablet
                                                        ? 54.h
                                                        : 50.h,
                                                child: ElevatedButton(
                                                  onPressed: controller.login,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    shadowColor: Colors.transparent,
                                                    minimumSize: Size.fromHeight(
                                                      isDesktop
                                                          ? 58.h
                                                          : isTablet
                                                              ? 54.h
                                                              : 50.h,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(25.r),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          buttonGradientStart,
                                                          buttonGradientEnd,
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(25.r),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      text.login,
                                                      style: TextStyle(
                                                        fontSize: isDesktop
                                                            ? 20.sp
                                                            : 18.sp,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: 1.1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )),
                                      ),
                                      SizedBox(
                                        width: isDesktop
                                            ? 20.w
                                            : isTablet
                                                ? 16.w
                                                : 12.w,
                                      ),
                                      // Icon FaceID
                                      Container(
                                        width: isDesktop
                                            ? 58.w
                                            : isTablet
                                                ? 52.w
                                                : 48.w,
                                        height: isDesktop
                                            ? 58.h
                                            : isTablet
                                                ? 52.h
                                                : 48.h,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.cyanAccent.withOpacity(0.45)
                                                : Colors.blue[300]!.withOpacity(0.6),
                                            width: 1.7,
                                          ),
                                          borderRadius: BorderRadius.circular(12.r),
                                          color: isDark
                                              ? Colors.white.withOpacity(0.08)
                                              : Colors.white.withOpacity(0.85),
                                        ),
                                        child: IconButton(
                                          splashRadius: 23.r,
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
                                            width: 29.w,
                                            height: 29.h,
                                            color: iconColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Dòng "Đăng nhập bằng tài khoản khác"
                                  if (loginFrozen)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: isDesktop
                                            ? 32.h
                                            : isTablet
                                                ? 28.h
                                                : 24.h,
                                      ),
                                      child: GestureDetector(
                                        onTap: () => controller.clearUserForNewLogin(),
                                        child: Text(
                                          'Đăng nhập bằng tài khoản khác',
                                          style: TextStyle(
                                            color: iconColor,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
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