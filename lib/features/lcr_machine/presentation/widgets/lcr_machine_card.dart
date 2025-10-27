import 'dart:math' as math;

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
    final computedTotal = data.total > 0 ? data.total : data.pass;
    final safeMax = math.max(computedTotal, 1).toDouble();
    final passValue = data.pass.toDouble().clamp(0.0, safeMax);
    final remainder = (safeMax - passValue).clamp(0.0, safeMax);
    final segments = <_GaugeSegment>[
      _GaugeSegment(label: 'pass', value: passValue, color: accent),
      _GaugeSegment(
        label: 'remaining',
        value: remainder,
        color: const Color(0xFF0C1E38),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF03132D).withOpacity(0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 118,
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
                      const SizedBox(height: 4),
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
              series: <CircularSeries<_GaugeSegment, String>>[
                DoughnutSeries<_GaugeSegment, String>(
                  dataSource: segments,
                  xValueMapper: (_GaugeSegment segment, _) => segment.label,
                  yValueMapper: (_GaugeSegment segment, _) => segment.value,
                  pointColorMapper: (_GaugeSegment segment, _) => segment.color,
                  startAngle: 180,
                  endAngle: 0,
                  radius: '112%',
                  innerRadius: '70%',
                  cornerStyle: CornerStyle.bothCurve,
                  dataLabelSettings: const DataLabelSettings(isVisible: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '0',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                data.total > 0 ? data.total.toString() : '0',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'MACHINE ${data.machineNo}',
            textAlign: TextAlign.center,
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

class _GaugeSegment {
  const _GaugeSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

