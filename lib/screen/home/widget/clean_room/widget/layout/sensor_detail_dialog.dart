import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SensorDetailDialog extends StatelessWidget {
  final Map<String, dynamic>? dataEntry;
  final String sensorName;
  final bool online;
  const SensorDetailDialog({
    super.key,
    required this.sensorName,
    required this.dataEntry,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    final series = (dataEntry?['series'] as List?) ?? [];
    final categories =
        (dataEntry?['categories'] is List && (dataEntry?['categories'] as List).isNotEmpty)
            ? ((dataEntry!['categories'][0]['categories'] as List?) ?? [])
            : [];
    final params = (dataEntry?['data'] as List?) ?? [];

    return AlertDialog(
      title: Text('Sensor $sensorName - ${online ? 'Online' : 'Offline'}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (online && series.isNotEmpty && categories.isNotEmpty)
              SizedBox(
                height: 150,
                width: 300,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(isVisible: false),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  legend: const Legend(isVisible: true),
                  series: series
                      .map((s) => LineSeries<dynamic, String>(
                            name: s['name'] ?? '',
                            dataSource: s['data'] as List,
                            markerSettings: const MarkerSettings(isVisible: true),
                            xValueMapper: (dynamic data, int index) =>
                                index < categories.length ? categories[index].toString() : '',
                            yValueMapper: (dynamic data, int index) => data,
                          ))
                      .toList(),
                ),
              ),
            if (params.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...params.map((p) => Text(
                    '${p['paramDisplayName']}: ${p['value']} ${p['paramUnit'] ?? ''}',
                  )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
