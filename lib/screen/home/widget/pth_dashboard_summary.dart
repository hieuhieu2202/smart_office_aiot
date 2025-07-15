import 'package:flutter/material.dart';
import '../../../config/global_color.dart';
import '../../../config/global_text_style.dart';

class PTHDashboardSummary extends StatelessWidget {
  final Map data;
  const PTHDashboardSummary({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = data['summary'] ?? {};
    final statList = [
      {"label": "PASS", "icon": Icons.check_circle, "color": Colors.green, "value": summary['pass'] ?? 0},
      {"label": "FAIL", "icon": Icons.cancel, "color": Colors.red, "value": summary['fail'] ?? 0},
      {"label": "YR (%)", "icon": Icons.percent, "color": Colors.blue, "value": summary['yr'] ?? 0},
      {"label": "FPR (%)", "icon": Icons.flag, "color": Colors.purple, "value": summary['fpr'] ?? 0},
      {"label": "RR (%)", "icon": Icons.refresh, "color": Colors.orange, "value": summary['rr'] ?? 0},
    ];

    return Card(
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: statList.map((stat) => _StatCard(
            icon: stat["icon"] as IconData,
            label: stat["label"] as String,
            value: stat["value"].toString(),
            color: stat["color"] as Color,
            isDark: isDark,
          )).toList(),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 7),
        Text(label, style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      ],
    );
  }
}
