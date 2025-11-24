import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import '../common/dashboard_card.dart';
import 'chart_style.dart';
import 'package:smart_factory/config/global_color.dart';

class SensorDataChartWidget extends StatelessWidget {
  const SensorDataChartWidget({super.key});

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
            ...controller.sensorData
                .where((sensor) =>
                    (sensor['series'] as List?)?.isNotEmpty == true &&
                    (sensor['categories'] as List?)?.isNotEmpty == true)
                .map((sensor) {
              final sensorName = (sensor['sensorName'] ?? '').toString();
              final categories = (sensor['categories'] as List<dynamic>).map((e) => e.toString()).toList();
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
                                dataSource: serie['data'] as List,
                                markerSettings: const MarkerSettings(isVisible: false),
                                xValueMapper: (dynamic data, int index) =>
                                    index < categories.length ? categories[index] : '',
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
    });
  }
}
