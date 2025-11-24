import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/area_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/bar_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/sensor_data_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/charts/sensor_history_chart_widget.dart';
import 'package:smart_factory/screen/home/widget/clean_room/widget/common/dashboard_card.dart';
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
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TopBar(onFilterTap: controller.toggleFilterPanel),
                        const SizedBox(height: 14),
                        LocationInfoWidget(),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 420,
                          child: _MapCard(isDark: isDark),
                        ),
                        const SizedBox(height: 14),
                        _SummaryCard(
                          controller: controller,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        SensorOverviewWidget(),
                        const SizedBox(height: 14),
                        SensorDataChartWidget(),
                        const SizedBox(height: 14),
                        SensorHistoryChartWidget(),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: BarChartWidget()),
                            const SizedBox(width: 14),
                            Expanded(child: AreaChartWidget()),
                          ],
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
          _BackButton(isDark: isDark),
          const SizedBox(width: 10),
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

class _SummaryCard extends StatelessWidget {
  final CleanRoomController controller;
  final bool isDark;

  const _SummaryCard({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: Icons.dashboard_customize_outlined, isDark: isDark),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sensor Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0a2540),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tổng số cảm biến & trạng thái',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: _SummaryGrid(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5aa6ff),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: controller.toggleFilterPanel,
              icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
              label: const Text('Chi tiết cảm biến', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CleanRoomController controller;
  final bool isDark;

  const _HistoryCard({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: Icons.timeline, isDark: isDark),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sensor History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0a2540),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thông số và biểu đồ của từng cảm biến',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 360,
            child: const SensorDataChartWidget(withCard: false),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final bool isDark;
  const _MapCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: Icons.map_outlined, isDark: isDark),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cleanroom Map',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0a2540),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vị trí cảm biến và trạng thái trên sơ đồ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RoomLayoutWidget(),
          ),
        ],
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final bool isDark;

  const _SectionIcon({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.cyanAccent.withOpacity(.82), Colors.blueAccent.shade200]
              : [const Color(0xFF5aa6ff), const Color(0xFF7cc5ff)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(.24), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _BackButton extends StatelessWidget {
  final bool isDark;
  const _BackButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Get.back(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)]
                : [const Color(0xFFe7f0ff), const Color(0xFFf4f7ff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.18 : 0.36)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 8)),
          ],
        ),
        child: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : const Color(0xFF0a2540), size: 18),
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

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CleanRoomController>();
    return Obx(() {
      final total = controller.sensorOverview['totalSensors'] ?? 0;
      final online = controller.sensorOverview['onlineSensors'] ?? 0;
      final warning = controller.sensorOverview['warningSensors'] ?? 0;
      final offline = controller.sensorOverview['offlineSensors'] ?? 0;

      return GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: [
          _StatChip(label: 'TOTAL', value: total.toString(), icon: Icons.layers, color: const Color(0xFF469cff)),
          _StatChip(label: 'ONLINE', value: online.toString(), icon: Icons.wifi_tethering, color: const Color(0xFF3ed399)),
          _StatChip(label: 'WARNING', value: warning.toString(), icon: Icons.warning_amber_rounded, color: const Color(0xFFf6b317)),
          _StatChip(label: 'OFFLINE', value: offline.toString(), icon: Icons.wifi_off_rounded, color: const Color(0xFF9aa6bb)),
        ],
      );
    });
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isDark
              ? [color.withOpacity(.3), const Color(0xFF0c223c)]
              : [Colors.white, const Color(0xFFe9f1ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(isDark ? 0.4 : 0.6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.14), blurRadius: 12, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(isDark ? 0.3 : 0.18),
              border: Border.all(color: Colors.white.withOpacity(.32)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white70 : Colors.blueGrey.shade800,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF0a2540),
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
        ],
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