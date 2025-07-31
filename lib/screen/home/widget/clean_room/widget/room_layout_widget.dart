import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import 'dashboard_card.dart';

class RoomLayoutWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();

    return Obx(
      () => DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bố cục phòng',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            if (controller.roomImage.value != null &&
                controller.configData['data'] is List &&
                (controller.configData['data'] as List).isNotEmpty)
              LayoutBuilder(
                builder: (ctx, cons) {
                  final sensors = controller.configData['data'] as List<dynamic>;
                  final image = controller.roomImage.value!;
                  final width = cons.maxWidth;
                  final height = width / 1.6; // match AspectRatio
                  return AspectRatio(
                    aspectRatio: 1.6,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image(image: image, fit: BoxFit.contain),
                        ),
                        ...sensors.map((sensor) {
                          final topPercentStr = sensor['Top']?.toString().replaceAll('%', '') ?? '0';
                          final leftPercentStr = sensor['Left']?.toString().replaceAll('%', '') ?? '0';
                          final topPercent = double.tryParse(topPercentStr) ?? 0.0;
                          final leftPercent = double.tryParse(leftPercentStr) ?? 0.0;
                          final topPos = (topPercent.isNaN ? 0.0 : topPercent) / 100 * height;
                          final leftPos = (leftPercent.isNaN ? 0.0 : leftPercent) / 100 * width;
                          return Positioned(
                            top: topPos,
                            left: leftPos,
                            child: GestureDetector(
                              onTap: () {
                                Get.snackbar(
                                  sensor['SensorName'],
                                  'Menu: ${sensor['menu']}',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    sensor['SensorName'],
                                    style: const TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              )
            else
              const Text('Không có hình ảnh hoặc dữ liệu cảm biến'),
          ],
        ),
      ),
    );
  }
}
