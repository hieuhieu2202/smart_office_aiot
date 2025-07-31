import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import '../common/dashboard_card.dart';
import 'chart_style.dart';
import 'package:smart_factory/config/global_color.dart';

class AreaChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(
      () => DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dữ liệu khu vực',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (controller.areaData.isNotEmpty &&
                controller.areaData.containsKey('series') &&
                controller.areaData.containsKey('categories') &&
                (controller.areaData['series'] as List).isNotEmpty &&
                (controller.areaData['categories'] as List).isNotEmpty)
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
                  series: (controller.areaData['series'] as List<dynamic>)
                      .where((serie) => serie['data'] != null && (serie['data'] as List).isNotEmpty)
                      .map((serie) => LineSeries<dynamic, String>(
                            name: serie['name'] ?? '',
                            dataSource: serie['data'] as List,
                            markerSettings: const MarkerSettings(isVisible: true),
                            xValueMapper: (dynamic data, int index) =>
                                index < (controller.areaData['categories'] as List).length
                                    ? controller.areaData['categories'][index].toString()
                                    : '',
                            yValueMapper: (dynamic data, int index) => data,
                          ))
                      .toList(),
                ),
              )
            else
              const Text('Không có dữ liệu khu vực'),
          ],
        ),
      ),
    );
  }
}
