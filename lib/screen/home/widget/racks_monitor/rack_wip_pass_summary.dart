import 'package:flutter/material.dart';
import '../../controller/racks_monitor_controller.dart';

class WipPassSummary extends StatelessWidget {
  const WipPassSummary({super.key, required this.controller});
  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final qs = controller.data.value!.quantitySummary;

    Widget line(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: Theme.of(context).textTheme.labelLarge)),
          Text(v, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TOTALS', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        line('WIP',  '${qs.wip} PCS'),
        line('PASS', '${qs.totalPass} PCS'),
      ],
    );
  }
}
