part of 'package:smart_factory/screen/home/widget/smt/stencil_monitor/stencil_monitor_screen.dart';

class _InsightMetric {
  const _InsightMetric({
    required this.label,
    required this.value,
    required this.description,
    required this.accent,
  });

  final String label;
  final String value;
  final String description;
  final Color accent;
}

class _InsightsStrip extends StatelessWidget {
  const _InsightsStrip({required this.items});

  final List<_InsightMetric> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final palette = _StencilColorScheme.of(context);
    final textColor = palette.onSurface;
    final muted = palette.onSurfaceMuted;

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          final metric = items[index];
          return Container(
            width: 168,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: metric.accent.withOpacity(0.5)),
              color: palette.cardBackground,
              gradient: LinearGradient(
                colors: [
                  metric.accent.withOpacity(0.18),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.cardShadow,
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  metric.label,
                  style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                    fontFamily: _StencilTypography.heading,
                    fontSize: 11,
                    color: metric.accent,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  metric.value,
                  style: GlobalTextStyles.bodyLarge(isDark: palette.isDark).copyWith(
                    fontFamily: _StencilTypography.heading,
                    fontSize: 26,
                    color: textColor,
                  ),
                ),
                Text(
                  metric.description,
                  style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                    fontFamily: _StencilTypography.numeric,
                    fontSize: 11,
                    color: muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
