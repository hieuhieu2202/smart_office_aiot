import 'package:flutter/material.dart';

class LcrSummaryTile extends StatelessWidget {
  const LcrSummaryTile({
    super.key,
    required this.title,
    required this.value,
    this.suffix,
    required this.color,
    this.onTap,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String value;
  final String? suffix;
  final Color color;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    // 📱 Responsive breakpoint
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1100;

    // 🔹 Responsive sizing
    final paddingH = isMobile ? 12.0 : isTablet ? 14.0 : 16.0;
    final paddingV = isMobile ? 8.0 : isTablet ? 10.0 : 12.0;
    final titleFont = isMobile ? 12.0 : isTablet ? 13.0 : 14.0;
    final valueFont = isMobile ? 26.0 : isTablet ? 34.0 : 44.0;
    final suffixFont = isMobile ? 12.0 : isTablet ? 14.0 : 16.0;
    final height = isMobile ? 72.0 : isTablet ? 96.0 : 120.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.85),
              color.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 Title + Overview button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: titleFont,
                      letterSpacing: 0.8,
                      height: 1.0,
                    ),
                  ),
                ),
                if (actionLabel != null && onActionTap != null)
                  GestureDetector(
                    onTap: onActionTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 10,
                        vertical: isMobile ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 10 : 11.5,
                              letterSpacing: 0.4,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.table_rows_rounded,
                              size: 13, color: Colors.white60),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // 🔹 Value + suffix
            Align(
              alignment: Alignment.bottomLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: valueFont,
                        letterSpacing: 1.1,
                        height: 0.9,
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        suffix!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: suffixFont,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

      ),
    );
  }
}
