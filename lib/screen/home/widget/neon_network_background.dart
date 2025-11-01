import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../config/global_color.dart';

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
  static const int _minNodes = 45;
  static const int _maxNodes = 110;
  static const double _maxSpeed = 28;

  final List<_NeonNode> _nodes = <_NeonNode>[];
  final math.Random _random = math.Random();
  late final Ticker _ticker;
  Duration? _lastTick;
  Size _viewport = Size.zero;

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
            ? LinearGradient(
                colors: <Color>[
                  GlobalColors.bodyDarkBg,
                  Colors.blueGrey.shade900,
                  const Color(0xFF020A16),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
    final double base = math.min(_viewport.width, _viewport.height);
    return base.clamp(140.0, 220.0);
  }
}

class _NeonNetworkPainter extends CustomPainter {
  _NeonNetworkPainter({
    required this.nodes,
    required this.linkDistance,
    required this.isDark,
  });

  final List<_NeonNode> nodes;
  final double linkDistance;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty || linkDistance <= 0) {
      return;
    }

    final Color glowColor = isDark
        ? const Color(0xFF00E5FF)
        : const Color(0xFF2563EB);

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final Paint glowDotPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final Paint coreDotPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.9 : 0.8);

    for (int i = 0; i < nodes.length; i++) {
      final Offset origin = nodes[i].position;
      for (int j = i + 1; j < nodes.length; j++) {
        final Offset target = nodes[j].position;
        final double distance = (origin - target).distance;
        if (distance > linkDistance) {
          continue;
        }
        final double opacity = 1 - (distance / linkDistance);
        linePaint.color = glowColor.withOpacity(opacity.clamp(0.05, 0.8));
        canvas.drawLine(origin, target, linePaint);
      }
    }

    for (final _NeonNode node in nodes) {
      canvas.drawCircle(node.position, 2.8, glowDotPaint);
      canvas.drawCircle(node.position, 1.6, coreDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonNetworkPainter oldDelegate) => true;
}

class _NeonNode {
  _NeonNode({required this.position, required this.velocity});

  Offset position;
  Offset velocity;
}
