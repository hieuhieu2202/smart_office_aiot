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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: ListView.separated(
          clipBehavior: Clip.none,
          itemCount: histories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final entry = histories[index];
            final categories = (entry['categories'] as List?) ?? <dynamic>[];
            final seriesList = (entry['series'] as List?) ?? <dynamic>[];
            final sensorName = entry['sensorName']?.toString() ?? '';
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
  final List<dynamic> categories;
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
              ? [const Color(0xFF0b1424), const Color(0xFF0f2744), const Color(0xFF143a66)]
              : [const Color(0xFFeef3ff), const Color(0xFFe2ecff), const Color(0xFFd6e3ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.2 : 0.26)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 12)),
          BoxShadow(color: Colors.blueAccent.withOpacity(0.16), blurRadius: 24, spreadRadius: -8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Header(
                  sensorName: sensorName.isNotEmpty ? sensorName : 'Sensor',
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

      final label = _resolveLabel(map, spec.fallbackLabel);
      final lastValue = data.last as num;
      final color = palette[colorIndex % palette.length];
      colorIndex++;

      items.add(_MetricItem(label: label, value: lastValue, color: color));
    }
    return items;
  }

  List<_ChartSeriesData> _buildSeries(
    List<dynamic> series,
    List<dynamic> categories,
    List<Color> palette,
  ) {
    final items = <_ChartSeriesData>[];
    int colorIndex = 0;

    for (final spec in _preferredParams) {
      final map = _findSeriesByKey(series, spec.key);
      final data = (map?['data'] as List?)?.map((e) => e as num).toList() ?? [];
      if (map == null || data.isEmpty || categories.isEmpty) continue;

      final label = _resolveLabel(map, spec.fallbackLabel);
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

  String _resolveLabel(Map<String, dynamic> map, String fallback) {
    if (map['parameterDisplayName'] != null) return map['parameterDisplayName'].toString();
    if (map['parameterName'] != null) return map['parameterName'].toString();
    if (map['name'] != null) return map['name'].toString();
    return fallback;
  }

  _CategoryLabel _resolveCategory(dynamic rawValue) {
    if (rawValue is Map) {
      final raw = rawValue['timestamp']?.toString() ?? rawValue['label']?.toString() ?? rawValue['name']?.toString();
      if (raw != null) {
        return _resolveCategory(raw);
      }
    }

    final raw = rawValue?.toString() ?? '';
    DateTime? timestamp;
    String display = raw;

    timestamp = DateTime.tryParse(raw);
    if (timestamp != null) {
      display = DateFormat('MM-dd HH:mm').format(timestamp.toLocal());
    }

    return _CategoryLabel(raw: raw, display: display, timestamp: timestamp);
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
                letterSpacing: 0.1,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                metric.color.withOpacity(isDark ? 0.12 : 0.08),
                metric.color.withOpacity(isDark ? 0.22 : 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: metric.color.withOpacity(isDark ? 0.42 : 0.32)),
            boxShadow: [
              BoxShadow(color: metric.color.withOpacity(0.3), blurRadius: 14, spreadRadius: -6),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
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
              const SizedBox(width: 8),
              Text(
                metric.formattedValue,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
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
      height: 170,
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
        final double clampedHeight = targetHeight.clamp(110.0, 180.0);
        final int pointCount = series.isNotEmpty ? series.first.points.length : 0;
        final double labelInterval = pointCount <= 6 ? 1 : (pointCount / 6).ceilToDouble();
        final double tooltipMaxWidth =
            (constraints.maxWidth.isFinite ? constraints.maxWidth - 10 : 280).clamp(180.0, 360.0).toDouble();

        final tooltipBehavior = _buildTooltip(series, tooltipMaxWidth);

        return Container(
          height: clampedHeight,
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.22) : Colors.white.withOpacity(0.82),
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
            primaryYAxis: const NumericAxis(
              isVisible: false,
              majorGridLines: MajorGridLines(width: 0),
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

  TooltipBehavior _buildTooltip(List<_ChartSeriesData> chartSeries, double maxWidth) {
    return TooltipBehavior(
      enable: true,
      color: Colors.transparent,
      header: '',
      canShowMarker: true,
      opacity: 1,
      animationDuration: 90,
      tooltipPosition: TooltipPosition.pointer,
      activationMode: ActivationMode.singleTap,
      shouldAlwaysShow: false,
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth * 0.45),
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  valuePoint.formattedValue,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ],
            ),
          );
        }).toList();

        return Material(
          color: Colors.transparent,
          elevation: 14,
          shadowColor: Colors.black54,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF12233d), Color(0xFF1f3a63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                ...rows,
              ],
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
    final doubleValue = value.toDouble();
    return doubleValue % 1 == 0 ? doubleValue.toStringAsFixed(0) : doubleValue.toStringAsFixed(2);
  }
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
