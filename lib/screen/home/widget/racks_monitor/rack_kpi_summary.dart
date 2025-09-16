import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/racks_monitor_controller.dart';

class RackNumbersBox extends StatelessWidget {
  const RackNumbersBox({super.key, required this.controller});

  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0E2A3A) : Colors.white;
    final border = BorderSide(
      color: isDark ? Colors.white24 : Colors.grey.shade300,
    );

    final labStyle = Theme.of(context).textTheme.labelMedium;
    final valStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);

    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: labStyle)),
          Text(v, style: valStyle),
        ],
      ),
    );

    return Obx(() {
      final qs = controller.data.value?.quantitySummary;
      final ut = (qs?.ut ?? 0).toStringAsFixed(2);
      final input = qs?.input ?? 0;
      final fail = qs?.fail ?? 0;
      final pass = qs?.pass ?? 0;
      final rePass = qs?.rePass ?? 0;

      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border.color),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SUMMARY',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            row('UT', '$ut %'),
            row('INPUT', '$input PCS'),
            row('FAIL', '$fail PCS'),
            row('PASS', '$pass PCS'),
            row('RE-PASS', '$rePass PCS'),
          ],
        ),
      );
    });
  }
}
