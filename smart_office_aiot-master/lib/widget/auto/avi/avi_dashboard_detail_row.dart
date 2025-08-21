import 'package:flutter/material.dart';
import '../../../config/global_color.dart';

class PTHDashboardDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const PTHDashboardDetailRow({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? GlobalColors.iconLight),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark
                ? GlobalColors.labelDark
                : GlobalColors.labelLight,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
