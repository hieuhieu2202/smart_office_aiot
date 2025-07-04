import 'package:flutter/material.dart';

class AnimatedRotateIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  const AnimatedRotateIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 29,
  });

  @override
  State<AnimatedRotateIcon> createState() => _AnimatedRotateIconState();
}

class _AnimatedRotateIconState extends State<AnimatedRotateIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Lặp vô tận
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Icon(widget.icon, size: widget.size, color: widget.color),
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.1416,
          child: child,
        );
      },
    );
  }
}
