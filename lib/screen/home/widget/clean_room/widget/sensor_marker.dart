import 'package:flutter/material.dart';

class SensorMarker extends StatelessWidget {
  final String sensorName;
  final String areaName;
  final bool online;
  final bool triangleAtLeft; // true: tam giác lệch trái, false: lệch phải
  final bool labelOnTop; // true: label nằm trên, false: bên dưới

  const SensorMarker({
    super.key,
    required this.sensorName,
    required this.areaName,
    required this.online,
    this.triangleAtLeft = true,
    this.labelOnTop = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color boxColor = Colors.blue.shade700.withOpacity(0.95);

    // Widget: label box + tam giác lệch, hướng xuống
    Widget labelWithTriangle() => Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sensorName,
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                online ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: online ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              Text(
                areaName,
                style: const TextStyle(fontSize: 9, color: Colors.white),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -10,
          left: triangleAtLeft ? 12 : null,
          right: triangleAtLeft ? null : 12,
          child: CustomPaint(
            size: const Size(16, 12),
            painter: _TrianglePainter(color: boxColor, downward: true),
          ),
        ),
      ],
    );

    // Widget: label box + tam giác lệch, hướng lên
    Widget labelWithTriangleUp() => Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -10,
          left: triangleAtLeft ? 12 : null,
          right: triangleAtLeft ? null : 12,
          child: CustomPaint(
            size: const Size(16, 12),
            painter: _TrianglePainter(color: boxColor, downward: false),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sensorName,
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                online ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: online ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              Text(
                areaName,
                style: const TextStyle(fontSize: 9, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );

    // Widget: chấm tròn trạng thái ở giữa
    Widget statusCircle() => Align(
      alignment: triangleAtLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(left: triangleAtLeft ? 20 : 0, right: triangleAtLeft ? 0 : 20),
        width: 17,
        height: 17,
        decoration: BoxDecoration(
          color: online ? Colors.greenAccent : Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 1.2),
        ),
      ),
    );

    // Build layout chính
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: labelOnTop
          ? [
        labelWithTriangle(),
        const SizedBox(height: 15),
        statusCircle(),
      ]
          : [
        statusCircle(),
        const SizedBox(height: 15),
        labelWithTriangleUp(),
      ],
    );
  }
}

// Tam giác vẽ bằng CustomPainter, cho phép chọn hướng lên/xuống
class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool downward; // true: tam giác xuống, false: lên

  _TrianglePainter({required this.color, this.downward = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (downward) {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
