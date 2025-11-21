import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import '../common/dashboard_card.dart';
import 'sensor_detail_dialog.dart';
import 'marker/sensor_marker.dart';

class RoomLayoutWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();

    return Obx(
      () => DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bố cục phòng',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (controller.roomImage.value != null &&
                controller.configData['data'] is List &&
                (controller.configData['data'] as List).isNotEmpty)
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, cons) {
                    final sensors = controller.configData['data'] as List<dynamic>;
                    final image = controller.roomImage.value!;
                    final maxWidth = cons.maxWidth;
                    final maxHeight = cons.maxHeight;
                    const aspect = 1.6;

                    double canvasWidth = maxWidth;
                    double canvasHeight = canvasWidth / aspect;
                    if (canvasHeight > maxHeight) {
                      canvasHeight = maxHeight;
                      canvasWidth = canvasHeight * aspect;
                    }

                    const circleDiameter = 17.0;

                    return Center(
                      child: SizedBox(
                        width: canvasWidth,
                        height: canvasHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image(image: image, fit: BoxFit.cover),
                              ),
                            ),
                            ...sensors.map((sensor) {
                              final topPercentStr = sensor['Top']?.toString().replaceAll('%', '') ?? '0';
                              final leftPercentStr = sensor['Left']?.toString().replaceAll('%', '') ?? '0';
                              final topPercent = double.tryParse(topPercentStr) ?? 0.0;
                              final leftPercent = double.tryParse(leftPercentStr) ?? 0.0;

                              final topPos = (topPercent.isNaN ? 0.0 : topPercent) / 100 * canvasHeight - circleDiameter;
                              final leftPos = (leftPercent.isNaN ? 0.0 : leftPercent) / 100 * canvasWidth - circleDiameter;

                              Map<String, dynamic>? dataEntry;
                              try {
                                dataEntry = controller.sensorData.firstWhere(
                                  (e) => e['sensorName'] == sensor['SensorName'],
                                );
                              } catch (_) {
                                dataEntry = null;
                              }

                              bool hasData = false;
                              if (dataEntry != null && dataEntry['series'] is List) {
                                final series = dataEntry['series'] as List;
                                hasData = series.any(
                                  (s) => s is Map && s['data'] is List && (s['data'] as List).isNotEmpty,
                                );
                              }

                              final areaName = dataEntry?['sensorDesc']?.toString() ?? '';

                              final menuMobile = sensor['menu-mobile']?.toString().toLowerCase() ?? '';
                              final menu = sensor['menu']?.toString().toLowerCase() ?? '';
                              final orientation = menuMobile.isNotEmpty ? menuMobile : menu;
                              bool labelOnTop = true;
                              if (orientation.contains('bottom')) {
                                labelOnTop = false;
                              } else if (orientation.contains('top')) {
                                labelOnTop = true;
                              }
                              bool triangleAtLeft = true;
                              if (menu.contains('right')) {
                                triangleAtLeft = false;
                              } else if (menu.contains('left')) {
                                triangleAtLeft = true;
                              }

                              return Positioned(
                                top: topPos,
                                left: leftPos,
                                child: SensorMarker(
                                  sensorName: sensor['SensorName'],
                                  areaName: areaName,
                                  online: hasData,
                                  triangleAtLeft: triangleAtLeft,
                                  labelOnTop: labelOnTop,
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => SensorDetailDialog(
                                        sensorName: sensor['SensorName'],
                                        dataEntry: dataEntry,
                                        online: hasData,
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.grid_off, size: 32, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Không có hình ảnh hoặc dữ liệu cảm biến'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
