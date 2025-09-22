import 'package:flutter/material.dart';

class ChartCardHeader extends StatelessWidget {
  const ChartCardHeader({
    super.key,
    required this.label,
    required this.textStyle,
  });

  final String label;
  final TextStyle textStyle;

  static const double verticalPadding = 6.0;
  static const double horizontalPadding = 12.0;
  static const double borderRadius = 12.0;

  static double heightForStyle(TextStyle style, TextTheme textTheme) {
    final fallbackFontSize = textTheme.labelLarge?.fontSize ?? 14.0;
    final fontSize = style.fontSize ?? fallbackFontSize;
    final fallbackHeight = textTheme.labelLarge?.height ?? 1.2;
    final lineHeight = style.height ?? fallbackHeight;
    return fontSize * lineHeight + verticalPadding * 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final background = isDark
        ? primary.withOpacity(0.18)
        : primary.withOpacity(0.12);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.25)
        : primary.withOpacity(0.35);

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
      alignment: Alignment.center,
      child: Text(
        label,
        style: textStyle.copyWith(letterSpacing: 1.05),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ChartCardFooter extends StatelessWidget {
  const ChartCardFooter({
    super.key,
    required this.label,
    required this.textStyle,
    this.child,
  });

  final String label;
  final TextStyle textStyle;
  final Widget? child;

  static const double verticalPadding = 8.0;
  static const double horizontalPadding = 12.0;
  static const double borderRadius = 12.0;
  static const double childSpacing = 6.0;

  static double heightForStyle(TextStyle style, TextTheme textTheme) {
    final fallbackFontSize = textTheme.labelMedium?.fontSize ?? 13.0;
    final fontSize = style.fontSize ?? fallbackFontSize;
    final fallbackHeight = textTheme.labelMedium?.height ?? 1.2;
    final lineHeight = style.height ?? fallbackHeight;
    return fontSize * lineHeight + verticalPadding * 2;
  }

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: textStyle.copyWith(letterSpacing: 1.05),
            textAlign: TextAlign.center,
          ),
          if (child != null) ...[
            const SizedBox(height: childSpacing),
            child!,
          ],
        ],
      ),
    );
  }
}
