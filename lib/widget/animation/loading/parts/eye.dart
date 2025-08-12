import 'dart:math' as math;
import 'package:flutter/material.dart';

class EyeWidget extends StatelessWidget {
  const EyeWidget({super.key, required this.mirror});
  final bool mirror;

  static const double size = 20.0; // mắt tròn

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Stack(
        children: [
          // Nền xanh nhạt + gradient
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFAEE6F2), Color(0xFF9BDAEB)],
              ),
            ),
          ),
          // Sọc trắng nghiêng
          CustomPaint(
            size: const Size(size, size),
            painter: _EyeStripesOnlyPainter(
              angleDeg: mirror ? -65 : 65,
              stripeColor: Colors.white,
            ),
          ),
          // Glow xanh ngoài
          IgnorePointer(
            child: Container(
              width: size, height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0xFF04B8D5), blurRadius: 4),
                  BoxShadow(color: Color(0x800BDAEB), blurRadius: 10, spreadRadius: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter chỉ vẽ sọc
class _EyeStripesOnlyPainter extends CustomPainter {
  _EyeStripesOnlyPainter({required this.angleDeg, required this.stripeColor});
  final double angleDeg;
  final Color stripeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rad = angleDeg * math.pi / 180.0;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rad);
    canvas.translate(-size.width / 2, -size.height / 2);

    final paint = Paint()..color = stripeColor;
    const stripeW = 1.0, gapW = 1.0;
    final step = stripeW + gapW;

    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawRect(
        Rect.fromLTWH(x, -size.height, stripeW, size.height * 3), paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EyeStripesOnlyPainter old) =>
      old.angleDeg != angleDeg || old.stripeColor != stripeColor;
}
