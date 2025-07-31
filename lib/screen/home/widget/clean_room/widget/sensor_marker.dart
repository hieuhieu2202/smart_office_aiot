import 'package:flutter/material.dart';

class SensorMarker extends StatelessWidget {
  final String sensorName;
  final String areaName;
  final bool online;
  final bool triangleAtLeft;
  final bool labelOnTop;
  final VoidCallback? onTap; // callback mở dialog

  const SensorMarker({
    super.key,
    required this.sensorName,
    required this.areaName,
    required this.online,
    this.triangleAtLeft = true,
    this.labelOnTop = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color boxColor = Colors.blue.shade700.withOpacity(0.7);
    const arrowOffset = 20.0; // khoảng cách từ circle tới label
    const markerBoxSize = 45.0; // vùng bấm marker (vuông)

    Widget labelDown() => Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.13),
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
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

    Widget labelUp() => Stack(
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.13),
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
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

    Widget circle() => Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: online ? Colors.greenAccent.withOpacity(0.6) : Colors.grey.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.2),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Container(
        width: markerBoxSize,
        height: markerBoxSize,
        color: Colors.transparent, // vùng click lớn nhưng không thấy gì
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            circle(),
            Positioned(
              left: triangleAtLeft ? -arrowOffset : null,
              right: triangleAtLeft ? null : -arrowOffset,
              bottom: labelOnTop ? arrowOffset : null,
              top: labelOnTop ? null : arrowOffset,
              child: labelOnTop ? labelDown() : labelUp(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool downward;

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
