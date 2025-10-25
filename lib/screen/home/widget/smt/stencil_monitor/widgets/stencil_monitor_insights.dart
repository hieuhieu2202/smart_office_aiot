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
      height: 280,
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
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const itemWidth = 174.0;
                  const itemSpacing = 18.0;
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

                  Widget buildMetricCard(_InsightMetric metric) {
                    return _InsightMetricCard(
                      metric: metric,
                      palette: palette,
                      textColor: textColor,
                      mutedColor: muted,
                      width: itemWidth,
                    );
                  }

                  if (constraints.maxWidth.isFinite &&
                      contentWidth <= constraints.maxWidth) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0) const SizedBox(width: itemSpacing),
                            buildMetricCard(items[i]),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: itemSpacing),
                    itemBuilder: (_, index) {
                      final metric = items[index];
                      return buildMetricCard(metric);
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

class _InsightMetricCard extends StatefulWidget {
  const _InsightMetricCard({
    required this.metric,
    required this.palette,
    required this.textColor,
    required this.mutedColor,
    required this.width,
  });

  final _InsightMetric metric;
  final _StencilColorScheme palette;
  final Color textColor;
  final Color mutedColor;
  final double width;

  @override
  State<_InsightMetricCard> createState() => _InsightMetricCardState();
}

class _InsightMetricCardState extends State<_InsightMetricCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;
    final palette = widget.palette;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final accent = metric.accent;
        final glowStrength = 0.5 + (0.35 * t);
        final borderColor = Color.lerp(
          accent.withOpacity(0.55),
          accent.withOpacity(0.85),
          t,
        )!;
        final startGlow = Color.lerp(
          accent.withOpacity(palette.isDark ? 0.18 : 0.14),
          accent.withOpacity(palette.isDark ? 0.32 : 0.24),
          t,
        )!;
        final shadowColor = Color.lerp(
          palette.cardShadow,
          accent.withOpacity(palette.isDark ? 0.55 : 0.45),
          t,
        )!;

        return Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.4),
            gradient: LinearGradient(
              colors: [
                startGlow,
                palette.cardBackground.withOpacity(0.88),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(glowStrength * 0.6),
                blurRadius: 18 + (10 * t),
                spreadRadius: 1.2 + (2 * t),
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        );
      },
      child: _InsightCardContent(
        metric: metric,
        palette: palette,
        textColor: widget.textColor,
        mutedColor: widget.mutedColor,
      ),
    );
  }
}

class _InsightCardContent extends StatelessWidget {
  const _InsightCardContent({
    required this.metric,
    required this.palette,
    required this.textColor,
    required this.mutedColor,
  });

  final _InsightMetric metric;
  final _StencilColorScheme palette;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          metric.label,
          textAlign: TextAlign.center,
          style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
            fontFamily: _StencilTypography.heading,
            fontSize: 13,
            color: metric.accent,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          metric.value,
          textAlign: TextAlign.center,
          style: GlobalTextStyles.bodyLarge(isDark: palette.isDark).copyWith(
            fontFamily: _StencilTypography.heading,
            fontSize: 34,
            color: textColor,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 18),
        _DashedRule(color: metric.accent.withOpacity(palette.isDark ? 0.5 : 0.35)),
        const SizedBox(height: 14),
        Text(
          metric.description,
          textAlign: TextAlign.center,
          style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
            fontFamily: _StencilTypography.numeric,
            fontSize: 12,
            color: mutedColor.withOpacity(palette.isDark ? 0.95 : 0.9),
            height: 1.4,
          ),
          softWrap: true,
        ),
      ],
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 6.0;
        final dashSpace = 4.0;
        final available = constraints.maxWidth;
        final dashCount = math.max(
          1,
          (available / (dashWidth + dashSpace)).floor(),
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < dashCount; i++)
              Container(
                width: dashWidth,
                height: 1.4,
                margin: EdgeInsets.symmetric(horizontal: dashSpace / 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        );
      },
    );
  }
}
