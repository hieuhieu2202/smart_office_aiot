import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../../domain/entities/sensor_data.dart';

class SensorOverviewCard extends StatefulWidget {
  const SensorOverviewCard({
    super.key,
    required this.data,
    required this.status,
    required this.size,
    required this.speechType,
  });

  final SensorDataResponse data;
  final String status;
  final double size;
  final String speechType;

  @override
  State<SensorOverviewCard> createState() => _SensorOverviewCardState();
}

class _SensorOverviewCardState extends State<SensorOverviewCard> {
  bool _isHovered = false;

  SensorDataResponse get data => widget.data;
  String get status => widget.status;
  double get size => widget.size;
  String get speechType => widget.speechType;

  Color _statusColor() {
    switch (status.toUpperCase()) {
      case 'WARNING':
        return Colors.orangeAccent;
      case 'OFFLINE':
        return Colors.grey;
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final DateTime? last = data.data
        .map((e) => e.timestamp)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (prev, element) =>
              prev == null || element.isAfter(prev) ? element : prev,
        );
    final bool bubbleBelow = speechType.toLowerCase().startsWith('top');

    final dot = Container(
      margin: const EdgeInsets.only(bottom: 6),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.22),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.65),
            blurRadius: 18,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.45,
          height: size * 0.45,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    final bubble = Container(
      margin: EdgeInsets.only(
        top: bubbleBelow ? 8 : 0,
        bottom: bubbleBelow ? 0 : 8,
      ),
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.sensorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      data.sensorDesc,
                      style: const TextStyle(color: Colors.white60),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (last != null)
                    Text(
                      last.toString(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: data.data.take(4).mapIndexed((index, p) {
              return _paramTile(p);
            }).toList(),
          ),
        ],
      ),
    );

    final children = bubbleBelow ? <Widget>[dot] : <Widget>[];
    children.add(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        child: _isHovered
            ? bubble
            : const SizedBox.shrink(
                key: ValueKey('hidden-bubble'),
              ),
      ),
    );
    if (!bubbleBelow) {
      children.add(dot);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: speechType.toLowerCase().contains('right')
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _paramTile(SensorDataPoint p) {
    final Color valueColor;
    switch (p.result.toUpperCase()) {
      case 'WARNING':
        valueColor = Colors.orangeAccent;
        break;
      case 'OFFLINE':
        valueColor = Colors.grey;
        break;
      default:
        valueColor = Colors.greenAccent;
    }

    final Map<String, Color> paramColors = {
      '0.3um': const Color(0xFF058DC7),
      '0.5um': const Color(0xFF50B432),
      '1.0um': const Color(0xFFED561B),
      '5.0um': const Color(0xFFDDDF00),
    };

    final Color labelColor = paramColors[p.paramName] ?? Colors.cyanAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: labelColor.withOpacity(0.4)),
      ),
      child: FittedBox(
        alignment: Alignment.topLeft,
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.paramDisplayName,
              style: TextStyle(color: labelColor, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              p.value.toStringAsFixed(p.precision),
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
