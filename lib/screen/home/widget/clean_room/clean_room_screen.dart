import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/area_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/bar_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/location_info_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/room_layout_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/sensor_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/sensor_data_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/sensor_history_chart_widget.dart';
import 'cleanroom_filter_panel.dart';


class CleanRoomScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.put(CleanRoomController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bảng điều khiển phòng sạch'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: controller.toggleFilterPanel,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                LocationInfoWidget(),
                RoomLayoutWidget(),
                SensorOverviewWidget(),
                SensorDataChartWidget(),
                SensorHistoryChartWidget(),
                BarChartWidget(),
                AreaChartWidget(),
              ],
            ),
          ),
          Obx(
                () => CleanroomFilterPanel(
              show: controller.showFilterPanel.value,
              start: controller.selectedStartDate.value,
              end: controller.selectedEndDate.value,
              customer: controller.selectedCustomer.value.isEmpty ? null : controller.selectedCustomer.value,
              factory: controller.selectedFactory.value.isEmpty ? null : controller.selectedFactory.value,
              floor: controller.selectedFloor.value.isEmpty ? null : controller.selectedFloor.value,
              room: controller.selectedRoom.value.isEmpty ? null : controller.selectedRoom.value,
              customerOptions: controller.customers,
              factoryOptions: controller.factories,
              floorOptions: controller.floors,
              roomOptions: controller.rooms,
              onApply: controller.applyFilter,
              onClose: controller.toggleFilterPanel,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}