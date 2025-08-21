import 'package:flutter/material.dart';

class LoginLogo extends StatelessWidget {
  final bool isDark;

  const LoginLogo({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (!isDark) {
      return Image.asset('assets/images/logo.png', width: 80, height: 80);
    }
    // Dark: có halo
    return Container(
      width: 88,
      height: 88,
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
      child: Image.asset('assets/images/logo.png', width: 72, height: 72),
    );
  }
}
