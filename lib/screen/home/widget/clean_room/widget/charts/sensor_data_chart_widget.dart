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
        return DashboardCard(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Text(
              'Không có lịch sử cảm biến',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: isDark ? Colors.white70 : Colors.blueGrey.shade700),
            ),
          ),
        );
      }

      return DashboardCard(
        padding: const EdgeInsets.all(12),
        child: ListView.separated(
          itemCount: histories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
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
  static const List<_ParameterSpec> _preferredParams = [
    _ParameterSpec(key: '0.3um', fallbackLabel: 'PM0.3 (µm/m³)'),
    _ParameterSpec(key: '0.5um', fallbackLabel: 'PM0.5 (µm/m³)'),
    _ParameterSpec(key: '1.0um', fallbackLabel: 'PM1.0 (µm/m³)'),
    _ParameterSpec(key: '5.0um', fallbackLabel: 'PM5.0 (µm/m³)'),
    _ParameterSpec(key: 'traffic', fallbackLabel: 'Traffic Flow (m/min)'),
  ];
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0a1327), const Color(0xFF0f1f3d), const Color(0xFF12345a)]
              : [const Color(0xFFf0f6ff), const Color(0xFFe3edff), const Color(0xFFd5e5ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.16 : 0.24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 12)),
          BoxShadow(color: Colors.blueAccent.withOpacity(0.16), blurRadius: 24, spreadRadius: -8),
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
          const SizedBox(height: 10),
          _MetricWrap(metrics: metrics, isDark: isDark),
          const SizedBox(height: 12),
          _SparklineCard(
            isDark: isDark,
            child: _Sparkline(
              series: chartSeries,
              palette: palette,
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

    for (final spec in _preferredParams) {
      final map = _findSeriesByKey(series, spec.key);
      final data = (map?['data'] as List?) ?? [];
      if (map == null || data.isEmpty) continue;

      final label = map['parameterDisplayName']?.toString() ??
          map['name']?.toString() ??
          spec.fallbackLabel;
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

    for (final spec in _preferredParams) {
      final map = _findSeriesByKey(series, spec.key);
      final data = (map?['data'] as List?)?.map((e) => e as num).toList() ?? [];
      if (map == null || data.isEmpty || categories.isEmpty) continue;

      final label = map['parameterDisplayName']?.toString() ??
          map['name']?.toString() ??
          spec.fallbackLabel;
      final length = data.length < categories.length ? data.length : categories.length;
      final color = palette[colorIndex % palette.length];
      colorIndex++;

      final points = <_ChartPoint>[];
      for (int i = 0; i < length; i++) {
        final category = _resolveCategory(categories[i]);
        points.add(
          _ChartPoint(
            rawLabel: category.raw,
            displayLabel: category.display,
            value: data[i],
            timestamp: category.timestamp,
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

  Map<String, dynamic>? _findSeriesByKey(List<dynamic> series, String key) {
    final normalizedKey = key.toLowerCase();
    final match = series.whereType<Map<String, dynamic>>().firstWhere(
          (map) {
            final paramName = map['parameterName']?.toString().toLowerCase();
            final name = map['name']?.toString().toLowerCase();
            return paramName == normalizedKey || name == normalizedKey;
          },
          orElse: () => <String, dynamic>{},
        );
    return match.isEmpty ? null : match;
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
      spacing: 10,
      runSpacing: 8,
      children: metrics.take(6).map((metric) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                metric.color.withOpacity(isDark ? 0.12 : 0.08),
                metric.color.withOpacity(isDark ? 0.2 : 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: metric.color.withOpacity(isDark ? 0.45 : 0.35)),
            boxShadow: [
              BoxShadow(color: metric.color.withOpacity(0.25), blurRadius: 14, spreadRadius: -4),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: metric.color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: metric.color.withOpacity(0.55), blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isDark ? Colors.white : const Color(0xFF0b2d55),
                      ),
                ),
              ),
              const SizedBox(width: 10),
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

class _SparklineCard extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _SparklineCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0b1b35), const Color(0xFF0e2a4d)]
              : [const Color(0xFFe7f0ff), const Color(0xFFdbe6ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.18)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 16, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<_ChartSeriesData> series;
  final List<Color> palette;
  final bool isDark;

  const _Sparkline({
    required this.series,
    required this.palette,
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
        final double tooltipMaxWidth =
            (constraints.maxWidth.isFinite ? constraints.maxWidth - 16 : 280).clamp(160.0, 320.0).toDouble();

        final tooltipBehavior = _buildTooltip(series, tooltipMaxWidth);

        return Container(
          height: clampedHeight,
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.22) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.18)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
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
              ),
            ],
          ),
        );
      },
    );
  }

  TooltipBehavior _buildTooltip(List<_ChartSeriesData> chartSeries, double maxWidth) {
    return TooltipBehavior(
      enable: true,
      color: Colors.blueGrey.shade900.withOpacity(0.95),
      header: '',
      canShowMarker: true,
      opacity: 0.98,
      animationDuration: 120,
      tooltipPosition: TooltipPosition.pointer,
      activationMode: ActivationMode.singleTap,
      builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
        _ChartPoint? chartPoint;
        if (data is _ChartPoint) {
          chartPoint = data;
        } else if (seriesIndex >= 0 && seriesIndex < chartSeries.length) {
          final points = chartSeries[seriesIndex].points;
          if (pointIndex >= 0 && pointIndex < points.length) {
            chartPoint = points[pointIndex];
          }
        }

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
              Flexible(
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                valuePoint.formattedValue,
                style: TextStyle(color: item.color, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          );
        }).toList();

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            color: Colors.transparent,
            elevation: 22,
            shadowColor: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900.withOpacity(0.98),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                      Flexible(
                        child: Text(
                          headerLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (rows.isNotEmpty) const SizedBox(height: 6),
                  ...rows,
                ],
              ),
            ),
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

_CategoryLabel _resolveCategory(dynamic raw) {
  if (raw == null) {
    return const _CategoryLabel(raw: '', display: '', timestamp: null);
  }

  if (raw is Map) {
    // Prioritize well-known time/label keys.
    const keys = ['timestamp', 'time', 'label', 'value', 'name'];
    for (final key in keys) {
      if (raw.containsKey(key) && raw[key] != null) {
        final candidate = raw[key].toString();
        final ts = _parseTimestamp(candidate);
        return _CategoryLabel(
          raw: candidate,
          display: _formatCategoryLabel(candidate),
          timestamp: ts,
        );
      }
    }

    // Fall back to a concatenated description when no key matches.
    final fallback = raw.values.map((v) => v?.toString() ?? '').where((v) => v.isNotEmpty).join(' ');
    return _CategoryLabel(
      raw: fallback,
      display: _formatCategoryLabel(fallback),
      timestamp: _parseTimestamp(fallback),
    );
  }

  final label = raw.toString();
  return _CategoryLabel(
    raw: label,
    display: _formatCategoryLabel(label),
    timestamp: _parseTimestamp(label),
  );
}

class _ChartSeriesData {
  final String name;
  final Color color;
  final List<_ChartPoint> points;

  const _ChartSeriesData({required this.name, required this.color, required this.points});
}

class _CategoryLabel {
  final String raw;
  final String display;
  final DateTime? timestamp;

  const _CategoryLabel({required this.raw, required this.display, required this.timestamp});
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

class _ParameterSpec {
  final String key;
  final String fallbackLabel;

  const _ParameterSpec({required this.key, required this.fallbackLabel});
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
