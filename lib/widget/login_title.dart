import 'package:flutter/material.dart';

class LoginTitle extends StatelessWidget {
  final bool isDark;
  const LoginTitle({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      'MBD Factory Platform',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDark
            ? Colors.white
            : const Color(0xFF153962),
        letterSpacing: 1,
        shadows: [
          Shadow(
            color: isDark
                ? Colors.cyanAccent.withOpacity(0.6)
                : Colors.white.withOpacity(0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
