import 'package:flutter/material.dart';

class RackPanelCard extends StatelessWidget {
  const RackPanelCard({
    required this.child,
    this.margin,
    super.key,
  });

  static const EdgeInsets contentPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  static double get horizontalPadding => contentPadding.horizontal;

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: contentPadding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1E30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black.withOpacity(0.4) : Colors.blueGrey.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
