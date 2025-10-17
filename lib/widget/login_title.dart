import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginTitle extends StatelessWidget {
  final bool isDark;
  final TextAlign textAlign;
  final double? fontSize;

  const LoginTitle({
    super.key,
    required this.isDark,
    this.textAlign = TextAlign.center,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'MBD Factory Platform',
      style: TextStyle(
        fontSize: (fontSize ?? 24).sp,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF153962),
        letterSpacing: 1.1.sp,
        shadows: [
          Shadow(
            color:
                isDark
                    ? Colors.cyanAccent.withOpacity(0.6)
                    : Colors.white.withOpacity(0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
