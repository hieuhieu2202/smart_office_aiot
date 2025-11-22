import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
    final chartSeries = _buildSeries(seriesList, categories, palette);
    final tooltip = _buildTooltip(chartSeries);

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
                child: _Header(
                  sensorName: sensorName,
                  sensorDesc: sensorDesc,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusPill(status: status),
                  if (lastTime.isNotEmpty) _TimePill(time: lastTime),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MetricWrap(metrics: metrics, isDark: isDark),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: _Sparkline(
              series: chartSeries,
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

  List<_ChartSeriesData> _buildSeries(
    List<dynamic> series,
    List<String> categories,
    List<Color> palette,
  ) {
    final items = <_ChartSeriesData>[];
    int colorIndex = 0;
    for (final raw in series) {
      final map = raw is Map<String, dynamic> ? raw : null;
      final data = (map?['data'] as List?)?.map((e) => e as num).toList() ?? [];
      if (map == null || data.isEmpty || categories.isEmpty) continue;

      final label = map['parameterDisplayName']?.toString() ?? map['name']?.toString() ?? '';
      final length = data.length < categories.length ? data.length : categories.length;
      final color = palette[colorIndex % palette.length];
      colorIndex++;

      final points = <_ChartPoint>[];
      for (int i = 0; i < length; i++) {
        final rawLabel = categories[i];
        final parsed = _parseTimestamp(rawLabel);
        points.add(
          _ChartPoint(
            rawLabel: rawLabel,
            displayLabel: _formatCategoryLabel(rawLabel),
            value: data[i],
            timestamp: parsed,
          ),
        );
      }

      items.add(
        _ChartSeriesData(
          name: label,
          color: color,
          points: points,
        ),
      );
    }
    return items;
  }

  TooltipBehavior _buildTooltip(List<_ChartSeriesData> chartSeries) {
    return TooltipBehavior(
      enable: true,
      color: Colors.blueGrey.shade900.withOpacity(0.95),
      header: '',
      canShowMarker: true,
      opacity: 0.98,
      animationDuration: 120,
      tooltipPosition: TooltipPosition.pointer,
      builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
        final chartPoint = point.data is _ChartPoint ? point.data as _ChartPoint : null;
        final headerLabel = chartPoint?.timestamp != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(chartPoint!.timestamp!)
            : (chartPoint?.displayLabel ?? chartPoint?.rawLabel ?? '');

        final rows = chartSeries
            .where((item) => pointIndex >= 0 && pointIndex < item.points.length)
            .map((item) {
          final valuePoint = item.points[pointIndex];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                item.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                valuePoint.formattedValue,
                style: TextStyle(color: item.color, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          );
        }).toList();

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade900.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 12, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    headerLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
              if (rows.isNotEmpty) const SizedBox(height: 6),
              ...rows,
            ],
          ),
        );
      },
    );
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
  final List<_ChartSeriesData> series;
  final List<Color> palette;
  final TooltipBehavior tooltipBehavior;
  final bool isDark;

  const _Sparkline({
    required this.series,
    required this.palette,
    required this.tooltipBehavior,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double targetHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 120.0;
        final double clampedHeight = targetHeight.clamp(100.0, 160.0);
        final int pointCount = series.isNotEmpty ? series.first.points.length : 0;
        final double labelInterval = pointCount <= 6 ? 1 : (pointCount / 6).ceilToDouble();

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
              labelPlacement: LabelPlacement.onTicks,
              labelIntersectAction: AxisLabelIntersectAction.hide,
              interval: labelInterval,
              labelStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                fontSize: 9,
              ),
            ),
            primaryYAxis: NumericAxis(
              isVisible: false,
              majorGridLines: const MajorGridLines(width: 0),
            ),
            legend: const Legend(isVisible: false),
            series: series.map((item) {
              return SplineSeries<_ChartPoint, String>(
                dataSource: item.points,
                width: 2.4,
                opacity: 0.95,
                markerSettings: const MarkerSettings(isVisible: true, height: 6, width: 6),
                xValueMapper: (point, _) => point.displayLabel,
                yValueMapper: (point, _) => point.value,
                name: item.name,
                color: item.color,
              );
            }).toList(),
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

String _formatCategoryLabel(String raw) {
  final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
  final parsed = DateTime.tryParse(normalized);
  if (parsed != null) {
    return DateFormat('MM-dd HH:mm').format(parsed);
  }
  return raw.length > 16 ? raw.substring(0, 16) : raw;
}

DateTime? _parseTimestamp(String raw) {
  final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}

class _ChartSeriesData {
  final String name;
  final Color color;
  final List<_ChartPoint> points;

  const _ChartSeriesData({required this.name, required this.color, required this.points});
}

class _ChartPoint {
  final String rawLabel;
  final String displayLabel;
  final num value;
  final DateTime? timestamp;

  const _ChartPoint({
    required this.rawLabel,
    required this.displayLabel,
    required this.value,
    required this.timestamp,
  });

  String get formattedValue {
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
