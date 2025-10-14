part of 'package:smart_factory/screen/home/widget/smt/stencil_monitor/stencil_monitor_screen.dart';

const List<String> _usageLegendOrder = [
  '0',
  '1 – 20K',
  '20K – 50K',
  '50K – 80K',
  '80K – 90K',
  '90K – 100K',
  'Greater than 100K',
  'Unknown',
];

Color _usageColorForLabel(String label, _StencilColorScheme palette) {
  final darkNeon = <String, Color>{
    '0': const Color(0xFF56D1FF),
    '1 – 20K': const Color(0xFF9A7BFF),
    '20K – 50K': const Color(0xFF3BFFC4),
    '50K – 80K': const Color(0xFFFFB74D),
    '80K – 90K': const Color(0xFF4FC3F7),
    '90K – 100K': const Color(0xFFFF7CE5),
    'Greater than 100K': const Color(0xFFFF6B6B),
    'Unknown': const Color(0xFFB0BEC5),
  };

  final lightVibrant = <String, Color>{
    '0': const Color(0xFF0284C7),
    '1 – 20K': const Color(0xFF6D28D9),
    '20K – 50K': const Color(0xFF0EA5E9),
    '50K – 80K': const Color(0xFFFF6F00),
    '80K – 90K': const Color(0xFF0EA293),
    '90K – 100K': const Color(0xFFEC4899),
    'Greater than 100K': const Color(0xFFD92D20),
    'Unknown': const Color(0xFF64748B),
  };

  final paletteMap = palette.isDark ? darkNeon : lightVibrant;
  return paletteMap[label] ?? GlobalColors.accentByIsDark(palette.isDark);
}

class _UsageLegendChip extends StatelessWidget {
  const _UsageLegendChip({
    required this.label,
    required this.count,
    required this.color,
    required this.textStyle,
    required this.palette,
  });

  final String label;
  final int count;
  final Color color;
  final TextStyle textStyle;
  final _StencilColorScheme palette;

  @override
  Widget build(BuildContext context) {
    final baseStyle = textStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: palette.onSurface,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(palette.isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.65), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: baseStyle),
        ],
      ),
    );
  }
}

class _UsagePrismChart extends StatelessWidget {
  const _UsagePrismChart({
    required this.slices,
    required this.palette,
  });

  final List<_PieSlice> slices;
  final _StencilColorScheme palette;

  @override
  Widget build(BuildContext context) {
    final ordered = <_PieSlice>[];
    final seen = <String>{};
    for (final label in _usageLegendOrder) {
      final slice = slices.where((item) => item.label == label).toList();
      if (slice.isNotEmpty) {
        ordered.add(slice.first);
        seen.add(label);
      }
    }
    for (final slice in slices) {
      if (seen.add(slice.label)) {
        ordered.add(slice);
      }
    }

    final maxValue = ordered.fold<int>(0, (max, slice) => math.max(max, slice.value));
    if (ordered.isEmpty || maxValue <= 0) {
      return Center(
        child: Text(
          'No usage data available',
          style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
            fontFamily: _StencilTypography.numeric,
            color: palette.onSurfaceMuted,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const leftInset = 42.0;
        const rightInset = 18.0;
        const topInset = 12.0;
        const bottomInset = 36.0;

        final chartHeight = constraints.maxHeight - topInset - bottomInset;
        final chartWidth = constraints.maxWidth - leftInset - rightInset;
        if (chartHeight <= 0 || chartWidth <= 0) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _UsageGridPainter(
                  palette: palette,
                  maxValue: maxValue,
                  leftInset: leftInset,
                  rightInset: rightInset,
                  topInset: topInset,
                  bottomInset: bottomInset,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(leftInset, topInset, rightInset, bottomInset),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final slice in ordered)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _UsagePrismBar(
                          value: slice.value,
                          maxValue: maxValue,
                          color: _usageColorForLabel(slice.label, palette),
                          palette: palette,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: leftInset,
              right: rightInset,
              bottom: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final slice in ordered)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          slice.label,
                          textAlign: TextAlign.center,
                          style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                            fontFamily: _StencilTypography.numeric,
                            fontSize: 11,
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UsagePrismBar extends StatelessWidget {
  const _UsagePrismBar({
    required this.value,
    required this.maxValue,
    required this.color,
    required this.palette,
  });

  final int value;
  final int maxValue;
  final Color color;
  final _StencilColorScheme palette;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
    return LayoutBuilder(
      builder: (context, constraints) {
        final barHeight = (constraints.maxHeight * ratio).clamp(6.0, constraints.maxHeight);

        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: double.infinity,
            height: barHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: barHeight,
                    child: CustomPaint(
                      painter: _PrismBarPainter(
                        color: color,
                        palette: palette,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -26,
                  child: _UsageValueBadge(
                    value: value,
                    color: color,
                    palette: palette,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UsageValueBadge extends StatelessWidget {
  const _UsageValueBadge({
    required this.value,
    required this.color,
    required this.palette,
  });

  final int value;
  final Color color;
  final _StencilColorScheme palette;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        _lightenColor(color, palette.isDark ? 0.42 : 0.18),
        _darkenColor(color, palette.isDark ? 0.1 : 0.02),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _darkenColor(color, 0.12), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontFamily: _StencilTypography.numeric,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: palette.isDark ? Colors.black : Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PrismBarPainter extends CustomPainter {
  const _PrismBarPainter({
    required this.color,
    required this.palette,
  });

  final Color color;
  final _StencilColorScheme palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final depth = math.min(size.width * 0.35, size.height * 0.3);
    final frontWidth = math.max(1.0, size.width - depth);
    final frontHeight = math.max(1.0, size.height - depth);
    final frontRect = Rect.fromLTWH(0, depth, frontWidth, frontHeight);

    final rightFace = Path()
      ..moveTo(frontRect.right, frontRect.top)
      ..lineTo(frontRect.right + depth, frontRect.top - depth)
      ..lineTo(frontRect.right + depth, frontRect.bottom - depth)
      ..lineTo(frontRect.right, frontRect.bottom)
      ..close();

    final topFace = Path()
      ..moveTo(frontRect.left, frontRect.top)
      ..lineTo(frontRect.right, frontRect.top)
      ..lineTo(frontRect.right + depth, frontRect.top - depth)
      ..lineTo(frontRect.left + depth, frontRect.top - depth)
      ..close();

    final frontFace = Path()..addRect(frontRect);

    final base = color;

    final rightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _darkenColor(base, 0.05),
          _darkenColor(base, 0.22),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rightFace.getBounds());
    canvas.drawPath(rightFace, rightPaint);

    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _lightenColor(base, 0.28),
          _lightenColor(base, 0.08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(topFace.getBounds());
    canvas.drawPath(topFace, topPaint);

    final frontPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _lightenColor(base, 0.18),
          base,
          _darkenColor(base, 0.15),
        ],
        stops: const [0.0, 0.45, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(frontRect);
    canvas.drawPath(frontFace, frontPaint);

    final outline = Paint()
      ..color = _darkenColor(base, palette.isDark ? 0.22 : 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawPath(frontFace, outline);
    canvas.drawPath(rightFace, outline);
    canvas.drawPath(topFace, outline);
  }

  @override
  bool shouldRepaint(covariant _PrismBarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.palette.isDark != palette.isDark;
  }
}

class _UsageGridPainter extends CustomPainter {
  const _UsageGridPainter({
    required this.palette,
    required this.maxValue,
    required this.leftInset,
    required this.rightInset,
    required this.topInset,
    required this.bottomInset,
  });

  final _StencilColorScheme palette;
  final int maxValue;
  final double leftInset;
  final double rightInset;
  final double topInset;
  final double bottomInset;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - topInset - bottomInset;
    final chartWidth = size.width - leftInset - rightInset;
    if (chartHeight <= 0 || chartWidth <= 0) {
      return;
    }

    final axisPaint = Paint()
      ..color = palette.onSurface.withOpacity(palette.isDark ? 0.26 : 0.18)
      ..strokeWidth = 1;

    final gridPaint = Paint()
      ..color = palette.onSurface.withOpacity(palette.isDark ? 0.18 : 0.12)
      ..strokeWidth = 1;

    const gridCount = 4;
    final labelStyle = TextStyle(
      fontFamily: _StencilTypography.numeric,
      fontSize: 10,
      color: palette.onSurfaceMuted,
    );

    for (var i = 0; i <= gridCount; i++) {
      final y = topInset + chartHeight - (chartHeight / gridCount) * i;
      canvas.drawLine(
        Offset(leftInset, y),
        Offset(leftInset + chartWidth, y),
        i == 0 ? axisPaint : gridPaint,
      );

      final value = (maxValue / gridCount * i).round();
      final painter = TextPainter(
        text: TextSpan(text: '$value', style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(leftInset - painter.width - 6, y - painter.height / 2),
      );
    }

    canvas.drawLine(
      Offset(leftInset, topInset + chartHeight),
      Offset(leftInset + chartWidth, topInset + chartHeight),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _UsageGridPainter oldDelegate) {
    return oldDelegate.maxValue != maxValue ||
        oldDelegate.palette.isDark != palette.isDark;
  }
}

Color _darkenColor(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}

Color _lightenColor(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}
