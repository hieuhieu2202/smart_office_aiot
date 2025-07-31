import 'package:flutter/material.dart';

import 'triangle_painter.dart';

class SensorMarkerLabel extends StatelessWidget {
  final String sensorName;
  final String areaName;
  final bool online;
  final bool triangleAtLeft;
  final bool downward;

  const SensorMarkerLabel({
    super.key,
    required this.sensorName,
    required this.areaName,
    required this.online,
    this.triangleAtLeft = true,
    this.downward = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color boxColor = Colors.blue.shade700.withOpacity(0.7);

    final label = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sensorName,
            style: const TextStyle(
                fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
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
    );

    final arrow = CustomPaint(
      size: const Size(16, 12),
      painter: TrianglePainter(color: boxColor, downward: downward),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (!downward)
          Positioned(
            top: -10,
            left: triangleAtLeft ? 12 : null,
            right: triangleAtLeft ? null : 12,
            child: arrow,
          ),
        label,
        if (downward)
          Positioned(
            bottom: -10,
            left: triangleAtLeft ? 12 : null,
            right: triangleAtLeft ? null : 12,
            child: arrow,
          ),
      ],
    );
  }
}

