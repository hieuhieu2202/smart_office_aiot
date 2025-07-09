import 'package:flutter/material.dart';

class GlobalColors {
  // Backgrounds
  static const Color bodyLightBg = Color(0xFFF7F9FC);
  static const Color bodyDarkBg = Color(0xFF0D1321);

  static const Color cardLightBg = Color(0xFFFFFFFF);
  static const Color cardDarkBg = Color(0xFF1E1E1E);

  // Borders
  static const Color borderLight = Color(0xFF5BC2FF);
  static const Color borderDark = Color(0xFFA3BFFA);

  // Texts
  static const Color lightPrimaryText = Color(0xFF153962); // navy
  static const Color darkPrimaryText = Color(0xFFFFFFFF);

  static const Color lightSecondaryText = Color(0xFF757575);
  static const Color darkSecondaryText = Color(0xFFB0B0B0);

  // Labels
  static const Color labelLight = Color(0xFF174076);
  static const Color labelDark = Color(0xFFA3BFFA);

  // Inputs
  static const Color inputLightFill = Color(0xFFEAF6FB);
  static const Color inputDarkFill = Color(0xFF222D3B);

  // Icon
  static const Color iconLight = Color(0xFF1976D2);
  static const Color iconDark = Color(0xFFA3BFFA);

  // Accent Colors (Nên nhóm ở gần nhau)
  static const Color primaryButtonLight = Color(0xFF2196F3); // Xanh dương sáng (light)
  static const Color primaryButtonDark = Color(0xFF42A5F5);  // Xanh dương đậm (dark)

  static const Color darkBackground = Color(0xFF121212); // hoặc 0xFF0D1321 cũng được
  static const Color lightBackground = Color(0xFFF5F5F5); // sáng nhã, dễ nhìn
  // Gradients
  static const mbdColor = Color(0xFF1A2A53);
  static const aiotColor = Color(0xFFA61F28);
  static const contentColor = Color(0xFF1A7BA8);

  static LinearGradient backgroundGradient({
    Color color1 = const Color(0xFF1E90FF),
    Color color2 = const Color(0xFF00BFFF),
    Color color3 = const Color(0xFF87CEFA),
    Color color4 = const Color(0xFFFFFFFF),
  }) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color1, color2, color3, color4],
      stops: [0.0, 0.4, 0.7, 1.0],
    );
  }

  static LinearGradient cardGradient({bool isDark = false}) => LinearGradient(
    colors: isDark
        ? [cardDarkBg, gradientDarkStart, gradientDarkEnd, bodyDarkBg]
        : [cardLightBg, gradientLightStart, gradientLightEnd, bodyLightBg],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient buttonGradient({bool isDark = false}) => LinearGradient(
    colors: isDark
        ? [gradientDarkStart, gradientDarkEnd]
        : [gradientLightStart, gradientLightEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient textGradient({bool isDark = false}) => LinearGradient(
    colors: isDark
        ? [gradientDarkStart, gradientDarkEnd]
        : [gradientLightStart, gradientLightEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );


  static const Color gradientLightStart = Color(0xFF00C4FF);
  static const Color gradientLightEnd = Color(0xFF0288D1);
  static const Color gradientDarkStart = Color(0xFFA3BFFA);
  static const Color gradientDarkEnd = Color(0xFF42A5F5);

  // AppBar (nếu muốn)
  static const Color appBarLightBg = Color(0xFFE6F0FA);
  static const Color appBarDarkBg = Color(0xFF1F2A44);
  static const Color appBarLightText = Color(0xFF1A3C6D);
  static const Color appBarDarkText = Color(0xFFA3BFFA);
}
