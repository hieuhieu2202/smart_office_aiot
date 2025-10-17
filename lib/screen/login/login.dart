import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/screen/login/controller/login_controller.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';

import '../../widget/login_logo.dart';
import '../../widget/login_title.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _faceIdLogin(
    BuildContext context,
    LoginController controller,
    S text,
  ) async {
    final localAuth = LocalAuthentication();
    bool didAuth = false;
    try {
      didAuth = await localAuth.authenticate(
        localizedReason: text.quick_login_faceid,
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        text.activate_faceid_note,
        backgroundColor: Colors.redAccent,
      );
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

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
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
                        ? Colors.black.withOpacity(0.32)
                        : Colors.white.withOpacity(0.12),
                    BlendMode.srcOver,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xAA0F172A),
                          const Color(0x660F172A),
                        ]
                      : [
                          const Color(0x66F8FAFC),
                          const Color(0x88EEF5FF),
                        ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth;
                final bool showTabletLayout = maxWidth >= 720;
                final bool showDesktopLayout = maxWidth >= 1120;
                final bool isTabletFieldLayout = maxWidth >= 600;

                final double horizontalPadding = showDesktopLayout
                    ? 56
                    : showTabletLayout
                        ? 36
                        : 20;
                final double verticalPadding = showDesktopLayout ? 40 : 24;

                final Widget loginCard = _LoginFormCard(
                  controller: controller,
                  text: text,
                  isDark: isDark,
                  isTablet: isTabletFieldLayout,
                  isDesktop: showDesktopLayout,
                  onRequestFaceId: () => _faceIdLogin(context, controller, text),
                );

                final Widget heroPanel = _LoginHeroPanel(
                  isDark: isDark,
                  expanded: showDesktopLayout,
                );

                if (showDesktopLayout) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding.w,
                      vertical: verticalPadding.h,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Row(
                          children: [
                            Expanded(child: heroPanel),
                            SizedBox(width: 42.w),
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: loginCard,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
                final double sidePadding = horizontalPadding.w;
                final double topPadding = verticalPadding.h;
                final double bottomPadding = topPadding + bottomInset;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    topPadding,
                    sidePadding,
                    bottomPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (showTabletLayout) ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 780),
                          child: heroPanel,
                        ),
                        SizedBox(height: 28.h),
                      ],
                      Align(
                        alignment: Alignment.center,
                        child: loginCard,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  final LoginController controller;
  final S text;
  final bool isDark;
  final bool isTablet;
  final bool isDesktop;
  final Future<void> Function() onRequestFaceId;

  const _LoginFormCard({
    required this.controller,
    required this.text,
    required this.isDark,
    required this.isTablet,
    required this.isDesktop,
    required this.onRequestFaceId,
  });

  @override
  Widget build(BuildContext context) {
    final double cardHorizontalPadding = (isDesktop ? 36.0 : isTablet ? 32.0 : 22.0).w;
    final double cardVerticalPadding = (isDesktop ? 36.0 : isTablet ? 32.0 : 26.0).h;
    final double headerSpacing = (isDesktop ? 28.0 : isTablet ? 24.0 : 20.0).h;
    final double fieldSpacing = (isDesktop ? 22.0 : isTablet ? 18.0 : 16.0).h;
    final double actionSpacing = (isDesktop ? 20.0 : isTablet ? 16.0 : 12.0).w;
    final double buttonHeight = (isDesktop ? 56.0 : isTablet ? 54.0 : 50.0).h;
    final double faceButtonSize = (isDesktop ? 56.0 : isTablet ? 52.0 : 48.0).w;

    final List<Color> cardGradient = isDark
        ? [
            const Color(0xDD0F172A),
            const Color(0xAA1E293B),
          ]
        : [
            Colors.white.withOpacity(0.96),
            const Color(0xE6F1F5FF),
          ];
    final Color borderColor = isDark
        ? Colors.cyanAccent.withOpacity(0.35)
        : Colors.blue[400]!.withOpacity(0.55);
    final Color labelColor = isDark ? Colors.cyanAccent : Colors.blueGrey[700]!;
    final Color inputFill = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.9);
    final Color textColor = isDark ? Colors.white : Colors.grey[900]!;
    final Color iconColor = isDark ? Colors.cyanAccent : Colors.blue[700]!;
    final Color buttonGradientStart =
        isDark ? Colors.cyanAccent : const Color(0xFF1E88E5);
    final Color buttonGradientEnd =
        isDark ? Colors.blueAccent : const Color(0xFF0D47A1);

    final BorderRadius cardRadius = BorderRadius.circular(isDesktop ? 28.r : 24.r);

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 460 : 440,
        ),
        child: _GlassPanel(
          borderRadius: cardRadius,
          gradient: cardGradient,
          borderColor: borderColor,
          blurSigma: 20,
          shadows: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.35)
                  : Colors.blueGrey.withOpacity(0.16),
              blurRadius: 30,
              offset: const Offset(0, 26),
            ),
          ],
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: cardHorizontalPadding,
              vertical: cardVerticalPadding,
            ),
            child: Obx(() {
              final bool loginFrozen = controller.isLoginFrozen.value;
              final bool showPassword = controller.showPassword.value;
              final bool isLoading = controller.isLoading.value;
              final bool faceIdEnabled = controller.isFaceIdEnabled.value;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment:
                        isDesktop ? Alignment.centerLeft : Alignment.center,
                    child: LoginLogo(
                      isDark: isDark,
                      size: isDesktop ? 88 : 80,
                    ),
                  ),
                  SizedBox(height: headerSpacing * 0.55),
                  Align(
                    alignment:
                        isDesktop ? Alignment.centerLeft : Alignment.center,
                    child: LoginTitle(
                      isDark: isDark,
                      textAlign:
                          isDesktop ? TextAlign.left : TextAlign.center,
                      fontSize: isDesktop ? 28 : 24,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Align(
                    alignment:
                        isDesktop ? Alignment.centerLeft : Alignment.center,
                    child: Text(
                      'Tăng tốc giám sát dây chuyền với báo cáo theo thời gian thực.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.85)
                            : Colors.blueGrey[600],
                        fontSize: isDesktop ? 16.sp : 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    ),
                  ),
                  SizedBox(height: headerSpacing),
                  if (!loginFrozen) ...[
                    TextField(
                      decoration: InputDecoration(
                        labelText: text.username,
                        labelStyle: TextStyle(
                          color: labelColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                        filled: true,
                        fillColor: inputFill,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(color: borderColor.withOpacity(0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.6,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: controller.setUsername,
                    ),
                    SizedBox(height: fieldSpacing),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: inputFill,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: borderColor.withOpacity(0.6)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: iconColor, size: 22.sp),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              controller.username.value,
                              style: TextStyle(
                                color: iconColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 17.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: fieldSpacing),
                  ],
                  TextField(
                    decoration: InputDecoration(
                      labelText: text.password,
                      labelStyle: TextStyle(
                        color: labelColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                      ),
                      filled: true,
                      fillColor: inputFill,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(color: borderColor.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                          color: borderColor,
                          width: 1.6,
                        ),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          controller.showPassword.value = !showPassword;
                        },
                        child: Icon(
                          showPassword ? Icons.visibility : Icons.visibility_off,
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
                    obscureText: !showPassword,
                    onChanged: controller.setPassword,
                    onSubmitted: (_) => controller.login(),
                  ),
                  SizedBox(height: headerSpacing),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: isLoading
                            ? Center(
                                child: SizedBox(
                                  width: 26.w,
                                  height: 26.w,
                                  child: CircularProgressIndicator(
                                    color: borderColor,
                                    strokeWidth: 2.8,
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: buttonHeight,
                                child: ElevatedButton(
                                  onPressed: controller.login,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26.r),
                                    ),
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          buttonGradientStart,
                                          buttonGradientEnd,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(26.r),
                                    ),
                                    child: Center(
                                      child: Text(
                                        text.login,
                                        style: TextStyle(
                                          fontSize: isDesktop ? 18.sp : 17.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      SizedBox(width: actionSpacing),
                      Container(
                        width: faceButtonSize,
                        height: faceButtonSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.cyanAccent.withOpacity(0.42)
                                : Colors.blue[200]!.withOpacity(0.7),
                            width: 1.4,
                          ),
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.88),
                        ),
                        child: IconButton(
                          splashRadius: 24.r,
                          onPressed: () async {
                            if (faceIdEnabled) {
                              await onRequestFaceId();
                            } else if (controller.username.value.isEmpty ||
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
                          },
                          icon: Image.asset(
                            'assets/icons/faceid.png',
                            width: 28.w,
                            height: 28.h,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (loginFrozen)
                    Padding(
                      padding: EdgeInsets.only(top: headerSpacing),
                      child: GestureDetector(
                        onTap: () => controller.clearUserForNewLogin(),
                        child: Text(
                          'Đăng nhập bằng tài khoản khác',
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 15.sp,
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
    );
  }
}

class _LoginHeroPanel extends StatelessWidget {
  final bool isDark;
  final bool expanded;

  const _LoginHeroPanel({
    required this.isDark,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(expanded ? 34.r : 26.r);
    final double horizontal = (expanded ? 42.0 : 26.0).w;
    final double vertical = (expanded ? 40.0 : 26.0).h;
    final TextStyle subtitleStyle = TextStyle(
      color: Colors.white.withOpacity(0.82),
      fontSize: expanded ? 15.sp : 13.sp,
      fontWeight: FontWeight.w500,
      height: 1.45,
    );

    final List<_HeroBulletData> bulletData = [
      _HeroBulletData(
        icon: Icons.analytics_outlined,
        title: 'Giám sát dây chuyền sản xuất',
        subtitle: 'Theo dõi công suất, cảnh báo ngừng máy và tình trạng vận hành ngay lập tức.',
      ),
      _HeroBulletData(
        icon: Icons.dashboard_customize,
        title: 'Bảng điều khiển đa màn hình',
        subtitle: 'Tối ưu cho tablet & desktop với bố cục linh hoạt và điều hướng nhanh.',
      ),
      _HeroBulletData(
        icon: Icons.verified_user_outlined,
        title: 'Bảo mật xác thực sinh trắc học',
        subtitle: 'Đăng nhập nhanh bằng FaceID/TouchID dành cho người vận hành.',
      ),
    ];

    final List<Color> gradient = isDark
        ? [
            const Color(0xF01B1E35),
            const Color(0xD01F2937),
          ]
        : [
            const Color(0xE61F4AC8),
            const Color(0xE6006CFF),
          ];

    final Color borderColor = isDark
        ? Colors.cyanAccent.withOpacity(0.35)
        : Colors.white.withOpacity(0.55);

    return _GlassPanel(
      borderRadius: radius,
      gradient: gradient,
      borderColor: borderColor,
      blurSigma: 22,
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.28),
          blurRadius: 38,
          offset: const Offset(0, 28),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            LoginLogo(isDark: true, size: expanded ? 92 : 80),
            SizedBox(height: expanded ? 26.h : 20.h),
            LoginTitle(
              isDark: true,
              textAlign: TextAlign.left,
              fontSize: expanded ? 32 : 26,
            ),
            SizedBox(height: 12.h),
            Text(
              'Chào mừng đến với MBD-Factory – nền tảng tự động hóa giúp bạn nắm bắt mọi chuyển động của nhà máy.',
              style: subtitleStyle,
            ),
            SizedBox(height: expanded ? 28.h : 22.h),
            ...bulletData.map(
              (data) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _HeroBullet(
                  data: data,
                  expanded: expanded,
                ),
              ),
            ),
            SizedBox(height: expanded ? 20.h : 12.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 18.w,
                vertical: 16.h,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security_rounded, color: Colors.white70),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Dữ liệu được mã hóa và đồng bộ trên mọi thiết bị.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: expanded ? 14.sp : 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBulletData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeroBulletData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _HeroBullet extends StatelessWidget {
  final _HeroBulletData data;
  final bool expanded;

  const _HeroBullet({
    required this.data,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18.w,
        vertical: expanded ? 16.h : 14.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: expanded ? 34.w : 30.w,
            height: expanded ? 34.w : 30.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              data.icon,
              color: Colors.white,
              size: expanded ? 20.sp : 18.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: expanded ? 16.sp : 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: expanded ? 13.5.sp : 12.5.sp,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final BorderRadius borderRadius;
  final List<Color> gradient;
  final Color borderColor;
  final Widget child;
  final double blurSigma;
  final List<BoxShadow>? shadows;

  const _GlassPanel({
    required this.borderRadius,
    required this.gradient,
    required this.borderColor,
    required this.child,
    this.blurSigma = 18,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 20),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}
