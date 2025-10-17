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

    final ResponsiveBreakpointsData breakpoints =
        ResponsiveBreakpoints.of(context);
    final bool isTablet = breakpoints.largerOrEqualTo(TABLET);
    final bool isDesktop = breakpoints.largerOrEqualTo(DESKTOP);

    return Scaffold(
      body: Stack(
        children: [
          _LoginBackground(isDark: isDark),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double bottomInset =
                    MediaQuery.of(context).viewInsets.bottom;

                final double horizontalPadding =
                    isDesktop ? 72 : isTablet ? 48 : 20;
                final double verticalPadding = isDesktop ? 56 : isTablet ? 40 : 24;

                final EdgeInsets scrollPadding = EdgeInsets.fromLTRB(
                  horizontalPadding.w,
                  verticalPadding.h,
                  horizontalPadding.w,
                  verticalPadding.h + bottomInset,
                );

                final double maxContentWidth =
                    isDesktop ? 1200 : isTablet ? 760 : double.infinity;

                final Widget formCard = _LoginFormCard(
                  controller: controller,
                  text: text,
                  isDark: isDark,
                  size: isDesktop
                      ? _LoginFormSize.large
                      : isTablet
                          ? _LoginFormSize.medium
                          : _LoginFormSize.small,
                  onRequestFaceId: () => _faceIdLogin(context, controller, text),
                );

                final Widget welcomePanel = _WelcomePanel(
                  isDark: isDark,
                  compact: !isDesktop,
                  tabletLayout: isTablet && !isDesktop,
                );

                return SingleChildScrollView(
                  padding: scrollPadding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: welcomePanel),
                                SizedBox(width: 48.w),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 440),
                                  child: formCard,
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                welcomePanel,
                                SizedBox(height: isTablet ? 36.h : 24.h),
                                formCard,
                              ],
                            ),
                    ),
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

class _LoginBackground extends StatelessWidget {
  final bool isDark;

  const _LoginBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF090E1C), Color(0xFF13203A)]
              : const [Color(0xFFF3F7FF), Color(0xFFE6F1FF)],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: IgnorePointer(
          child: Padding(
            padding: EdgeInsets.only(right: 24.w, bottom: 24.h),
            child: Opacity(
              opacity: isDark ? 0.18 : 0.12,
              child: Container(
                width: 220.w,
                height: 220.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [const Color(0xFF36D1DC).withOpacity(0.7), Colors.transparent]
                        : [const Color(0xFF1E88E5).withOpacity(0.45), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _LoginFormSize { small, medium, large }

class _LoginFormCard extends StatelessWidget {
  final LoginController controller;
  final S text;
  final bool isDark;
  final _LoginFormSize size;
  final Future<void> Function() onRequestFaceId;

  const _LoginFormCard({
    required this.controller,
    required this.text,
    required this.isDark,
    required this.size,
    required this.onRequestFaceId,
  });

  double _select(double small, double medium, double large) {
    switch (size) {
      case _LoginFormSize.large:
        return large;
      case _LoginFormSize.medium:
        return medium;
      case _LoginFormSize.small:
      default:
        return small;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = _select(22, 30, 36).w;
    final double verticalPadding = _select(24, 30, 36).h;
    final double headerSpacing = _select(18, 22, 26).h;
    final double fieldSpacing = _select(16, 18, 20).h;
    final double buttonHeight = _select(50, 54, 56).h;

    final Color cardColor = isDark
        ? const Color(0xFF101B2E).withOpacity(0.92)
        : Colors.white;
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.14)
        : Colors.blueGrey.withOpacity(0.12);
    final Color accentColor = isDark ? const Color(0xFF67E8F9) : const Color(0xFF1E88E5);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(_select(22, 26, 30).r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : Colors.blueGrey.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Obx(() {
          final bool loginFrozen = controller.isLoginFrozen.value;
          final bool showPassword = controller.showPassword.value;
          final bool isLoading = controller.isLoading.value;
          final bool faceIdEnabled = controller.isFaceIdEnabled.value;

          final TextStyle captionStyle = TextStyle(
            color: isDark ? Colors.white70 : Colors.blueGrey[600],
            fontSize: _select(12.5, 13, 13.5).sp,
          );

          final InputBorder inputBorder = OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: borderColor.withOpacity(isDark ? 0.6 : 0.8)),
          );

          Widget buildFaceButton() {
            return Tooltip(
              message: faceIdEnabled
                  ? text.quick_login_faceid
                  : text.need_login_first_to_activate_faceid,
              child: OutlinedButton(
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: _select(12, 14, 16).w,
                    vertical: _select(10, 10, 12).h,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.face_6, size: _select(18, 20, 20).sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Face ID',
                      style: TextStyle(
                        fontSize: _select(13, 13.5, 14).sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                size == _LoginFormSize.large ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: size == _LoginFormSize.large
                    ? Alignment.centerLeft
                    : Alignment.center,
                child: LoginLogo(
                  isDark: isDark,
                  size: size == _LoginFormSize.large ? 92 : 80,
                ),
              ),
              SizedBox(height: headerSpacing * 0.6),
              Align(
                alignment: size == _LoginFormSize.large
                    ? Alignment.centerLeft
                    : Alignment.center,
                child: LoginTitle(
                  isDark: isDark,
                  textAlign:
                      size == _LoginFormSize.large ? TextAlign.left : TextAlign.center,
                  fontSize: size == _LoginFormSize.large ? 30 : 26,
                ),
              ),
              SizedBox(height: 12.h),
              Align(
                alignment: size == _LoginFormSize.large
                    ? Alignment.centerLeft
                    : Alignment.center,
                child: Text(
                  'Nền tảng điều hành nhà máy thông minh',
                  style: captionStyle.copyWith(
                    fontSize: _select(13, 13.5, 14).sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: size == _LoginFormSize.large ? TextAlign.left : TextAlign.center,
                ),
              ),
              SizedBox(height: headerSpacing),
              if (!loginFrozen)
                TextField(
                  decoration: InputDecoration(
                    labelText: text.username,
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.blueGrey.withOpacity(0.05),
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: accentColor, width: 1.6),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: controller.setUsername,
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.blueGrey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: accentColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: accentColor, size: 20.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          controller.username.value,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 15.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: fieldSpacing),
              TextField(
                decoration: InputDecoration(
                  labelText: text.password,
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.blueGrey.withOpacity(0.05),
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: accentColor, width: 1.6),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: accentColor,
                    ),
                    onPressed: () {
                      controller.showPassword.value = !showPassword;
                    },
                  ),
                ),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                obscureText: !showPassword,
                onChanged: controller.setPassword,
                onSubmitted: (_) => controller.login(),
              ),
              SizedBox(height: fieldSpacing),
              Text(
                text.quick_login_faceid,
                style: captionStyle,
              ),
              SizedBox(height: headerSpacing * 0.7),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: controller.login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          textStyle: TextStyle(
                            fontSize: _select(16, 16.5, 17).sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 22.w,
                                height: 22.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(text.login),
                      ),
                    ),
                  ),
                  SizedBox(width: _select(12, 14, 16).w),
                  buildFaceButton(),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  final bool isDark;
  final bool compact;
  final bool tabletLayout;

  const _WelcomePanel({
    required this.isDark,
    required this.compact,
    required this.tabletLayout,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(compact ? 26.r : 32.r);

    final List<_WelcomeHighlight> highlights = const [
      _WelcomeHighlight(
        icon: Icons.speed,
        title: 'Giám sát thời gian thực',
        description: 'Cập nhật tình trạng dây chuyền tức thì.',
      ),
      _WelcomeHighlight(
        icon: Icons.auto_graph,
        title: 'Phân tích trực quan',
        description: 'Dashboard đa lớp cho mọi vai trò.',
      ),
      _WelcomeHighlight(
        icon: Icons.security,
        title: 'Bảo mật chuẩn doanh nghiệp',
        description: 'Xác thực sinh trắc và phân quyền linh hoạt.',
      ),
    ];

    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: compact ? 24.w : 36.w,
      vertical: compact ? 28.h : 40.h,
    );

    final TextStyle bodyStyle = TextStyle(
      color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1A365D),
      fontSize: compact ? 14.sp : 15.5.sp,
      height: 1.45,
      fontWeight: FontWeight.w500,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF10203B), Color(0xFF081222)]
              : const [Color(0xFFEAF4FF), Color(0xFFFFFFFF)],
        ),
        borderRadius: radius,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.blueGrey.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.28)
                : Colors.blueGrey.withOpacity(0.14),
            blurRadius: 30,
            offset: const Offset(0, 22),
          )
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Align(
              alignment:
                  compact ? Alignment.center : Alignment.centerLeft,
              child: LoginLogo(
                isDark: isDark,
                size: compact ? 76 : 88,
              ),
            ),
            SizedBox(height: 18.h),
            Align(
              alignment:
                  compact ? Alignment.center : Alignment.centerLeft,
              child: LoginTitle(
                isDark: isDark,
                textAlign: compact ? TextAlign.center : TextAlign.left,
                fontSize: compact ? 26 : 30,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Quản lý nhà máy trên mọi thiết bị. Giao diện thích ứng giúp đội ngũ vận hành làm việc liền mạch từ điện thoại đến màn hình lớn.',
              style: bodyStyle,
              textAlign: compact ? TextAlign.center : TextAlign.left,
            ),
            SizedBox(height: compact ? 24.h : 32.h),
            Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              alignment: compact ? WrapAlignment.center : WrapAlignment.start,
              children: highlights
                  .map(
                    (item) => _HighlightCard(
                      data: item,
                      compact: compact && !tabletLayout,
                      isDark: isDark,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHighlight {
  final IconData icon;
  final String title;
  final String description;

  const _WelcomeHighlight({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _HighlightCard extends StatelessWidget {
  final _WelcomeHighlight data;
  final bool compact;
  final bool isDark;

  const _HighlightCard({
    required this.data,
    required this.compact,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 160.w : 180.w,
        maxWidth: compact ? 220.w : 240.w,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16.w : 20.w,
        vertical: compact ? 16.h : 20.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.blueGrey.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.cyanAccent.withOpacity(0.18)
                  : const Color(0xFF1E88E5).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              data.icon,
              color: isDark ? Colors.cyanAccent : const Color(0xFF1E88E5),
              size: 20.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            data.title,
            style: TextStyle(
              fontSize: compact ? 14.sp : 15.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF153B65),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            data.description,
            style: TextStyle(
              fontSize: compact ? 12.5.sp : 13.sp,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.blueGrey[600],
            ),
          ),
        ],
      ),
    );
  }
}
