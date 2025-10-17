import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginLogo extends StatelessWidget {
  final bool isDark;

  const LoginLogo({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (!isDark) {
      return Image.asset('assets/images/logo.png', width: 80.w, height: 80.w);
    }
    // Dark: có halo
    return Container(
      width: 88.w,
      height: 88.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.14),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.33),
            blurRadius: 36,
            spreadRadius: 3,
          ),
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 7),
        ],
      ),
      child: Image.asset('assets/images/logo.png', width: 72.w, height: 72.w),
    );
  }
}
