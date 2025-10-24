import 'package:flutter/material.dart';

class CircularKpi extends StatelessWidget {
  final String label;
  final String valueText;
  final IconData iconData;
  final double circleSize;
  final double iconSize;
  final double labelSize;
  final double valueSize;

  const CircularKpi({
    super.key,
    required this.label,
    required this.valueText,
    required this.iconData,
    this.circleSize = 96,
    this.iconSize = 36,
    this.labelSize = 12,
    this.valueSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ring = isDark ? Colors.cyanAccent : const Color(0xFF0EA5C6);
    final ringBg = isDark ? Colors.white10 : const Color(0xFFBFE8F5);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF2A4B5D);
    final valueColor = isDark ? Colors.white : const Color(0xFF0B2433);

    final strokeWidth = (circleSize / 16).clamp(3.0, 6.5);
    final gap = (circleSize * 0.08).clamp(6.0, 10.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: circleSize,
              height: circleSize,
              child: CircularProgressIndicator(
                value: 1.0, // vòng tròn đầy (trang trí)
                strokeWidth: strokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(ring),
                backgroundColor: ringBg,
              ),
            ),
            Icon(iconData, size: iconSize, color: ring),
          ],
        ),
        SizedBox(height: gap),
        Text(label, style: TextStyle(color: labelColor, fontSize: labelSize)),
        Text(valueText,
            style: TextStyle(
                color: valueColor, fontWeight: FontWeight.w800, fontSize: valueSize)),
      ],
    );
  }
}
