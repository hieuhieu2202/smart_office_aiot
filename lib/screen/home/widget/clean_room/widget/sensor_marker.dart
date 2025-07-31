import 'package:flutter/material.dart';

class SensorMarker extends StatelessWidget {
  final String sensorName;
  final String areaName;
  final bool online;
  const SensorMarker({
    super.key,
    required this.sensorName,
    required this.areaName,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF052C54);
    final lineColor = Colors.lightBlueAccent.withOpacity(0.3);

    return CustomPaint(
      painter: _StripedPainter(lineColor),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.8),
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
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: online ? Colors.greenAccent : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_right_alt,
                    size: 12, color: online ? Colors.greenAccent : Colors.grey),
              ],
            ),
          ],
        ),
      ),
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
