import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'global_color.dart';

class GlobalTextStyles {
  static TextStyle bodyLarge({bool isDark = false}) => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: isDark
            ? GlobalColors.darkPrimaryText
            : GlobalColors.lightPrimaryText,
      );

  static TextStyle bodyMedium({bool isDark = false}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark
            ? GlobalColors.darkPrimaryText
            : GlobalColors.lightPrimaryText,
      );

  static TextStyle bodySmall({bool isDark = false}) =>
      GoogleFonts.ibmPlexSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark
            ? GlobalColors.darkSecondaryText
            : GlobalColors.lightSecondaryText,
      );

  static TextStyle contentStyle({bool isDark = false}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w700,
        color: isDark
            ? GlobalColors.darkPrimaryText
            : GlobalColors.lightPrimaryText,
      );

}
