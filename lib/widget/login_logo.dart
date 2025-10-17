import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginLogo extends StatelessWidget {
  final bool isDark;
  final double size;

  const LoginLogo({
    super.key,
    required this.isDark,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final double haloSize = (size * 1.12).w;
    final double logoSize = size.w;

    if (!isDark) {
      return Image.asset('assets/images/logo.png', width: logoSize, height: logoSize);
    }
    // Dark: có halo
    return Container(
      width: haloSize,
      height: haloSize,
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
      child: Image.asset(
        'assets/images/logo.png',
        width: logoSize,
        height: logoSize,
      ),
    );
  }
}
