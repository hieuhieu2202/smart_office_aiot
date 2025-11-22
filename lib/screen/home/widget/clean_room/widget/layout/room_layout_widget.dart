import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import 'sensor_detail_dialog.dart';
import 'marker/sensor_marker.dart';

class RoomLayoutWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();

    return Obx(
      () {
        final hasLayout = controller.roomImage.value != null &&
            controller.configData['data'] is List &&
            (controller.configData['data'] as List).isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0b3a6a).withOpacity(.52),
                const Color(0xFF0f5c9c).withOpacity(.55),
                const Color(0xFF0c2749).withOpacity(.58),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.35),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF0a2747), const Color(0xFF081a31).withOpacity(.95)],
                ),
              ),
              child: LayoutBuilder(
                builder: (ctx, cons) {
                  final maxWidth = cons.maxWidth;
                  final maxHeight = cons.maxHeight;
                  const aspect = 1.85;

                  double canvasWidth = maxWidth;
                  double canvasHeight = canvasWidth / aspect;
                  if (canvasHeight > maxHeight) {
                    canvasHeight = maxHeight;
                    canvasWidth = canvasHeight * aspect;
                  }

                  const double markerDiameter = 16.0;

                  if (!hasLayout) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.map_outlined, color: Colors.white70, size: 36),
                          SizedBox(height: 10),
                          Text(
                            'Chưa có sơ đồ phòng hoặc dữ liệu cảm biến',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  }

                  final sensors = controller.configData['data'] as List<dynamic>;
                  final image = controller.roomImage.value!;

                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: canvasWidth,
                          height: canvasHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.25),
                                blurRadius: 22,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(.2),
                                blurRadius: 28,
                                spreadRadius: -6,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: Colors.white.withOpacity(.08)),
                          ),
                        ),
                        SizedBox(
                          width: canvasWidth,
                          height: canvasHeight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image(image: image, fit: BoxFit.cover),
                                ),
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(.08),
                                          Colors.black.withOpacity(.12),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ),
                                ...sensors.map((sensor) {
                                  final topPercentStr = sensor['Top']?.toString().replaceAll('%', '') ?? '0';
                                  final leftPercentStr = sensor['Left']?.toString().replaceAll('%', '') ?? '0';
                                  final topPercent = double.tryParse(topPercentStr) ?? 0.0;
                                  final leftPercent = double.tryParse(leftPercentStr) ?? 0.0;

                                  final topPos = (topPercent.isNaN ? 0.0 : topPercent) / 100 * canvasHeight - markerDiameter;
                                  final leftPos = (leftPercent.isNaN ? 0.0 : leftPercent) / 100 * canvasWidth - markerDiameter;

                                  Map<String, dynamic>? dataEntry;
                                  try {
                                    dataEntry = controller.sensorData.firstWhere(
                                      (e) => e['sensorName'] == sensor['SensorName'],
                                    );
                                  } catch (_) {
                                    dataEntry = null;
                                  }

                                  bool hasDataPoint = false;
                                  if (dataEntry != null && dataEntry['series'] is List) {
                                    final series = dataEntry['series'] as List;
                                    hasDataPoint = series.any(
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
                                      online: hasDataPoint,
                                      triangleAtLeft: triangleAtLeft,
                                      labelOnTop: labelOnTop,
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => SensorDetailDialog(
                                            sensorName: sensor['SensorName'],
                                            dataEntry: dataEntry,
                                            online: hasDataPoint,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.35),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(.12)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.touch_app_outlined, size: 16, color: Colors.white70),
                                SizedBox(width: 8),
                                Text(
                                  'Chạm vào cảm biến để xem chi tiết',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
