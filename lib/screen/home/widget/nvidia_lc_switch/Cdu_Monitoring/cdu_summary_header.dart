import 'package:flutter/material.dart';

class CduSummaryHeader extends StatelessWidget {
  final int total;
  final int running;
  final int warning;
  final int abnormal;

  const CduSummaryHeader({
    super.key,
    required this.total,
    required this.running,
    required this.warning,
    required this.abnormal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    Widget item({
      required String title,
      required int value,
      required IconData icon,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? color.withOpacity(0.9) : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Responsive grid
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        int cols = 4;
        if (w < 480) cols = 2;
        else if (w < 900) cols = 3;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.9,
          ),
          children: [
            item(
              title: 'Total CDU',
              value: total,
              icon: Icons.precision_manufacturing,
              color: Colors.blueGrey,
            ),
            item(
              title: 'Running',
              value: running,
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            item(
              title: 'Warning',
              value: warning,
              icon: Icons.warning_amber,
              color: Colors.orange,
            ),
            item(
              title: 'Abnormal',
              value: abnormal,
              icon: Icons.block,
              color: Colors.red,
            ),
          ],
        );
      },
    );
  }
}
