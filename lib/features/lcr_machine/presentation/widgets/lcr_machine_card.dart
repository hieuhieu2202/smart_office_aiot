import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../viewmodels/lcr_dashboard_view_state.dart';

class LcrMachineCard extends StatefulWidget {
  const LcrMachineCard({
    super.key,
    required this.data,
  });

  final LcrMachineGauge data;

  @override
  State<LcrMachineCard> createState() => _LcrMachineCardState();
}

class _LcrMachineCardState extends State<LcrMachineCard>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _rotationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data;
    final total = data.total == 0 ? 1 : data.total;
    final double passRatio =
    (data.pass / total).clamp(0.0, 1.0).toDouble();
    final double failRatio =
    (data.fail / total).clamp(0.0, 1.0).toDouble();

    const gaugeDesignSize = 260.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF03132D).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            'MACHINE ${data.machineNo}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final glow = 0.45 + _pulse.value * 0.55;
                    final orbitGlow = 0.35 + _pulse.value * 0.45;
                    return Container(
                      padding: EdgeInsets.all(8 + 8 * glow),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent
                                .withOpacity(0.12 + _pulse.value * 0.18),
                            blurRadius: 24 * glow,
                            spreadRadius: 3 * glow,
                          ),
                        ],
                      ),
                      child: SizedBox.square(
                        dimension: gaugeDesignSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              painter: _MachineGaugePainter(
                                passRatio: passRatio,
                                failRatio: failRatio,
                              ),
                              child: const SizedBox.expand(),
                            ),
                            RotationTransition(
                              turns: _rotationController,
                              child: CustomPaint(
                                painter: _OrbitPainter(glow: orbitGlow),
                                child: const SizedBox.expand(),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  data.pass.toString(),
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'PCS PASS',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.cyanAccent.withOpacity(0.85),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
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

    final outerRadius = radius * 0.94;

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFF04152B),
          Color(0xFF071F3E),
          Color(0xFF031126),
        ],
        stops: const [0.1, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius * 0.6));
    canvas.drawCircle(center, outerRadius * 0.6, corePaint);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.22
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF082347);

    final trackRect = Rect.fromCircle(center: center, radius: outerRadius * 0.8);
    canvas.drawArc(trackRect, -math.pi / 2, math.pi * 2, false, trackPaint);

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05
      ..strokeCap = StrokeCap.round
      ..color = Colors.white10;

    final dashRect = Rect.fromCircle(center: center, radius: outerRadius * 0.94);
    const segmentCount = 32;
    final gapAngle = math.pi / 40;
    final usable = math.pi * 2 - gapAngle * segmentCount;
    final segmentSweep = usable / segmentCount;
    var start = -math.pi / 2;
    for (var i = 0; i < segmentCount; i++) {
      final intensity = 0.08 + (i % 4 == 0 ? 0.28 : 0.0);
      dashPaint.color = Colors.white.withOpacity(intensity);
      canvas.drawArc(dashRect, start, segmentSweep, false, dashPaint);
      start += segmentSweep + gapAngle;
    }

    if (passRatio > 0) {
      final progressRect =
      Rect.fromCircle(center: center, radius: outerRadius * 0.8);
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.22
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
          stops: const [0.0, 0.35, 0.82, 1.0],
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
      final failRect = Rect.fromCircle(center: center, radius: outerRadius * 0.63);
      final failPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.12
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + math.pi * 2,
          colors: const [
            Color(0xFFFF80E5),
            Color(0xFFE84AFF),
            Color(0xFFFF80E5),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(failRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);
      canvas.drawArc(
        failRect,
        -math.pi / 2,
        math.pi * 2 * failRatio.clamp(0, 1),
        false,
        failPaint,
      );
    }

    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.03
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawCircle(center, outerRadius * 0.55, innerRingPaint);
  }

  @override
  bool shouldRepaint(covariant _MachineGaugePainter oldDelegate) {
    return oldDelegate.passRatio != passRatio ||
        oldDelegate.failRatio != failRatio;
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.glow});

  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final orbitRadius = radius * 0.95;

    final rect = Rect.fromCircle(center: center, radius: orbitRadius);
    final sweep = math.pi * 0.9;
    final startAngle = -math.pi / 2;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.07
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweep,
        colors: [
          Colors.transparent,
          Colors.cyanAccent.withOpacity(glow.clamp(0, 1)),
          Colors.cyanAccent.withOpacity((glow * 0.7).clamp(0, 1)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 0.85, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, startAngle, sweep, false, arcPaint);

    final dotAngle = startAngle + sweep;
    final dotOffset = Offset(
      center.dx + orbitRadius * math.cos(dotAngle),
      center.dy + orbitRadius * math.sin(dotAngle),
    );

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.cyanAccent.withOpacity(glow.clamp(0, 1));
    canvas.drawCircle(dotOffset, radius * 0.08, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.glow != glow;
  }
}
