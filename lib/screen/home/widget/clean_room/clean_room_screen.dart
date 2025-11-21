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
  const CleanRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.put(CleanRoomController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const double headerHeight = 86;
    const double outerPadding = 22;
    const double hSpacing = 16;
    const double vSpacing = 16;
    const double leftWidth = 360;
    const double rightWidth = 380;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF021026), const Color(0xFF042d56), const Color(0xFF0b4a7a)]
                : [const Color(0xFFdceaff), const Color(0xFFd7e7ff), const Color(0xFFf2f6ff)],
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
                  constraints: const BoxConstraints(maxWidth: 1900, maxHeight: 1040),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: outerPadding, vertical: 18),
                    child: Column(
                      children: [
                        SizedBox(
                          height: headerHeight,
                          child: _HeaderBar(onFilterTap: controller.toggleFilterPanel),
                        ),
                        const SizedBox(height: vSpacing),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double bodyHeight = constraints.maxHeight;

                              const double locationHeight = 176;
                              const double overviewHeight = 186;
                              final double sensorChartHeight =
                                  (bodyHeight - locationHeight - overviewHeight - vSpacing * 2).clamp(260.0, 420.0);

                              final double mapHeight = (bodyHeight * 0.55).clamp(470.0, 620.0);
                              final double chartRowHeight = (bodyHeight - mapHeight - vSpacing).clamp(260.0, bodyHeight);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: leftWidth,
                                    child: Column(
                                      children: [
                                        _InfoPanel(height: locationHeight, child: LocationInfoWidget()),
                                        const SizedBox(height: vSpacing),
                                        _InfoPanel(height: overviewHeight, child: SensorOverviewWidget()),
                                        const SizedBox(height: vSpacing),
                                        _InfoPanel(height: sensorChartHeight, child: SensorDataChartWidget()),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: hSpacing),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _DataPanel(
                                          height: mapHeight,
                                          title: 'Sơ đồ phòng sạch',
                                          subtitle: 'Bản đồ khu vực và trạng thái điểm đo',
                                          child: RoomLayoutWidget(),
                                        ),
                                        const SizedBox(height: vSpacing),
                                        SizedBox(
                                          height: chartRowHeight,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _DataPanel(
                                                  title: 'Tần suất cảnh báo',
                                                  subtitle: 'Tổng hợp cảnh báo gần đây',
                                                  child: BarChartWidget(),
                                                ),
                                              ),
                                              const SizedBox(width: hSpacing),
                                              Expanded(
                                                child: _DataPanel(
                                                  title: 'Xu hướng theo thời gian',
                                                  subtitle: 'Biểu đồ biến động cảm biến',
                                                  child: AreaChartWidget(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: hSpacing),
                                  SizedBox(
                                    width: rightWidth,
                                    child: _DataPanel(
                                      height: bodyHeight,
                                      title: 'Lịch sử cảm biến',
                                      subtitle: 'Dữ liệu real-time và ghi nhận',
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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0b1f3f), const Color(0xFF0f3f76), const Color(0xFF1662a3)]
              : [const Color(0xFFdce9ff), const Color(0xFFeaf2ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.08 : 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.2),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.cyanAccent.withOpacity(0.9), Colors.blueAccent.shade200]
                    : [Colors.blue.shade300, Colors.lightBlueAccent],
              ),
              boxShadow: [
                BoxShadow(color: Colors.cyanAccent.withOpacity(.38), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.bubble_chart, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    'Cleanroom Command',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0a2540),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(.22)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.monitor_heart_outlined, size: 14, color: Colors.white70),
                        SizedBox(width: 6),
                        Text('1080p fixed layout', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Giám sát phòng sạch thời gian thực với bố cục cố định',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white70 : const Color(0xFF3b5068),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeaderChip(icon: Icons.cloud_outlined, label: 'Realtime data'),
              _HeaderChip(icon: Icons.shield_outlined, label: 'Safety view'),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  foregroundColor: isDark ? Colors.white : Colors.blueGrey.shade900,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onFilterTap,
                icon: const Icon(Icons.filter_list),
                label: const Text('Bộ lọc dữ liệu'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(.06) : Colors.blueGrey.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(isDark ? .18 : .32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isDark ? Colors.white70 : Colors.blueGrey.shade700, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.blueGrey.shade800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DataPanel extends StatelessWidget {
  final Widget child;
  final double? height;
  final String title;
  final String subtitle;

  const _DataPanel({required this.child, required this.title, required this.subtitle, this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0a2041), const Color(0xFF0b3965), const Color(0xFF0d4c82)]
              : [Colors.white, const Color(0xFFe7efff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.08 : 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 22, offset: const Offset(0, 12)),
          BoxShadow(color: Colors.blueAccent.withOpacity(.18), blurRadius: 32, spreadRadius: -8, offset: const Offset(0, 16)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF0d2c54).withOpacity(.94), const Color(0xFF0a1d37).withOpacity(.95)]
                  : [Colors.white, const Color(0xFFf2f6ff)],
            ),
          ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white70 : Colors.blueGrey.shade600,
                              ),
                        ),
                      ],
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

class _InfoPanel extends StatelessWidget {
  final double height;
  final Widget child;

  const _InfoPanel({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.05)]
              : [Colors.white, const Color(0xFFedf2ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0f294d), const Color(0xFF0c1f3d)]
                  : [Colors.white, const Color(0xFFf3f7ff)],
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