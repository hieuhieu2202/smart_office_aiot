import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import 'dashboard_card.dart';

class BarChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();
    return Obx(
      () => DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dữ liệu thanh',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (controller.barData.isNotEmpty &&
                controller.barData.containsKey('series') &&
                controller.barData.containsKey('categories') &&
                (controller.barData['series'] as List).isNotEmpty &&
                (controller.barData['categories'] as List).isNotEmpty)
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  legend: const Legend(isVisible: true),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: (controller.barData['series'] as List<dynamic>)
                      .where((serie) => serie['data'] != null && (serie['data'] as List).isNotEmpty)
                      .map((serie) => BarSeries<dynamic, String>(
                            name: serie['name'] ?? '',
                            dataSource: serie['data'] as List,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                            xValueMapper: (dynamic data, int index) =>
                                index < (controller.barData['categories'] as List).length
                                    ? controller.barData['categories'][index].toString()
                                    : '',
                            yValueMapper: (dynamic data, int index) => data,
                          ))
                      .toList(),
                ),
              )
            else
              const Text('Không có dữ liệu thanh'),
          ],
        ),
      ),
    );
  }
}
