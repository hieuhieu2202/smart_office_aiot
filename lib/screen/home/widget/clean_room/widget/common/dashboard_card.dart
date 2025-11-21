import 'package:flutter/material.dart';
import 'package:smart_factory/config/global_color.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  const DashboardCard({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = isDark ? const Color(0xFF123B66) : Colors.white;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF071B35), const Color(0xFF0E2C51)]
              : [Colors.white, const Color(0xFFE4EDFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? GlobalColors.borderDark.withOpacity(.4)
              : GlobalColors.borderLight.withOpacity(.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.12),
            blurRadius: 26,
            spreadRadius: -8,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: highlight.withOpacity(isDark ? 0.25 : 0.65),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.cyanAccent.withOpacity(.15)
                : Colors.blueAccent.withOpacity(.12),
          ),
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
