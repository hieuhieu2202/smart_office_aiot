import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';

class AreaChartWidget extends StatelessWidget {
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
              Text('Dữ liệu khu vực', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (controller.areaData.isNotEmpty &&
                  controller.areaData.containsKey('series') &&
                  controller.areaData.containsKey('categories') &&
                  (controller.areaData['series'] as List).isNotEmpty &&
                  (controller.areaData['categories'] as List).isNotEmpty)
                SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  series: (controller.areaData['series'] as List<dynamic>)
                      .where((serie) => serie['data'] != null && (serie['data'] as List).isNotEmpty)
                      .map((serie) => LineSeries<dynamic, String>(
                    name: serie['name'] ?? '',
                    dataSource: serie['data'] as List,
                    xValueMapper: (dynamic data, int index) =>
                    index < (controller.areaData['categories'] as List).length
                        ? controller.areaData['categories'][index].toString()
                        : '',
                    yValueMapper: (dynamic data, int index) => data,
                  ))
                      .toList(),
                )
              else
                Text('Không có dữ liệu khu vực'),
            ],
          ),
        ),
      ),
    );
  }
}