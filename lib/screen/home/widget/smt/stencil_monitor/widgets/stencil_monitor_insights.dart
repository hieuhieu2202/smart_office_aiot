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

    final frameBorder = palette.dividerColor.withOpacity(palette.isDark ? 0.35 : 0.25);
    final frameGradient = palette.isDark
        ? [
            palette.cardBackground.withOpacity(0.45),
            palette.surfaceOverlay.withOpacity(0.4),
            Colors.transparent,
          ]
        : [
            Colors.white.withOpacity(0.92),
            palette.surfaceOverlay.withOpacity(0.35),
            Colors.white.withOpacity(0.85),
          ];

    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: frameBorder),
        gradient: LinearGradient(
          colors: frameGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANALYSIS LINE TRACKING',
              style: GlobalTextStyles.bodyMedium(isDark: palette.isDark).copyWith(
                fontFamily: _StencilTypography.heading,
                color: palette.accentSecondary,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const itemWidth = 168.0;
                  const itemSpacing = 14.0;
                  final spacingCount = items.length > 1 ? items.length - 1 : 0;
                  final contentWidth =
                      (items.length * itemWidth) + (spacingCount * itemSpacing);

                  double horizontalPadding = 0;
                  if (constraints.maxWidth.isFinite) {
                    final centeredPadding =
                        (constraints.maxWidth - contentWidth) / 2;
                    if (centeredPadding > 0) {
                      horizontalPadding = centeredPadding;
                    }
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: itemSpacing),
                    itemBuilder: (_, index) {
                      final metric = items[index];
                      final accent = metric.accent;

                      return Container(
                        width: itemWidth,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: accent.withOpacity(0.6)),
                          gradient: LinearGradient(
                            colors: [
                              accent.withOpacity(palette.isDark ? 0.22 : 0.16),
                              palette.cardBackground.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: palette.cardShadow,
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              metric.label,
                              textAlign: TextAlign.center,
                              style: GlobalTextStyles.bodySmall(
                                      isDark: palette.isDark)
                                  .copyWith(
                                fontFamily: _StencilTypography.heading,
                                fontSize: 12,
                                color: accent,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              metric.value,
                              textAlign: TextAlign.center,
                              style: GlobalTextStyles.bodyLarge(
                                      isDark: palette.isDark)
                                  .copyWith(
                                fontFamily: _StencilTypography.heading,
                                fontSize: 28,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Flexible(
                              child: Text(
                                metric.description,
                                textAlign: TextAlign.center,
                                style: GlobalTextStyles.bodySmall(
                                        isDark: palette.isDark)
                                    .copyWith(
                                  fontFamily: _StencilTypography.numeric,
                                  fontSize: 11,
                                  color: muted,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
