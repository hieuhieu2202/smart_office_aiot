import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../viewmodels/lcr_dashboard_view_state.dart';

class LcrMachineGaugeCard extends StatelessWidget {
  const LcrMachineGaugeCard({
    super.key,
    required this.data,
  });

  final LcrMachineGaugeData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seriesData = <_Slice>[
      _Slice('PASS', data.pass.toDouble(), Colors.cyanAccent),
      _Slice('FAIL', data.fail.toDouble(), Colors.pinkAccent),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF03132D).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'MACHINE ${data.machineNo}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 110,
            child: SfCircularChart(
              margin: EdgeInsets.zero,
              legend: Legend(isVisible: false),
              annotations: <CircularChartAnnotation>[
                CircularChartAnnotation(
                  widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.total.toString(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${data.yieldRate.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              series: <DoughnutSeries<_Slice, String>>[
                DoughnutSeries<_Slice, String>(
                  dataSource: seriesData,
                  xValueMapper: (_Slice slice, _) => slice.label,
                  yValueMapper: (_Slice slice, _) => slice.value,
                  pointColorMapper: (_Slice slice, _) => slice.color,
                  innerRadius: '70%',
                  radius: '100%',
                  explode: false,
                  dataLabelSettings: const DataLabelSettings(isVisible: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slice {
  _Slice(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}
