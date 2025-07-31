import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import 'dashboard_card.dart';

class SensorOverviewWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();
    final textTheme = Theme.of(context).textTheme;

    Widget buildItem(String label, dynamic value, Color color) {
      return Expanded(
        child: Column(
          children: [
            Text(value.toString(),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Obx(
      () => DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng quan cảm biến',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                buildItem('Tổng cộng', controller.sensorOverview['totalSensors'] ?? 0, Colors.blue),
                buildItem('Online', controller.sensorOverview['onlineSensors'] ?? 0, Colors.green),
                buildItem('Offline', controller.sensorOverview['offlineSensors'] ?? 0, Colors.red),
                buildItem('Cảnh báo', controller.sensorOverview['warningSensors'] ?? 0, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
