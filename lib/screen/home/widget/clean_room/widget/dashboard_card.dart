import 'package:flutter/material.dart';
import '../../../../../config/global_color.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const DashboardCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? GlobalColors.borderDark.withOpacity(.4)
              : GlobalColors.borderLight.withOpacity(.4),
        ),
      ),
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
