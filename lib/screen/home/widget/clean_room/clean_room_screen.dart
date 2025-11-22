import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/sensor_history_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/layout/room_layout_widget.dart';

import 'cleanroom_filter_panel.dart';


class CleanRoomScreen extends StatelessWidget {
  const CleanRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.put(CleanRoomController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const double outerPadding = 12;
    const double gridGap = 10;
    const int gridColumns = 5;
    const int gridRows = 5;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF031023), const Color(0xFF052444), const Color(0xFF0a3d73)]
                : [const Color(0xFFd8e7ff), const Color(0xFFe6f0ff), const Color(0xFFf2f7ff)],
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
                  constraints: const BoxConstraints(maxWidth: 1920, maxHeight: 1040),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: outerPadding, vertical: 14),
                    child: Column(
                      children: [
                        _TopBar(onFilterTap: controller.toggleFilterPanel),
                        const SizedBox(height: gridGap),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double bodyHeight = constraints.maxHeight;
                              final double bodyWidth = constraints.maxWidth;

                              final double cellWidth = (bodyWidth - gridGap * (gridColumns - 1)) / gridColumns;
                              final double cellHeight = (bodyHeight - gridGap * (gridRows - 1)) / gridRows;

                              final double leftWidth = cellWidth * 2 + gridGap;
                              final double summaryHeight = cellHeight * 2 + gridGap;
                              final double historyHeight = cellHeight * 3 + gridGap * 2;
                              final double mapWidth = cellWidth * 3 + gridGap * 2;
                              final double mapHeight = cellHeight * 5 + gridGap * 4;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: leftWidth,
                                    child: Column(
                                      children: [
                                        _SummaryPanel(height: summaryHeight),
                                        const SizedBox(height: gridGap),
                                        _GlassPanel(
                                          height: historyHeight,
                                          title: 'Lịch sử cảm biến',
                                          subtitle: 'Dòng sự kiện và xu hướng',
                                          leadingIcon: Icons.history_toggle_off,
                                          child: SensorHistoryChartWidget(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: gridGap),
                                  SizedBox(
                                    width: mapWidth,
                                    height: mapHeight,
                                    child: _GlassPanel(
                                      height: mapHeight,
                                      title: 'Sơ đồ phòng sạch',
                                      subtitle: 'Bản đồ bố trí cảm biến và trạng thái điểm đo',
                                      leadingIcon: Icons.location_on_outlined,
                                      actions: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(isDark ? 0.08 : 0.18),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.14 : 0.24)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.touch_app_outlined, size: 16, color: Colors.white70),
                                              SizedBox(width: 6),
                                              Text(
                                                'Chạm cảm biến để xem chi tiết',
                                                style: TextStyle(color: Colors.white70, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      child: RoomLayoutWidget(),
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

class _TopBar extends StatelessWidget {
  final VoidCallback onFilterTap;
  const _TopBar({required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final CleanRoomController controller = Get.find<CleanRoomController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0b1d38), const Color(0xFF0f2f55), const Color(0xFF114374)]
              : [const Color(0xFFdceaff), const Color(0xFFeaf2ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 22, offset: const Offset(0, 12)),
          BoxShadow(color: Colors.blueAccent.withOpacity(0.16), blurRadius: 26, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.cyanAccent.withOpacity(0.9), Colors.blueAccent.shade200]
                    : [Colors.blue.shade400, Colors.lightBlueAccent],
              ),
              boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(.36), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: const Icon(Icons.bubble_chart, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CLEAN ROOM SENSOR MONITOR',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0a2540),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Giám sát phòng sạch với bố cục cố định 1080p',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white70 : const Color(0xFF3b5068),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Obx(
            () => Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterChip(label: controller.selectedCustomer.value.isEmpty ? 'Customer' : controller.selectedCustomer.value),
                _FilterChip(label: controller.selectedFactory.value.isEmpty ? 'Factory' : controller.selectedFactory.value),
                _FilterChip(label: controller.selectedFloor.value.isEmpty ? 'Floor' : controller.selectedFloor.value),
                _FilterChip(label: controller.selectedRoom.value.isEmpty ? 'Room' : controller.selectedRoom.value),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    foregroundColor: isDark ? Colors.white : Colors.blueGrey.shade900,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onFilterTap,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Bộ lọc'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(.06) : Colors.blueGrey.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(isDark ? .16 : .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.lightBlueAccent),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.blueGrey.shade800, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final double height;
  const _SummaryPanel({required this.height});

  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();

    return _GlassPanel(
      height: height,
      title: 'Tổng quan cảm biến',
      subtitle: 'Tổng số, trạng thái và chi tiết',
      leadingIcon: Icons.dashboard_outlined,
      trailing: TextButton(
        onPressed: controller.fetchData,
        child: const Text('Làm mới'),
      ),
      child: Obx(
        () {
          final total = controller.sensorOverview['totalSensors'] ?? 0;
          final online = controller.sensorOverview['onlineSensors'] ?? 0;
          final warning = controller.sensorOverview['warningSensors'] ?? 0;
          final offline = controller.sensorOverview['offlineSensors'] ?? 0;

          return Column(
            children: [
              Row(
                children: [
                  _StatTile(
                    height: 96,
                    icon: Icons.layers,
                    label: 'TOTAL',
                    value: total.toString(),
                    color: const Color(0xFF4fa5ff),
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    height: 96,
                    icon: Icons.wifi_tethering,
                    label: 'ONLINE',
                    value: online.toString(),
                    color: const Color(0xFF4bd1a0),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatTile(
                    height: 96,
                    icon: Icons.warning_amber_rounded,
                    label: 'WARNING',
                    value: warning.toString(),
                    color: const Color(0xFFf7b500),
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    height: 96,
                    icon: Icons.wifi_off_rounded,
                    label: 'OFFLINE',
                    value: offline.toString(),
                    color: const Color(0xFF94a0b8),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFFf7b500),
                  ),
                  onPressed: controller.toggleFilterPanel,
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text('XEM CHI TIẾT', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double? height;

  const _StatTile({required this.icon, required this.label, required this.value, required this.color, this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(isDark ? .45 : .85),
              const Color(0xFF0b1d38).withOpacity(.88),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          border: Border.all(color: color.withOpacity(isDark ? 0.32 : 0.52)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 16, offset: const Offset(0, 10)),
            BoxShadow(color: color.withOpacity(.26), blurRadius: 22, spreadRadius: -6, offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.08),
                border: Border.all(color: Colors.white.withOpacity(.2)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(.85),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final double? height;
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final List<Widget>? actions;
  final Widget? trailing;

  const _GlassPanel({
    required this.child,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    this.height,
    this.actions,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF062045), const Color(0xFF0a2f5e), const Color(0xFF0f4c8c)]
              : [const Color(0xFFd7e9ff), const Color(0xFFe7f1ff)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 24, offset: const Offset(0, 14)),
          BoxShadow(color: Colors.blueAccent.withOpacity(.16), blurRadius: 30, spreadRadius: -10, offset: const Offset(0, 16)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0c2d52).withOpacity(.92), const Color(0xFF0b1f3c).withOpacity(.94)]
                  : [const Color(0xFFf7fbff), const Color(0xFFe8f1ff)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Semantics(
            label: title,
            hint: subtitle,
            child: child,
          ),
        ),
      ),
    );

    return height != null ? SizedBox(height: height, child: panel) : panel;
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