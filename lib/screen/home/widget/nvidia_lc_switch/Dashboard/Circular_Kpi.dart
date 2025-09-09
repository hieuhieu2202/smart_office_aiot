import 'package:flutter/material.dart';

class CircularKpi extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ring = isDark ? Colors.cyanAccent : const Color(0xFF0EA5C6);
    final ringBg = isDark ? Colors.white10 : const Color(0xFFBFE8F5);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF2A4B5D);
    final valueColor = isDark ? Colors.white : const Color(0xFF0B2433);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: CircularProgressIndicator(
                value: 1.0, // vòng tròn đầy (trang trí)
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(ring),
                backgroundColor: ringBg,
              ),
            ),
            Icon(iconData, size: 36, color: ring),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
        Text(valueText, style: TextStyle(color: valueColor, fontWeight: FontWeight.w800, fontSize: 18)),
      ],
    );
  }
}
