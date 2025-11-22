import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';

import '../common/dashboard_card.dart';
import 'chart_style.dart';

class SensorDataChartWidget extends StatelessWidget {
  const SensorDataChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final histories = controller.sensorHistories;
      if (histories.isEmpty) {
        return const DashboardCard(
          padding: EdgeInsets.all(10),
          child: Center(child: Text('Không có lịch sử cảm biến')),
        );
      }

      return DashboardCard(
        padding: const EdgeInsets.all(10),
        child: ListView.separated(
          itemCount: histories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final entry = histories[index];
            final categories =
                (entry['categories'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
            final seriesList = (entry['series'] as List?) ?? <dynamic>[];
            final sensorName = entry['sensorName']?.toString() ?? 'Sensor';
            final sensorDesc = entry['sensorDesc']?.toString() ?? '';
            final lastTime = entry['timestamp']?.toString() ?? '';
            final status = (entry['status'] ?? 'ONLINE').toString().toUpperCase();

            return _SensorCard(
              sensorName: sensorName,
              sensorDesc: sensorDesc,
              lastTime: lastTime,
              status: status,
              categories: categories,
              seriesList: seriesList,
              isDark: isDark,
            );
          },
        ),
      );
    });
  }
}

class _SensorCard extends StatelessWidget {
  final String sensorName;
  final String sensorDesc;
  final String lastTime;
  final String status;
  final List<String> categories;
  final List<dynamic> seriesList;
  final bool isDark;

  const _SensorCard({
    required this.sensorName,
    required this.sensorDesc,
    required this.lastTime,
    required this.status,
    required this.categories,
    required this.seriesList,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CleanRoomChartStyle.palette(isDark);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0d2a4b), const Color(0xFF0f3a6d)]
              : [const Color(0xFFe2f1ff), const Color(0xFFd4e7ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.2 : 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 14, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.blueAccent.withOpacity(0.18), blurRadius: 16, spreadRadius: -8),
        ],
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
                  children: _buildMetrics(palette),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(sensorName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0a2d50),
                          )),
                  if (sensorDesc.isNotEmpty)
                    Text(sensorDesc,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: isDark ? Colors.white70 : Colors.blueGrey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 12, color: _statusColor(status)),
                      const SizedBox(width: 6),
                      Text(status,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _statusColor(status),
                              )),
                    ],
                  ),
                  if (lastTime.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(lastTime,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: isDark ? Colors.white70 : Colors.blueGrey.shade700)),
                    ),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              borderWidth: 0,
              palette: palette,
              primaryXAxis: CategoryAxis(
                isVisible: false,
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                isVisible: false,
                majorGridLines: const MajorGridLines(width: 0),
              ),
              legend: const Legend(isVisible: false),
              series: seriesList
                  .where((serie) => serie is Map && (serie['data'] as List?)?.isNotEmpty == true)
                  .map<SplineSeries<dynamic, String>>((serie) {
                final data = (serie['data'] as List).map((e) => e as num).toList();
                final name = serie['parameterDisplayName'] ?? serie['name'] ?? '';
                return SplineSeries<dynamic, String>(
                  dataSource: data,
                  width: 2.2,
                  markerSettings: const MarkerSettings(isVisible: false),
                  xValueMapper: (dynamic value, int index) =>
                      index < categories.length ? categories[index] : index.toString(),
                  yValueMapper: (dynamic value, int _) => value,
                  name: name.toString(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetrics(List<Color> palette) {
    final List<Widget> metrics = [];
    for (int i = 0; i < seriesList.length && i < 4; i++) {
      final serie = seriesList[i] as Map<String, dynamic>?;
      if (serie == null) continue;
      final label = serie['parameterDisplayName']?.toString() ?? serie['name']?.toString() ?? '';
      final data = (serie['data'] as List?) ?? [];
      final value = data.isNotEmpty ? data.last : null;
      metrics.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '$label: ${value ?? 0}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: palette[i % palette.length],
            ),
          ),
        ),
      );
    }
    return metrics;
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OFFLINE':
        return Colors.grey.shade400;
      case 'WARNING':
        return Colors.orangeAccent;
      default:
        return Colors.lightGreenAccent;
    }
  }
}
