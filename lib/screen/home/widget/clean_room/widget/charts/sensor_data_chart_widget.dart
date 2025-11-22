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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0d213b), const Color(0xFF0f305d)]
              : [const Color(0xFFe6f0ff), const Color(0xFFd6e7ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.14 : 0.32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.blueAccent.withOpacity(0.18), blurRadius: 18, spreadRadius: -6),
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
                  children: [
                    Text(
                      sensorName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0a2d50),
                          ),
                    ),
                    if (sensorDesc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          sensorDesc,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: isDark ? Colors.white70 : Colors.blueGrey.shade600),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusPill(status: status),
                  if (lastTime.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.16 : 0.22)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 14, color: isDark ? Colors.white70 : Colors.blueGrey.shade700),
                            const SizedBox(width: 6),
                            Text(
                              lastTime,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: isDark ? Colors.white70 : Colors.blueGrey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          _MetricWrap(palette: palette, seriesList: seriesList, isDark: isDark),
          const SizedBox(height: 12),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(isDark ? 0.08 : 0.18)),
            ),
            padding: const EdgeInsets.only(left: 6, right: 6, top: 4, bottom: 2),
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
                  width: 2.4,
                  opacity: 0.9,
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

}

class _MetricWrap extends StatelessWidget {
  final List<Color> palette;
  final List<dynamic> seriesList;
  final bool isDark;

  const _MetricWrap({required this.palette, required this.seriesList, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (int i = 0; i < seriesList.length && i < 5; i++) {
      final serie = seriesList[i] as Map<String, dynamic>?;
      if (serie == null) continue;
      final label = serie['parameterDisplayName']?.toString() ?? serie['name']?.toString() ?? '';
      final data = (serie['data'] as List?) ?? [];
      if (data.isEmpty) continue;
      final value = data.last as num;
      final color = palette[i % palette.length];
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.16) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 10, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0a2d50),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatValue(value),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  String _formatValue(num value) {
    if (value is int) return value.toString();
    final doubleValue = value.toDouble();
    return doubleValue % 1 == 0 ? doubleValue.toStringAsFixed(0) : doubleValue.toStringAsFixed(2);
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.22) : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OFFLINE':
        return Colors.grey.shade400;
      case 'WARNING':
        return Colors.orangeAccent;
      default:
        return Colors.lightGreenAccent.shade400;
    }
  }
}
