import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/racks_monitor_controller.dart';

class PassByModelBar extends StatelessWidget {
  const PassByModelBar({super.key, required this.controller});
  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg  = isDark ? const Color(0xFF132738) : const Color(0xFFE9EEF4);

    const palette = <Color>[
      Color(0xFF4DA3FF), // blue
      Color(0xFF7F5CFF), // purple
      Color(0xFF2ECC71), // green
      Color(0xFFFFA726), // orange
      Color(0xFFE74C3C), // red
      Color(0xFF26C6DA), // cyan
    ];

    return Obx(() {
      final items = controller.passByModelAgg; // List<ModelPass>
      final data  = items.where((e) => e.pass > 0).toList();
      if (data.isEmpty) {
        return Text('No data', style: Theme.of(context).textTheme.bodySmall);
      }

      final maxVal = data.map((e) => e.pass).reduce((a, b) => a > b ? a : b);

      Widget row(int idx, ModelPass mp) {
        final color = palette[idx % palette.length];
        final value = mp.pass; // Output (totalPass) để khớp web
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 76,
                child: Text(
                  mp.model,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: barBg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: '${mp.model} · Output: $value PCS',
                        waitDuration: const Duration(milliseconds: 250),
                        child: FractionallySizedBox(
                          widthFactor: value / (maxVal == 0 ? 1 : maxVal),
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '$value',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PASS BY MODEL',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (var i = 0; i < data.length; i++) row(i, data[i]),
        ],
      );
    });
  }
}
