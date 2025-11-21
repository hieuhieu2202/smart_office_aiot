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
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0c213f), const Color(0xFF12345e)]
              : [Colors.white, const Color(0xFFE8F1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? GlobalColors.borderDark.withOpacity(.32)
              : GlobalColors.borderLight.withOpacity(.32),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: highlight.withOpacity(isDark ? 0.24 : 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.cyanAccent.withOpacity(.14)
                : Colors.blueAccent.withOpacity(.14),
          ),
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
