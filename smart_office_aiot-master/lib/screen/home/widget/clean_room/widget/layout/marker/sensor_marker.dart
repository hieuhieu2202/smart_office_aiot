import 'package:flutter/material.dart';

import 'sensor_marker_label.dart';

class SensorMarker extends StatelessWidget {
  final String sensorName;
  final String areaName;
  final bool online;
  final bool triangleAtLeft;
  final bool labelOnTop;
  final VoidCallback? onTap;

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
    const arrowOffset = 20.0;
    const markerBoxSize = 45.0;

    Widget circle() => Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: online
                ? Colors.greenAccent.withOpacity(0.6)
                : Colors.grey.withOpacity(0.5),
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
        color: Colors.transparent,
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
              child: SensorMarkerLabel(
                sensorName: sensorName,
                areaName: areaName,
                online: online,
                triangleAtLeft: triangleAtLeft,
                downward: labelOnTop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

