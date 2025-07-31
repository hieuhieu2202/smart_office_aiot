import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';

class LocationInfoWidget extends StatelessWidget {
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
              Text('Thông tin vị trí', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Khách hàng: ${controller.selectedCustomer.value.isEmpty ? "Chưa chọn" : controller.selectedCustomer.value}'),
              Text('Nhà máy: ${controller.selectedFactory.value.isEmpty ? "Chưa chọn" : controller.selectedFactory.value}'),
              Text('Tầng: ${controller.selectedFloor.value.isEmpty ? "Chưa chọn" : controller.selectedFloor.value}'),
              Text('Phòng: ${controller.selectedRoom.value.isEmpty ? "Chưa chọn" : controller.selectedRoom.value}'),
            ],
          ),
        ),
      ),
    );
  }
}