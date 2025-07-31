import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';

class BarChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();

    return Obx(
          () => Card(
        margin: EdgeInsets.all(8.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dữ liệu thanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (controller.barData.isNotEmpty &&
                  controller.barData.containsKey('series') &&
                  controller.barData.containsKey('categories') &&
                  (controller.barData['series'] as List).isNotEmpty &&
                  (controller.barData['categories'] as List).isNotEmpty)
                SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  series: (controller.barData['series'] as List<dynamic>)
                      .where((serie) => serie['data'] != null && (serie['data'] as List).isNotEmpty)
                      .map((serie) => BarSeries<dynamic, String>(
                    name: serie['name'] ?? '',
                    dataSource: serie['data'] as List,
                    xValueMapper: (dynamic data, int index) =>
                    index < (controller.barData['categories'] as List).length
                        ? controller.barData['categories'][index].toString()
                        : '',
                    yValueMapper: (dynamic data, int index) => data,
                  ))
                      .toList(),
                )
              else
                Text('Không có dữ liệu thanh'),
            ],
          ),
        ),
      ),
    );
  }
}