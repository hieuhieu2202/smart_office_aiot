import 'package:flutter/material.dart';

class ChartCardFooter extends StatelessWidget {
  const ChartCardFooter({
    super.key,
    required this.label,
    required this.textStyle,
  });

  final String label;
  final TextStyle textStyle;

  static const double verticalPadding = 8.0;
  static const double horizontalPadding = 12.0;
  static const double borderRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final background = isDark
        ? primary.withOpacity(0.22)
        : primary.withOpacity(0.08);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.18)
        : primary.withOpacity(0.24);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        label,
        style: textStyle.copyWith(letterSpacing: 1.05),
        textAlign: TextAlign.center,
      ),
    );
  }
}
