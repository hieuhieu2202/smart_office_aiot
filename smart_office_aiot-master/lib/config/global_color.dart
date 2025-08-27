import 'package:flutter/material.dart';

class GlobalColors {
  // --- Backgrounds ---
  static const Color bodyLightBg = Color(0xFFF7F9FC);
  static const Color bodyDarkBg = Color(0xFF0D1321);

  static const Color cardLightBg = Color(0xFFFFFFFF);
  static const Color cardDarkBg = Color(0xFF1E1E1E);

  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF19232F);

  static const Color bgLight = Color(0xFFF7F9FC);
  static const Color bgDark = Color(0xFF0D1321);

  static const Color darkBackground = Color(0xFF121212);
  static const Color lightBackground = Color(0xFFF5F5F5);

  // --- Border ---
  static const Color borderLight = Color(0xFF5BC2FF);
  static const Color borderDark = Color(0xFFA3BFFA);

  // Slot Border
  static const Color borderLightSlot = Color(0xFFB3E5FC); // blue50
  static const Color borderDarkSlot = Color(0xFF00FFF8); // cyanAccent

  // --- Texts ---
  static const Color lightPrimaryText = Color(0xFF153962); // navy
  static const Color darkPrimaryText = Color(0xFFFFFFFF);

  static const Color lightSecondaryText = Color(0xFF757575);
  static const Color darkSecondaryText = Color(0xFFB0B0B0);

  static const Color primaryTextLight = Color(0xFF153962);
  static const Color primaryTextDark = Color(0xFF7DE6F7); // cyan dịu
  static const Color secondaryTextLight = Color(0xFF757575);
  static const Color secondaryTextDark = Color(0xB3FFFFFF); // white70

  // --- Labels ---
  static const Color labelLight = Color(0xFF174076);
  static const Color labelDark = Color(0xFFA3BFFA);

  // --- Inputs ---
  static const Color inputLightFill = Color(0xFFEAF6FB);
  static const Color inputDarkFill = Color(0xFF222D3B);

  // --- Icon & accent ---
  static const Color iconLight = Color(0xFF1976D2); // blue700
  static const Color iconDark = Color(0xFF00FFF8); // cyanAccent
  static const Color accentLight = Color(0xFF1976D2); // blue700
  static const Color accentDark = Color(0xFF00FFF8); // cyanAccent

  // --- Button ---
  static const Color primaryButtonLight = Color(0xFF2196F3); // blue light
  static const Color primaryButtonDark = Color(0xFF42A5F5); // blue dark

  // --- Shadow ---
  static const Color shadowLight = Color(0x3329B6F6); // blue, opacity 20%
  static const Color shadowDark = Color(0x3300FFF8); // cyan, opacity 20%

  // --- Progress bar ---
  static const Color progressBgLight = Color(0xFFB3E5FC); // blue50 sáng
  static const Color progressBgDark = Color(0xFF30425A); // bluegrey tối

  // --- Slot/Item ---
  static const Color slotBgLight = Color(0xFFF3F6FB);
  static const Color slotBgDark = Color(0xFF232B39);

  // --- Tooltip ---
  static const Color tooltipBgLight = Colors.white;
  static const Color tooltipBgDark = Color(0xFF22304A);

  // --- AppBar ---
  static const Color appBarLightBg = Color(0xFFE6F0FA);
  static const Color appBarDarkBg = Color(0xFF1F2A44);
  static const Color appBarLightText = Color(0xFF1A3C6D);
  static const Color appBarDarkText = Color(0xFFA3BFFA);

  // --- Gradient ---
  static const Color gradientLightStart = Color(0xFF00C4FF);
  static const Color gradientLightEnd = Color(0xFF0288D1);
  static const Color gradientDarkStart = Color(0xFFA3BFFA);
  static const Color gradientDarkEnd = Color(0xFF42A5F5);

  // --- Special ---
  static const Color mbdColor = Color(0xFF1A2A53);
  static const Color aiotColor = Color(0xFFA61F28);
  static const Color contentColor = Color(0xFF1A7BA8);

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
    colors:
        isDark
            ? [cardDark, gradientDarkStart, gradientDarkEnd, bgDark]
            : [cardLight, gradientLightStart, gradientLightEnd, bgLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient buttonGradient({bool isDark = false}) => LinearGradient(
    colors:
        isDark
            ? [gradientDarkStart, gradientDarkEnd]
            : [gradientLightStart, gradientLightEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient textGradient({bool isDark = false}) => LinearGradient(
    colors:
        isDark
            ? [gradientDarkStart, gradientDarkEnd]
            : [gradientLightStart, gradientLightEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color accentByIsDark(bool isDark) =>
      isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight;
}
