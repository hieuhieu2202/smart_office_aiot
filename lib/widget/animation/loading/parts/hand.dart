import 'dart:math' as math;
import 'package:flutter/material.dart';

class HandWidget extends StatelessWidget {
  const HandWidget({
    super.key,
    required this.width, required this.height,
    required this.rotateZDeg, required this.rotateYDeg,
    required this.leftToRight,
  });

  final double width, height;
  final double rotateZDeg, rotateYDeg;
  final bool leftToRight;

  @override
  Widget build(BuildContext context) {
    final rotY = rotateYDeg * math.pi / 180;
    final rotZ = rotateZDeg * math.pi / 180;

    final grad = leftToRight
        ? const LinearGradient(
      begin: Alignment.centerLeft, end: Alignment.centerRight,
      colors: [Colors.white, Color(0xFFBFC0C2)], stops: [0.15, 1],
    )
        : const LinearGradient(
      begin: Alignment.centerRight, end: Alignment.centerLeft,
      colors: [Colors.white, Color(0xFFBFC0C2)], stops: [0.15, 1],
    );

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)..rotateY(rotY)..rotateZ(rotZ),
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: grad,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(5, 0)),
          ],
        ),
        foregroundDecoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Colors.white24, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
