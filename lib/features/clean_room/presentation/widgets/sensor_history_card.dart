import 'package:flutter/material.dart';

import '../../domain/entities/sensor_data.dart';

class SensorHistoryCard extends StatelessWidget {
  const SensorHistoryCard({super.key, required this.data, required this.status});

  final SensorDataResponse data;
  final String status;

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
    final DateTime? last = data.data.map((e) => e.timestamp).whereType<DateTime>().fold<DateTime?>(
          null,
          (prev, element) => prev == null || element.isAfter(prev) ? element : prev,
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
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
                  children: data.data
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${p.paramDisplayName}: ${p.value.toStringAsFixed(p.precision)}',
                            style: TextStyle(color: Colors.white.withOpacity(0.9)),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withOpacity(0.14),
                ),
                alignment: Alignment.center,
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  if (last != null)
                    Text(
                      last.toString(),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
