import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';

class RoomLayoutWidget extends StatelessWidget {
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
              Text('Bố cục phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (controller.roomImage.value != null &&
                  controller.configData.containsKey('data') &&
                  controller.configData['data'] is List &&
                  (controller.configData['data'] as List).isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Image(image: controller.roomImage.value!, fit: BoxFit.contain),
                      ...(controller.configData['data'] as List<dynamic>).map((sensor) {
                        double top = double.parse(sensor['Top'].replaceAll('%', '')) / 100 * 185;
                        double left = double.parse(sensor['Left'].replaceAll('%', '')) / 100 * MediaQuery.of(context).size.width*0.8;
                        return Positioned(
                          top: top,
                          left: left,
                          child: GestureDetector(
                            onTap: () {
                              Get.snackbar(
                                sensor['SensorName'],
                                'Menu: ${sensor['menu']}',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  sensor['SensorName'],
                                  style: TextStyle(fontSize: 8, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                )
              else
                Text('Không có hình ảnh hoặc dữ liệu cảm biến'),
            ],
          ),
        ),
      ),
    );
  }
}