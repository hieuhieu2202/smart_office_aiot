import 'package:flutter/material.dart';

class DashboardSection extends StatelessWidget {
  const DashboardSection({super.key, this.label = 'Dashboard content placeholder'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.12)
            : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.18)
              : const Color(0xFFB3E5FC).withOpacity(0.65),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.78),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
