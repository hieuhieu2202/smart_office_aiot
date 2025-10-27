import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../viewmodels/lcr_dashboard_view_state.dart';

class LcrMachineCard extends StatelessWidget {
  const LcrMachineCard({
    super.key,
    required this.data,
  });

  final LcrMachineGauge data;

  static const List<Color> _palette = <Color>[
    Color(0xFF26C6DA),
    Color(0xFF7C4DFF),
    Color(0xFFFF4081),
    Color(0xFF64FFDA),
  ];

  Color get _accentColor {
    final safeIndex = (data.machineNo - 1) % _palette.length;
    return _palette[safeIndex < 0 ? safeIndex + _palette.length : safeIndex];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor;
    final gaugeValue = data.yieldRate.clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF03132D).withOpacity(0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            child: SfCircularChart(
              margin: EdgeInsets.zero,
              annotations: <CircularChartAnnotation>[
                CircularChartAnnotation(
                  radius: '0%',
                  widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${data.pass}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PCS PASS',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              series: <CircularSeries<_MachineGaugeSlice, String>>[
                RadialBarSeries<_MachineGaugeSlice, String>(
                  maximumValue: 100,
                  gap: '4%',
                  radius: '100%',
                  innerRadius: '68%',
                  cornerStyle: CornerStyle.bothCurve,
                  trackColor: const Color(0xFF11233E),
                  trackOpacity: 1,
                  dataSource: <_MachineGaugeSlice>[
                    _MachineGaugeSlice('yield', gaugeValue),
                  ],
                  xValueMapper: (_MachineGaugeSlice slice, _) => slice.label,
                  yValueMapper: (_MachineGaugeSlice slice, _) => slice.value,
                  pointColorMapper: (_, __) => accent,
                  dataLabelSettings: const DataLabelSettings(isVisible: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'MACHINE ${data.machineNo}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MachineGaugeSlice {
  const _MachineGaugeSlice(this.label, this.value);

  final String label;
  final double value;
}

