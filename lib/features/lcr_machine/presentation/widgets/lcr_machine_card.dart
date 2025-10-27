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
          const SizedBox(height: 12),
          _MachinePerformanceGauge(data: data),
        ],
      ),
    );
  }
}

class _MachinePerformanceGauge extends StatelessWidget {
  const _MachinePerformanceGauge({
    required this.data,
  });

  final LcrMachineGauge data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passRate = data.total > 0 ? data.pass / data.total : 0;
    final Color primary = Colors.cyanAccent;
    final Color secondary = const Color(0xFF58E1FF);
    final Color alert = Colors.pinkAccent;

    return SizedBox(
      height: 120,
      width: 120,
      child: CustomPaint(
        painter: _MachinePerformancePainter(
          progress: passRate.clamp(0.0, 1.0).toDouble(),
          primaryColor: primary,
          secondaryColor: secondary,
          alertColor: alert,
        ),
        child: Center(
          child: Column(
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
      ),
    );
  }
}

class _MachinePerformancePainter extends CustomPainter {
  _MachinePerformancePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.alertColor,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color alertColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = math.min(size.width, size.height) / 2;
    final double outerRadius = radius * 0.9;
    final double strokeWidth = outerRadius * 0.28;
    final Rect outerRect = Rect.fromCircle(center: center, radius: outerRadius);

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = primaryColor.withOpacity(0.12)
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(outerRect, -math.pi / 2, math.pi * 2, false, trackPaint);

    if (progress < 1) {
      final Paint failPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = alertColor.withOpacity(0.4)
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        outerRect,
        -math.pi / 2 + progress * math.pi * 2,
        (1 - progress) * math.pi * 2,
        false,
        failPaint,
      );
    }

    if (progress > 0) {
      final SweepGradient gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: <Color>[
          primaryColor.withOpacity(0.25),
          primaryColor,
          secondaryColor,
        ],
        stops: const <double>[0, 0.65, 1],
      );

      final Paint progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = gradient.createShader(outerRect)
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        outerRect,
        -math.pi / 2,
        progress * math.pi * 2,
        false,
        progressPaint,
      );
    }

    final double accentRadius = outerRadius * 0.7;
    final Paint accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.45
      ..strokeCap = StrokeCap.round
      ..color = secondaryColor.withOpacity(0.45);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: accentRadius),
      -math.pi / 2 + math.pi / 9,
      math.pi / 6,
      false,
      accentPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: accentRadius * 0.92),
      math.pi + math.pi / 12,
      math.pi / 10,
      false,
      accentPaint..color = primaryColor.withOpacity(0.35),
    );

    final Paint innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.35
      ..color = Colors.white.withOpacity(0.08);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius * 0.45),
      0,
      math.pi * 2,
      false,
      innerRingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MachinePerformancePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.alertColor != alertColor;
  }
}
