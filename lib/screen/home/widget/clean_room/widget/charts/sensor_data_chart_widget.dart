import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import '../common/dashboard_card.dart';
import 'chart_style.dart';
import 'package:smart_factory/config/global_color.dart';

class SensorDataChartWidget extends StatelessWidget {
  const SensorDataChartWidget({super.key});

  /// Returns a shorter label (e.g. `HH:mm`) when the category contains
  /// a datetime string, otherwise falls back to the raw value.
  String _compactLabel(String raw) {
    final parsed = DateTime.tryParse(raw.replaceAll('/', '-'));
    if (parsed != null) {
      return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    }

    if (raw.contains(' ')) {
      final parts = raw.split(' ');
      return parts.last;
    }

    return raw;
  }

  /// Returns indices limited to the most recent 10 hours (approx. 20 points
  /// when data arrives every 30 minutes). Falls back to the latest 20 points
  /// when timestamps cannot be parsed.
  List<int> _recentIndices(List<String> categories) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 10));
    final parsed = categories
        .map((raw) => DateTime.tryParse(raw.replaceAll('/', '-')))
        .toList();

    final indices = <int>[];
    for (var i = 0; i < parsed.length; i++) {
      final ts = parsed[i];
      if (ts != null && !ts.isBefore(cutoff)) {
        indices.add(i);
      }
    }

    if (indices.isNotEmpty) {
      return indices;
    }

    final start = math.max(categories.length - 20, 0);
    return List<int>.generate(categories.length - start, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.sensorData.isEmpty) {
        return const DashboardCard(
          child: Text('Không có dữ liệu cảm biến'),
        );
      }

      final palette = CleanRoomChartStyle.palette(isDark);

      return DashboardCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sensors = controller.sensorData
                .where((sensor) =>
                    (sensor['series'] as List?)?.isNotEmpty == true &&
                    (sensor['categories'] as List?)?.isNotEmpty == true)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dữ liệu cảm biến',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...sensors.map((sensor) {
                    final sensorName = (sensor['sensorName'] ?? '').toString();
                    final categories =
                        (sensor['categories'] as List<dynamic>).map((e) => e.toString()).toList();
                    final keep = _recentIndices(categories);
                    final formattedCategories = keep
                        .where((i) => i < categories.length)
                        .map((i) => _compactLabel(categories[i]))
                        .toList();
                    final seriesList = sensor['series'] as List<dynamic>;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sensorName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                sensorName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          SizedBox(
                            height: 260,
                            child: SfCartesianChart(
                              palette: palette,
                              primaryXAxis: CategoryAxis(
                                majorGridLines: const MajorGridLines(width: 0),
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontSize: 11),
                              ),
                              primaryYAxis: NumericAxis(
                                majorGridLines: const MajorGridLines(dashArray: [4, 4]),
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontSize: 11),
                              ),
                              legend: const Legend(isVisible: true),
                              tooltipBehavior: TooltipBehavior(
                                enable: true,
                                color: isDark
                                    ? GlobalColors.tooltipBgDark
                                    : GlobalColors.tooltipBgLight,
                              ),
                              series: seriesList
                                  .where((serie) =>
                                      serie['data'] != null && (serie['data'] as List).isNotEmpty)
                                  .map(
                                    (serie) => SplineSeries<dynamic, String>(
                                      name: (serie['parameterDisplayName'] ?? serie['name'] ?? '')
                                          .toString(),
                                      dataSource: keep
                                          .where((i) =>
                                              i < (serie['data'] as List).length && i < categories.length)
                                          .map((i) => (serie['data'] as List)[i])
                                          .toList(),
                                      markerSettings: const MarkerSettings(isVisible: false),
                                      xValueMapper: (dynamic data, int index) =>
                                          index < formattedCategories.length
                                              ? formattedCategories[index]
                                              : '',
                                      yValueMapper: (dynamic data, int index) => data,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
