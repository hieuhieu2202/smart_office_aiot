import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/area_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/bar_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/sensor_data_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/sensor_history_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/info/location_info_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/layout/room_layout_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/overview/sensor_overview_widget.dart';

import 'cleanroom_filter_panel.dart';


class CleanRoomScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.put(CleanRoomController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF040b1f), const Color(0xFF0b1e3f), const Color(0xFF0c2e58)]
                : [const Color(0xFFe9f2ff), const Color(0xFFdfe7ff), const Color(0xFFf6f9ff)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: _AuroraBackdrop(isDark: isDark),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1880, maxHeight: 1040),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: Column(
                      children: [
                        SizedBox(height: 88, child: _HeaderBar(onFilterTap: controller.toggleFilterPanel)),
                        const SizedBox(height: 18),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final bodyHeight = constraints.maxHeight;
                              const double sideWidth = 360;
                              const double rightWidth = 380;
                              const double spacing = 18;

                              const double locationHeight = 210;
                              const double overviewHeight = 210;
                              final double sensorChartHeight = (bodyHeight - locationHeight - overviewHeight - spacing * 2)
                                  .clamp(320.0, bodyHeight);

                              final double mapHeight = (bodyHeight * 0.5).clamp(420.0, bodyHeight - 280);
                              final double chartRowHeight = (bodyHeight - mapHeight - spacing).clamp(260.0, 360.0);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: sideWidth,
                                    child: Column(
                                      children: [
                                        _GlassCard(height: locationHeight, child: LocationInfoWidget()),
                                        const SizedBox(height: spacing),
                                        _GlassCard(height: overviewHeight, child: SensorOverviewWidget()),
                                        const SizedBox(height: spacing),
                                        _GlassCard(height: sensorChartHeight, child: SensorDataChartWidget()),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: spacing),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _GradientPanel(
                                          height: mapHeight,
                                          title: 'Sơ đồ phòng sạch',
                                          child: RoomLayoutWidget(),
                                        ),
                                        const SizedBox(height: spacing),
                                        SizedBox(
                                          height: chartRowHeight,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _GradientPanel(
                                                  title: 'Tần suất cảnh báo',
                                                  child: BarChartWidget(),
                                                ),
                                              ),
                                              const SizedBox(width: spacing),
                                              Expanded(
                                                child: _GradientPanel(
                                                  title: 'Xu hướng theo thời gian',
                                                  child: AreaChartWidget(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: spacing),
                                  SizedBox(
                                    width: rightWidth,
                                    child: _GradientPanel(
                                      height: bodyHeight,
                                      title: 'Lịch sử cảm biến',
                                      child: SensorHistoryChartWidget(),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0b2345), const Color(0xFF123c72)]
              : [const Color(0xFFdbe9ff), const Color(0xFFf7fbff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.08 : 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.cyanAccent.withOpacity(0.8), Colors.blueAccent.shade200]
                    : [Colors.blueAccent.shade200, Colors.lightBlueAccent],
              ),
            ),
            child: const Icon(Icons.bubble_chart, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Cleanroom Command',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0a2540),
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                'Giám sát thời gian thực với bố cục cố định 1080p',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white70 : const Color(0xFF38536f),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              foregroundColor: isDark ? Colors.white : Colors.blueGrey.shade900,
              backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onFilterTap,
            icon: const Icon(Icons.filter_list),
            label: const Text('Bộ lọc dữ liệu'),
          ),
        ],
      ),
    );
  }
}

class _GradientPanel extends StatelessWidget {
  final Widget child;
  final double? height;
  final String title;

  const _GradientPanel({required this.child, required this.title, this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0c1f3d), const Color(0xFF0f2f59)]
              : [Colors.white, const Color(0xFFe8f0ff)],
        ),
        border: Border.all(color: isDark ? Colors.white24 : Colors.blueGrey.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.18),
            blurRadius: 32,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF0e274b).withOpacity(0.9), const Color(0xFF09182f).withOpacity(0.92)]
                  : [Colors.white, const Color(0xFFeef4ff)],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [Colors.cyanAccent.shade200, Colors.blueAccent.shade200],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );

    return height != null ? SizedBox(height: height, child: panel) : panel;
  }
}

class _GlassCard extends StatelessWidget {
  final double height;
  final Widget child;

  const _GlassCard({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.04)]
              : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: isDark ? Colors.white12 : Colors.blueGrey.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0b1f3c), const Color(0xFF0c2747)]
                  : [Colors.white, const Color(0xFFf1f5ff)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AuroraBackdrop extends StatelessWidget {
  final bool isDark;
  const _AuroraBackdrop({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 60,
          left: -80,
          child: _blob(radius: 240, colors: [Colors.blueAccent.withOpacity(0.18), Colors.cyanAccent.withOpacity(0.12)]),
        ),
        Positioned(
          right: -120,
          top: 120,
          child: _blob(radius: 280, colors: [Colors.purpleAccent.withOpacity(0.16), Colors.blue.withOpacity(0.12)]),
        ),
        Positioned(
          bottom: -120,
          left: 160,
          child: _blob(radius: 260, colors: [Colors.blue.withOpacity(0.1), Colors.tealAccent.withOpacity(0.12)]),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: isDark ? 0.18 : 0.28,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white24, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.8],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blob({required double radius, required List<Color> colors}) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors, center: Alignment.center, radius: 0.75),
        boxShadow: [
          BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 80, spreadRadius: 50),
        ],
      ),
    );
  }
}