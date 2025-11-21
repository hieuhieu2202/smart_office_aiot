import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/area_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/bar_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/info/location_info_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/layout/room_layout_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/sensor_data_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/sensor_history_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/overview/sensor_overview_widget.dart';
import 'cleanroom_filter_panel.dart';


class CleanRoomScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.put(CleanRoomController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF041226), const Color(0xFF08264A), const Color(0xFF021325)]
                : [const Color(0xFFE5F1FF), Colors.white, const Color(0xFFD7E7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: isDark ? 0.25 : 0.4,
                  child: GridPaper(
                    divisions: 2,
                    interval: 80,
                    color: isDark ? Colors.lightBlueAccent.withOpacity(0.08) : Colors.blueGrey.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1920,
                    maxHeight: 1080,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 72,
                          child: _HeaderBar(onFilterTap: controller.toggleFilterPanel),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double bodyHeight = constraints.maxHeight;

                              const double sideWidth = 360;
                              const double spacing = 16;

                              const double locationHeight = 220;
                              const double overviewHeight = 200;
                              final double sensorChartHeight = (bodyHeight - (locationHeight + overviewHeight + spacing * 2))
                                  .clamp(320.0, bodyHeight)
                                  .toDouble();

                              final double chartRowHeight = (bodyHeight * 0.32).clamp(280.0, bodyHeight * 0.45).toDouble();
                              final double layoutHeight = (bodyHeight - chartRowHeight - spacing).clamp(360.0, bodyHeight).toDouble();

                              return Row(
                                children: [
                                  SizedBox(
                                    width: sideWidth,
                                    child: Column(
                                      children: [
                                        SizedBox(height: locationHeight, child: LocationInfoWidget()),
                                        const SizedBox(height: spacing),
                                        SizedBox(height: overviewHeight, child: SensorOverviewWidget()),
                                        const SizedBox(height: spacing),
                                        SizedBox(height: sensorChartHeight, child: SensorDataChartWidget()),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: spacing),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        SizedBox(height: layoutHeight, child: _NeonPanel(child: RoomLayoutWidget())),
                                        const SizedBox(height: spacing),
                                        SizedBox(
                                          height: chartRowHeight,
                                          child: Row(
                                            children: [
                                              Expanded(child: BarChartWidget()),
                                              const SizedBox(width: spacing),
                                              Expanded(child: AreaChartWidget()),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: spacing),
                                  SizedBox(
                                    width: sideWidth,
                                    child: SizedBox(
                                      height: bodyHeight,
                                      child: const SensorHistoryChartWidget(),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final VoidCallback onFilterTap;
  const _HeaderBar({required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? [const Color(0xFF0B2E59), const Color(0xFF0F3C71)]
              : [const Color(0xFFB9D8FF), Colors.white],
        ),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_mode, color: Colors.lightBlueAccent),
          const SizedBox(width: 10),
          Text(
            'Bảng điều khiển phòng sạch',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0C2340),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onFilterTap,
            icon: const Icon(Icons.filter_list),
            label: const Text('Lọc dữ liệu'),
          ),
        ],
      ),
    );
  }
}

class _NeonPanel extends StatelessWidget {
  final Widget child;
  const _NeonPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF0B1F3C), const Color(0xFF10386A)]
              : [Colors.white, const Color(0xFFE3EEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}