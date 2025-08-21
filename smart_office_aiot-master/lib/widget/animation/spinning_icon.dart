import 'package:flutter/material.dart';

class SpinningIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;

  const SpinningIcon({
    super.key,
    required this.icon,
    this.size = 36,
    this.color = Colors.blue,
  });

  @override
  State<SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<SpinningIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Lặp vô hạn
  }

  @override
  void dispose() {
    _controller.dispose(); // Ngừng khi widget bị huỷ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
