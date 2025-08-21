import 'package:flutter/material.dart';
import 'global_color.dart';

class GlobalTextStyles {
  static TextStyle bodyLarge({bool isDark = false}) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: isDark
        ? GlobalColors.darkPrimaryText
        : GlobalColors.lightPrimaryText,
  );

  static TextStyle bodyMedium({bool isDark = false}) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: isDark
        ? GlobalColors.darkPrimaryText
        : GlobalColors.lightPrimaryText,
  );

  static TextStyle bodySmall({bool isDark = false}) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: isDark
        ? GlobalColors.darkSecondaryText
        : GlobalColors.lightSecondaryText,
  );

  static TextStyle contentStyle({bool isDark = false}) => TextStyle(
    fontSize: 24,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.bold,
    color: isDark
        ? GlobalColors.darkPrimaryText
        : GlobalColors.lightPrimaryText,
  );

}
