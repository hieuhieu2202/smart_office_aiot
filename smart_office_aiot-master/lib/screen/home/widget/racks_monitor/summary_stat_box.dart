import 'package:flutter/material.dart';

class SummaryStatBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final bool isDark; // Nếu cần thay đổi theo theme

  const SummaryStatBox({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Colors.white
                  : Colors.black.withOpacity(0.50), // nhạt đều, tuỳ theme
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
