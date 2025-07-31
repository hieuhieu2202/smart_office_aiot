import 'package:flutter/material.dart';

class SensorMarker extends StatelessWidget {
  final String sensorName;
  final String areaName;
  final bool online;
  final bool labelOnLeft;
  const SensorMarker({
    super.key,
    required this.sensorName,
    required this.areaName,
    required this.online,
    this.labelOnLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF052C54);
    final lineColor = Colors.lightBlueAccent.withOpacity(0.3);

    final circle = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: online ? Colors.greenAccent : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );

    final arrow = Transform.rotate(
      angle: labelOnLeft ? 3.1416 : 0,
      child: Icon(Icons.arrow_right_alt,
          size: 12, color: online ? Colors.greenAccent : Colors.grey),
    );

    final label = CustomPaint(
      painter: _StripedPainter(lineColor),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$sensorName - ${online ? 'ON' : 'OFF'}',
              style: TextStyle(
                color: online ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              areaName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );

    final children = labelOnLeft
        ? [label, const SizedBox(width: 4), arrow, const SizedBox(width: 4), circle]
        : [circle, const SizedBox(width: 4), arrow, const SizedBox(width: 4), label];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}

class _StripedPainter extends CustomPainter {
  final Color lineColor;
  _StripedPainter(this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (double y = 0; y <= size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
