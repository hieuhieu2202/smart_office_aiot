import 'package:flutter/material.dart';

class CircularKpi extends StatefulWidget {
  final String label;
  final String valueText;
  final IconData iconData;

  const CircularKpi({
    super.key,
    required this.label,
    required this.valueText,
    required this.iconData,
  });

  @override
  State<CircularKpi> createState() => _CircularKpiState();
}

class _CircularKpiState extends State<CircularKpi>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    if (_spinCtrl.isAnimating) _spinCtrl.stop();
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ring = isDark ? Colors.cyanAccent : const Color(0xFF0EA5C6);
    final ringBg = isDark ? Colors.white10 : const Color(0xFFBFE8F5);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF2A4B5D);
    final valueColor = isDark ? Colors.white : const Color(0xFF0B2433);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        final circleSize = availableWidth.isFinite && availableWidth > 0
            ? availableWidth.clamp(120.0, 220.0)
            : 160.0;
        final iconSize = (circleSize * 0.35).clamp(36.0, 72.0);
        final labelSize = (circleSize * 0.12).clamp(13.0, 18.0);
        final valueSize = (circleSize * 0.18).clamp(20.0, 28.0);
        final strokeWidth = (circleSize / 12).clamp(5.0, 10.0);
        final gap = (circleSize * 0.08).clamp(10.0, 18.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: circleSize,
              height: circleSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _spinCtrl,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: strokeWidth,
                      valueColor: AlwaysStoppedAnimation<Color>(ring),
                      backgroundColor: ringBg,
                    ),
                  ),
                  RotationTransition(
                    turns: ReverseAnimation(_spinCtrl),
                    child: Icon(widget.iconData, size: iconSize, color: ring),
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),
            Text(widget.label,
                style: TextStyle(color: labelColor, fontSize: labelSize)),
            Text(
              widget.valueText,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontSize: valueSize,
              ),
            ),
          ],
        );
      },
    );
  }
}
