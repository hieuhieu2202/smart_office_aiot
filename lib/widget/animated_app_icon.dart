import 'package:flutter/material.dart';
import 'dart:math';

/// Tên các hiệu ứng bạn sẽ dùng trong app
enum AppIconEffect {
  pulse,        // Phóng to-thu nhỏ (scale)
  glow,         // Viền sáng nhấp nháy
  shake,        // Rung nhẹ ngang
  flash,        // Chớp sáng nhanh (opacity)
  colorLoop,    // Đổi màu luân phiên (fire, warning)
  sweep,        // Sweep (dành cho Dashboard, complex)
  none,         // Không hiệu ứng
}

class AnimatedAppIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final AppIconEffect effect;
  final Duration duration;
  final double size;
  final Color? altColor; // dùng cho hiệu ứng đổi màu

  const AnimatedAppIcon({
    Key? key,
    required this.icon,
    required this.color,
    required this.effect,
    this.duration = const Duration(milliseconds: 900),
    this.size = 32,
    this.altColor,
  }) : super(key: key);

  @override
  State<AnimatedAppIcon> createState() => _AnimatedAppIconState();
}

class _AnimatedAppIconState extends State<AnimatedAppIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.effect == AppIconEffect.sweep
          ? const Duration(seconds: 2)
          : widget.duration,
      vsync: this,
    )..repeat(reverse: widget.effect != AppIconEffect.sweep);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Glow shadow color theo hiệu ứng
  BoxShadow? _buildGlow(double t) {
    if (widget.effect == AppIconEffect.glow) {
      return BoxShadow(
        color: widget.color.withOpacity(0.5 + 0.5 * t),
        blurRadius: 12 + 6 * t,
        spreadRadius: 1 + 1 * t,
      );
    }
    if (widget.effect == AppIconEffect.colorLoop) {
      Color color = Color.lerp(widget.color, widget.altColor ?? Colors.orange, t)!;
      return BoxShadow(
        color: color.withOpacity(0.6),
        blurRadius: 14 + 7 * t,
        spreadRadius: 1.4 + 1.1 * t,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final double t = _controller.value;

        switch (widget.effect) {
          case AppIconEffect.pulse:
            return Transform.scale(
              scale: 1 + 0.13 * (sin(2 * pi * t)), // nhịp đập
              child: Icon(widget.icon, color: widget.color, size: widget.size),
            );

          case AppIconEffect.glow:
          case AppIconEffect.colorLoop:
            return Container(
              decoration: BoxDecoration(boxShadow: [_buildGlow(t)!]),
              child: Icon(widget.icon, color: widget.color, size: widget.size),
            );

          case AppIconEffect.shake:
            return Transform.translate(
              offset: Offset(2 * sin(2 * pi * t), 0),
              child: Icon(widget.icon, color: widget.color, size: widget.size),
            );

          case AppIconEffect.flash:
            return Opacity(
              opacity: (0.5 + 0.5 * sin(2 * pi * t)),
              child: Icon(widget.icon, color: widget.color, size: widget.size),
            );

          case AppIconEffect.sweep:
          // Quét vòng quanh (chỉ hiệu ứng demo, muốn đẹp dùng CustomPaint/Lottie)
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: 2 * pi * t,
                  child: Icon(Icons.circle_outlined,
                      color: widget.altColor?.withOpacity(0.55) ?? Colors.cyan.withOpacity(0.45),
                      size: widget.size + 10),
                ),
                Icon(widget.icon, color: widget.color, size: widget.size),
              ],
            );

          case AppIconEffect.none:
          default:
            return Icon(widget.icon, color: widget.color, size: widget.size);
        }
      },
    );
  }
}
