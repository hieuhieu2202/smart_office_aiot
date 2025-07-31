import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';

class SensorDataChartWidget extends StatelessWidget {
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
              Text('Dữ liệu cảm biến', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (controller.sensorData.isNotEmpty &&
                  controller.sensorData[0].containsKey('series') &&
                  controller.sensorData[0].containsKey('categories') &&
                  (controller.sensorData[0]['series'] as List).isNotEmpty &&
                  (controller.sensorData[0]['categories'] as List).isNotEmpty)
                SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  series: controller.sensorData
                      .map((sensor) => sensor['series'] as List<dynamic>)
                      .expand((series) => series)
                      .where((serie) => serie['data'] != null && (serie['data'] as List).isNotEmpty)
                      .map((serie) => LineSeries<dynamic, String>(
                    name: serie['name'] ?? '',
                    dataSource: serie['data'] as List,
                    xValueMapper: (dynamic data, int index) =>
                    index < (controller.sensorData[0]['categories'] as List).length
                        ? controller.sensorData[0]['categories'][index].toString()
                        : '',
                    yValueMapper: (dynamic data, int index) => data,
                  ))
                      .toList(),
                )
              else
                Text('Không có dữ liệu cảm biến'),
            ],
          ),
        ),
      ),
    );
  }
}