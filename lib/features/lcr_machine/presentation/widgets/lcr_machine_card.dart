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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 120,
            child: SfCircularChart(
              margin: EdgeInsets.zero,
              annotations: <CircularChartAnnotation>[
                CircularChartAnnotation(
                  radius: '0%',
                  widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${gaugeValue.toStringAsFixed(0)}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        '${data.total} PCS',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
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
                  startAngle: 180,
                  endAngle: 0,
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
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MetricBadge(
                label: 'PASS',
                color: const Color(0xFF00E5FF),
                value: data.pass,
              ),
              _MetricBadge(
                label: 'FAIL',
                color: const Color(0xFFFF80AB),
                value: data.fail,
              ),
            ],
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

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '$value',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
