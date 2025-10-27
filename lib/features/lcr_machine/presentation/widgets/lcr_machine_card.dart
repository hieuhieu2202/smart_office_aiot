import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../viewmodels/lcr_dashboard_view_state.dart';

class LcrMachineCard extends StatelessWidget {
  const LcrMachineCard({
    super.key,
    required this.data,
  });

  final LcrMachineGauge data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.total == 0 ? 1 : data.total;
    final passRatio = data.pass / total;
    final failRatio = data.fail / total;

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 24.0;
        const headerSpacing = 72.0;
        var gaugeSize = 132.0;

        final maxWidth = constraints.maxWidth.isFinite
            ? math.max(0.0, constraints.maxWidth - horizontalPadding)
            : double.infinity;
        final maxHeight = constraints.maxHeight.isFinite
            ? math.max(0.0, constraints.maxHeight - headerSpacing)
            : double.infinity;

        if (maxWidth.isFinite) {
          gaugeSize = math.min(gaugeSize, maxWidth);
        }

        if (maxHeight.isFinite) {
          gaugeSize = math.min(gaugeSize, maxHeight);
        }

        gaugeSize = gaugeSize.clamp(48.0, 180.0);

        if (maxWidth.isFinite) {
          gaugeSize = math.min(gaugeSize, maxWidth);
        }

        if (maxHeight.isFinite) {
          gaugeSize = math.min(gaugeSize, maxHeight);
        }

        if (gaugeSize <= 0) {
          gaugeSize = math.min(48.0, constraints.maxWidth.isFinite ? constraints.maxWidth : 48.0);
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF03132D).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MACHINE ${data.machineNo}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: gaugeSize,
                width: gaugeSize,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          painter: _MachineGaugePainter(
                            passRatio: passRatio.clamp(0, 1),
                            failRatio: failRatio.clamp(0, 1),
                          ),
                          child: const SizedBox.expand(),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data.total.toString(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${data.yieldRate.toStringAsFixed(1)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: [
                  _LegendTile(
                    label: 'PASS',
                    value: data.pass,
                    color: Colors.cyanAccent,
                  ),
                  _LegendTile(
                    label: 'FAIL',
                    value: data.fail,
                    color: Colors.pinkAccent,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendTile extends StatelessWidget {
  const _LegendTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MachineGaugePainter extends CustomPainter {
  const _MachineGaugePainter({
    required this.passRatio,
    required this.failRatio,
  });

  final double passRatio;
  final double failRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;

    final outerRadius = radius * 0.9;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.18
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF0A2850);

    final trackRect = Rect.fromCircle(center: center, radius: outerRadius * 0.78);
    canvas.drawArc(trackRect, -math.pi / 2, math.pi * 2, false, trackPaint);

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..strokeCap = StrokeCap.round
      ..color = Colors.white10;

    final dashRect = Rect.fromCircle(center: center, radius: outerRadius);
    const segmentCount = 28;
    final gapAngle = math.pi / 36; // 5 degrees
    final usable = math.pi * 2 - gapAngle * segmentCount;
    final segmentSweep = usable / segmentCount;
    var start = -math.pi / 2;
    for (var i = 0; i < segmentCount; i++) {
      final intensity = 0.1 + (i % 3 == 0 ? 0.25 : 0.0);
      dashPaint.color = Colors.white.withOpacity(intensity);
      canvas.drawArc(dashRect, start, segmentSweep, false, dashPaint);
      start += segmentSweep + gapAngle;
    }

    if (passRatio > 0) {
      final progressRect = Rect.fromCircle(center: center, radius: outerRadius * 0.78);
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.18
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + math.pi * 2,
          colors: const [
            Color(0xFF33F2FF),
            Color(0xFF2FC4FF),
            Color(0xFF8657FF),
            Color(0xFF33F2FF),
          ],
          stops: const [0.0, 0.45, 0.8, 1.0],
        ).createShader(progressRect);
      canvas.drawArc(
        progressRect,
        -math.pi / 2,
        math.pi * 2 * passRatio.clamp(0, 1),
        false,
        progressPaint,
      );
    }

    if (failRatio > 0) {
      final failRect = Rect.fromCircle(center: center, radius: outerRadius * 0.58);
      final failPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.1
        ..strokeCap = StrokeCap.round
        ..color = Colors.pinkAccent.withOpacity(0.8);
      canvas.drawArc(
        failRect,
        -math.pi / 2,
        math.pi * 2 * failRatio.clamp(0, 1),
        false,
        failPaint,
      );
    }

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.02
      ..color = Colors.white10;
    canvas.drawCircle(center, outerRadius * 0.4, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _MachineGaugePainter oldDelegate) {
    return oldDelegate.passRatio != passRatio || oldDelegate.failRatio != failRatio;
  }
}
