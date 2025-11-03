import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class NeonNetworkBackdrop extends StatefulWidget {
  const NeonNetworkBackdrop({
    super.key,
    required this.isDark,
    required this.child,
  });

  final bool isDark;
  final Widget child;

  @override
  State<NeonNetworkBackdrop> createState() => _NeonNetworkBackdropState();
}

class _NeonNetworkBackdropState extends State<NeonNetworkBackdrop>
    with SingleTickerProviderStateMixin {
  static const int _minNodes = 70;
  static const int _maxNodes = 130;
  static const double _maxSpeed = 28;

  final List<_NeonNode> _nodes = <_NeonNode>[];
  final math.Random _random = math.Random();
  late final Ticker _ticker;
  Duration? _lastTick;
  Size _viewport = Size.zero;
  double _pulsePhase = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _handleTick(Duration elapsed) {
    if (!mounted || _viewport == Size.zero) {
      _lastTick = elapsed;
      return;
    }

    final Duration? lastTick = _lastTick;
    _lastTick = elapsed;
    if (lastTick == null) {
      return;
    }

    final double dt = (elapsed - lastTick).inMicroseconds / 1e6;
    if (dt <= 0 || _nodes.isEmpty) {
      return;
    }

    final double width = _viewport.width;
    final double height = _viewport.height;

    for (final _NeonNode node in _nodes) {
      Offset position = node.position + node.velocity * dt;
      double dx = node.velocity.dx;
      double dy = node.velocity.dy;

      if (position.dx <= 0 || position.dx >= width) {
        dx = -dx;
        position = Offset(
          position.dx.clamp(0.0, width),
          position.dy,
        );
      }
      if (position.dy <= 0 || position.dy >= height) {
        dy = -dy;
        position = Offset(
          position.dx,
          position.dy.clamp(0.0, height),
        );
      }

      node
        ..position = position
        ..velocity = Offset(dx, dy);
    }

    _pulsePhase = (_pulsePhase + dt * 1.6) % (2 * math.pi);

    setState(() {});
  }

  void _seedNodes() {
    if (_viewport == Size.zero) {
      return;
    }

    final double area = _viewport.width * _viewport.height;
    final double density = (area / 22000)
        .clamp(0.0, (_maxNodes - _minNodes).toDouble());
    final int rawTarget = (_minNodes + density).round();
    final int target = math.min(math.max(rawTarget, _minNodes), _maxNodes);

    _nodes
      ..clear()
      ..addAll(List<_NeonNode>.generate(target, (_) {
        final Offset position = Offset(
          _random.nextDouble() * _viewport.width,
          _random.nextDouble() * _viewport.height,
        );
        final double angle = _random.nextDouble() * 2 * math.pi;
        final double speed = 12 + _random.nextDouble() * (_maxSpeed - 12);
        return _NeonNode(
          position: position,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        );
      }));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size nextViewport = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );
        if (nextViewport != _viewport) {
          _viewport = nextViewport;
          _seedNodes();
        }

        final Gradient gradient = widget.isDark
            ? const RadialGradient(
                colors: <Color>[
                  Color(0xFF010B18),
                  Color(0xFF00040D),
                ],
                center: Alignment.center,
                radius: 1.0,
              )
            : const LinearGradient(
                colors: <Color>[
                  Color(0xFFE0F2FF),
                  Color(0xFFF0F4FF),
                  Color(0xFFCCE7FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(gradient: gradient),
            ),
            if (_viewport != Size.zero)
              RepaintBoundary(
                child: CustomPaint(
                  painter: _NeonNetworkPainter(
                    nodes: _nodes,
                    linkDistance: _computeLinkDistance(),
                    isDark: widget.isDark,
                    pulsePhase: _pulsePhase,
                  ),
                ),
              ),
            widget.child,
          ],
        );
      },
    );
  }

  double _computeLinkDistance() {
    if (_viewport == Size.zero) {
      return 0;
    }
    final double base = math.min(_viewport.width, _viewport.height) * 0.4;
    return base.clamp(100.0, 160.0);
  }
}

class _NeonNetworkPainter extends CustomPainter {
  _NeonNetworkPainter({
    required this.nodes,
    required this.linkDistance,
    required this.isDark,
    required this.pulsePhase,
  });

  final List<_NeonNode> nodes;
  final double linkDistance;
  final bool isDark;
  final double pulsePhase;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty || linkDistance <= 0) {
      return;
    }

    canvas.saveLayer(Offset.zero & size, Paint());

    final Color glowColor = isDark
        ? const Color(0xFF00E5FF)
        : const Color(0xFF00E5FF);

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;

    final Paint glowDotPaint = Paint()
      ..color = glowColor.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12)
      ..blendMode = BlendMode.plus;

    final Paint coreDotPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.95 : 0.85);

    final double pulse = (math.sin(pulsePhase) * 0.6) + 0.8;

    for (int i = 0; i < nodes.length; i++) {
      final Offset origin = nodes[i].position;
      for (int j = i + 1; j < nodes.length; j++) {
        final Offset target = nodes[j].position;
        final double distance = (origin - target).distance;
        if (distance > linkDistance) {
          continue;
        }
        final double opacity = 1 - (distance / linkDistance);
        final double intensity = (opacity * pulse).clamp(0.08, 1.0);
        linePaint.color = glowColor.withOpacity(intensity);
        canvas.drawLine(origin, target, linePaint);
      }
    }

    for (final _NeonNode node in nodes) {
      canvas.drawCircle(node.position, 3.0, glowDotPaint);
      canvas.drawCircle(node.position, 1.4, coreDotPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeonNetworkPainter oldDelegate) => true;
}

class _NeonNode {
  _NeonNode({required this.position, required this.velocity});

  Offset position;
  Offset velocity;
}
