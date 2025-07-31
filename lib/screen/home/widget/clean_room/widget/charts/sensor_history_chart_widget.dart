import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import '../common/dashboard_card.dart';
import 'chart_style.dart';
import 'package:smart_factory/config/global_color.dart';

class SensorHistoryChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(
      () => DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lịch sử cảm biến',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (controller.sensorHistories.isNotEmpty &&
                controller.sensorHistories[0].containsKey('series') &&
                controller.sensorHistories[0].containsKey('categories') &&
                (controller.sensorHistories[0]['series'] as List).isNotEmpty &&
                (controller.sensorHistories[0]['categories'] as List).isNotEmpty)
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  palette: CleanRoomChartStyle.palette(isDark),
                  primaryXAxis: CategoryAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                  ),
                  primaryYAxis: NumericAxis(
                    majorGridLines: const MajorGridLines(dashArray: [4, 4]),
                  ),
                  legend: const Legend(isVisible: true),
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    color: isDark
                        ? GlobalColors.tooltipBgDark
                        : GlobalColors.tooltipBgLight,
                  ),
                  series: controller.sensorHistories
                      .map((sensor) => sensor['series'] as List<dynamic>)
                      .expand((series) => series)
                      .where((serie) => serie['data'] != null && (serie['data'] as List).isNotEmpty)
                      .map((serie) => LineSeries<dynamic, String>(
                            name: serie['name'] ?? '',
                            dataSource: serie['data'] as List,
                            markerSettings: const MarkerSettings(isVisible: true),
                            xValueMapper: (dynamic data, int index) =>
                                index < (controller.sensorHistories[0]['categories'] as List).length
                                    ? controller.sensorHistories[0]['categories'][index].toString()
                                    : '',
                            yValueMapper: (dynamic data, int index) => data,
                          ))
                      .toList(),
                ),
              )
            else
              const Text('Không có lịch sử cảm biến'),
          ],
        ),
      ),
    );
  }
}
