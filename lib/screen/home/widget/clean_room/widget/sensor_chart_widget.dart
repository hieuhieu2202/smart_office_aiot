import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';

class SensorOverviewWidget extends StatelessWidget {
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
              Text('Tổng quan cảm biến', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Tổng cộng: ${controller.sensorOverview['totalSensors'] ?? 0}'),
              Text('Đang hoạt động: ${controller.sensorOverview['onlineSensors'] ?? 0}'),
              Text('Ngừng hoạt động: ${controller.sensorOverview['offlineSensors'] ?? 0}'),
              Text('Cảnh báo: ${controller.sensorOverview['warningSensors'] ?? 0}'),
            ],
          ),
        ),
      ),
    );
  }
}