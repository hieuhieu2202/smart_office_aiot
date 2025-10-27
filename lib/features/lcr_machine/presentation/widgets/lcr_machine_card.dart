import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

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
            height: 100,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  startAngle: 180,
                  endAngle: 0,
                  showLabels: false,
                  showTicks: false,
                  radiusFactor: 0.9,
                  canScaleToFit: true,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.14,
                    thicknessUnit: GaugeSizeUnit.factor,
                    cornerStyle: CornerStyle.bothCurve,
                    color: Color(0xFF11233E),
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: gaugeValue,
                      width: 0.16,
                      sizeUnit: GaugeSizeUnit.factor,
                      cornerStyle: CornerStyle.bothCurve,
                      gradient: SweepGradient(
                        colors: <Color>[
                          accent,
                          accent.withOpacity(0.25),
                        ],
                        stops: const <double>[0.2, 1.0],
                      ),
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      angle: 90,
                      positionFactor: 0,
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
