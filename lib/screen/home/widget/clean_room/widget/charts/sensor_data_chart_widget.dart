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
    final metrics = _buildMetrics(seriesList, palette);
    final tooltip = TooltipBehavior(
      enable: true,
      shared: true,
      color: Colors.blueGrey.shade900.withOpacity(0.95),
      header: '',
      format: 'Time: point.x',
      textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      canShowMarker: true,
      opacity: 0.98,
      tooltipPosition: TooltipPosition.pointer,
      animationDuration: 150,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0b1d35), const Color(0xFF0d3055), const Color(0xFF0e3b6a)]
              : [const Color(0xFFe9f3ff), const Color(0xFFd7e8ff), const Color(0xFFc8defc)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.18 : 0.28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 10)),
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
                child: _Header(sensorName: sensorName, sensorDesc: sensorDesc, isDark: isDark),
              ),
              const SizedBox(width: 10),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  _SensorTag(sensorName: sensorName, sensorDesc: sensorDesc, isDark: isDark),
                  _StatusPill(status: status),
                  if (lastTime.isNotEmpty) _TimePill(time: lastTime),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetricWrap(metrics: metrics, isDark: isDark),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 110, maxHeight: 150),
            child: _Sparkline(
              categories: categories,
              seriesList: seriesList,
              palette: palette,
              tooltipBehavior: tooltip,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  List<_MetricItem> _buildMetrics(List<dynamic> series, List<Color> palette) {
    final items = <_MetricItem>[];
    int colorIndex = 0;
    for (final raw in series) {
      final map = raw is Map<String, dynamic> ? raw : null;
      final data = (map?['data'] as List?) ?? [];
      if (map == null || data.isEmpty) continue;
      final label = map['parameterDisplayName']?.toString() ?? map['name']?.toString() ?? '';
      final lastValue = data.last as num;
      final color = palette[colorIndex % palette.length];
      colorIndex++;
      items.add(_MetricItem(label: label, value: lastValue, color: color));
    }
    return items;
  }
}

class _Header extends StatelessWidget {
  final String sensorName;
  final String sensorDesc;
  final bool isDark;

  const _Header({required this.sensorName, required this.sensorDesc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sensorName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF0b2d55),
                letterSpacing: 0.15,
              ),
        ),
        if (sensorDesc.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              sensorDesc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: isDark ? Colors.white60 : Colors.blueGrey.shade600, fontSize: 11.5),
            ),
          ),
      ],
    );
  }
}

class _MetricWrap extends StatelessWidget {
  final List<_MetricItem> metrics;
  final bool isDark;

  const _MetricWrap({required this.metrics, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return Text(
        'No sensor data',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: isDark ? Colors.white70 : Colors.blueGrey.shade700),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: metrics.take(6).map((metric) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: metric.color.withOpacity(isDark ? 0.45 : 0.35)),
            boxShadow: [
              BoxShadow(color: metric.color.withOpacity(0.2), blurRadius: 10, spreadRadius: -2),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: metric.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF0b2d55),
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                metric.formattedValue,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: metric.color,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
class _Sparkline extends StatelessWidget {
  final List<String> categories;
  final List<dynamic> seriesList;
  final List<Color> palette;
  final TooltipBehavior tooltipBehavior;
  final bool isDark;

  const _Sparkline({
    required this.categories,
    required this.seriesList,
    required this.palette,
    required this.tooltipBehavior,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final series = seriesList
        .where((serie) => serie is Map && (serie['data'] as List?)?.isNotEmpty == true)
        .map<SplineSeries<dynamic, String>>((serie) {
      final data = (serie['data'] as List).map((e) => e as num).toList();
      final name = serie['parameterDisplayName'] ?? serie['name'] ?? '';
      return SplineSeries<dynamic, String>(
        dataSource: data,
        width: 2.6,
        opacity: 0.95,
        markerSettings: const MarkerSettings(isVisible: true, height: 6, width: 6),
        xValueMapper: (dynamic value, int index) => index < categories.length ? categories[index] : index.toString(),
        yValueMapper: (dynamic value, int _) => value,
        name: name.toString(),
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double targetHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 120.0;
        final double clampedHeight = targetHeight.clamp(100.0, 160.0);

        return Container(
          height: clampedHeight,
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.25) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.18)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
          child: SfCartesianChart(
            margin: EdgeInsets.zero,
            plotAreaBorderWidth: 0,
            borderWidth: 0,
            palette: palette,
            tooltipBehavior: tooltipBehavior,
            primaryXAxis: CategoryAxis(
              isVisible: true,
              majorGridLines: const MajorGridLines(width: 0),
              labelStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                fontSize: 10,
              ),
            ),
            primaryYAxis: NumericAxis(
              isVisible: false,
              majorGridLines: const MajorGridLines(width: 0),
            ),
            legend: const Legend(isVisible: false),
            series: series,
          ),
        );
      },
    );
  }
}

class _MetricItem {
  final String label;
  final num value;
  final Color color;

  const _MetricItem({required this.label, required this.value, required this.color});

  String get formattedValue {
    if (value is int) return value.toString();
    final doubleValue = value.toDouble();
    return doubleValue % 1 == 0 ? doubleValue.toStringAsFixed(0) : doubleValue.toStringAsFixed(2);
  }
}

class _SensorTag extends StatelessWidget {
  final String sensorName;
  final String sensorDesc;
  final bool isDark;

  const _SensorTag({required this.sensorName, required this.sensorDesc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF123a64).withOpacity(0.9), const Color(0xFF0f2744).withOpacity(0.9)]
              : [const Color(0xFFd9e9ff), const Color(0xFFc5dbfb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.18 : 0.26)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.blueAccent.withOpacity(0.12), blurRadius: 14, spreadRadius: -4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_tethering, size: 15, color: isDark ? Colors.white : const Color(0xFF0a2d50)),
          const SizedBox(width: 8),
          Text(
            sensorName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0a2d50),
                ),
          ),
          if (sensorDesc.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              sensorDesc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: isDark ? Colors.white70 : Colors.blueGrey.shade700, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
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
        color: isDark ? color.withOpacity(0.28) : color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 11, color: color),
          const SizedBox(width: 7),
          Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
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

class _TimePill extends StatelessWidget {
  final String time;

  const _TimePill({required this.time});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.14 : 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white70 : Colors.blueGrey.shade700),
          const SizedBox(width: 6),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}
