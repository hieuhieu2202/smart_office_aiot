import 'package:flutter/material.dart';
import 'package:smart_factory/config/global_color.dart';

class CleanRoomChartStyle {
  static List<Color> palette(bool isDark) => [
        GlobalColors.accentByIsDark(isDark),
        isDark ? GlobalColors.iconDark : GlobalColors.iconLight,
        Colors.orangeAccent,
        Colors.purpleAccent,
      ];
}
