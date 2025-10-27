import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../viewmodels/lcr_dashboard_view_state.dart';

class LcrMachineCard extends StatelessWidget {
  const LcrMachineCard({
    super.key,
    required this.data,
    required this.maxPass,
  });

  final LcrMachineGauge data;
  final int maxPass;

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
    final labelAccent = accent.withOpacity(0.75);
    final pcsPassStyle = theme.textTheme.labelSmall?.copyWith(
          color: labelAccent,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          fontSize: 9,
        ) ??
        TextStyle(
          color: labelAccent,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          fontSize: 9,
        );
    final overallMax = math.max(maxPass, data.pass);
    final gaugeMaxLabel = overallMax > 0 ? overallMax : 0;
    final safeMax = gaugeMaxLabel > 0 ? gaugeMaxLabel.toDouble() : 1.0;
    final passValue = gaugeMaxLabel > 0
        ? data.pass.toDouble().clamp(0.0, safeMax)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF03132D).withOpacity(0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 140.0;
                final maxWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 140.0;
                final chartExtent = math.min(maxHeight, maxWidth);
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: chartExtent,
                    width: chartExtent,
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
                                style: theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      fontSize: 22,
                                    ) ??
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22,
                                      letterSpacing: 0.4,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text('PCS PASS', style: pcsPassStyle),
                            ],
                          ),
                        ),
                      ],
                      series: <CircularSeries<_RadialGaugePoint, String>>[
                        RadialBarSeries<_RadialGaugePoint, String>(
                          dataSource: const <_RadialGaugePoint>[
                            _RadialGaugePoint(label: 'pass'),
                          ],
                          maximumValue: safeMax,
                          xValueMapper: (_RadialGaugePoint point, _) => point.label,
                          yValueMapper: (_RadialGaugePoint point, _) => passValue,
                          pointShaderMapper: (
                            ChartShaderDetails details,
                            _RadialGaugePoint point,
                            Color color,
                            Rect rect,
                          ) {
                            return LinearGradient(
                              colors: [accent.withOpacity(0.35), accent],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ).createShader(rect);
                          },
                          trackColor: const Color(0xFF071B32),
                          trackBorderColor: Colors.transparent,
                          trackOpacity: 1,
                          cornerStyle: CornerStyle.bothCurve,
                          gap: '0%',
                          radius: '120%',
                          innerRadius: '58%',
                          animationDuration: 1400,
                          dataLabelSettings:
                              const DataLabelSettings(isVisible: false),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '0',
                style: theme.textTheme.labelMedium?.copyWith(
                      color: accent.withOpacity(0.85),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                gaugeMaxLabel.toString(),
                style: theme.textTheme.labelMedium?.copyWith(
                      color: accent.withOpacity(0.85),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'MACHINE ${data.machineNo}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
                  color: accent.withOpacity(0.9),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
          ),
        ],
      ),
    );
  }
}

class _RadialGaugePoint {
  const _RadialGaugePoint({required this.label});

  final String label;
}

