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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: _TopBar(onFilterTap: controller.toggleFilterPanel),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                              maxWidth: 1440,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              child: Center(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    LocationInfoWidget(),
                                    const SizedBox(height: 14),
                                    _MainRow(isDark: isDark, controller: controller),
                                    const SizedBox(height: 14),
                                    _ChartRow(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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

class _MainRow extends StatelessWidget {
  final bool isDark;
  final CleanRoomController controller;

  const _MainRow({required this.isDark, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 240,
                child: _SummaryCard(controller: controller, isDark: isDark),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 420,
                child: _HistoryCard(isDark: isDark),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 460,
                child: _MapCard(isDark: isDark),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 420,
                child: DashboardCard(
                  padding: const EdgeInsets.all(12),
                  child: SensorOverviewWidget(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 420,
                child: DashboardCard(
                  padding: const EdgeInsets.all(12),
                  child: SensorDataChartWidget(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Row(
        children: [
          Expanded(
            child: DashboardCard(
              padding: const EdgeInsets.all(12),
              child: BarChartWidget(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: DashboardCard(
              padding: const EdgeInsets.all(12),
              child: AreaChartWidget(),
            ),
          ),
        ],
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

    return DashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            () {
              final controller = Get.find<CleanRoomController>();
              return Wrap(
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
              );
            },
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
                label: const Text('Làm mới'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.blueGrey.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: const [
                _StatTile(title: 'TOTAL', valueKey: 'total', icon: Icons.layers, color: Color(0xFF5aa6ff)),
                _StatTile(title: 'ONLINE', valueKey: 'online', icon: Icons.ssid_chart, color: Color(0xFF22d3a8)),
                _StatTile(title: 'WARNING', valueKey: 'warning', icon: Icons.warning_amber_rounded, color: Color(0xFFf9b234)),
                _StatTile(title: 'OFFLINE', valueKey: 'offline', icon: Icons.wifi_off_rounded, color: Color(0xFF9aa4b1)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF1d7bff),
              ),
              onPressed: controller.onDetailTap,
              icon: const Icon(Icons.arrow_circle_right_outlined),
              label: const Text('Details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final bool isDark;

  const _HistoryCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: Icons.history_toggle_off_outlined, isDark: isDark),
              const SizedBox(width: 10),
              Text(
                'Sensor Histories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0a2540),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DashboardCard(
              padding: EdgeInsets.zero,
              child: SensorHistoryChartWidget(),
            ),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: Icons.map_outlined, isDark: isDark),
              const SizedBox(width: 10),
              Text(
                'Room Layout',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0a2540),
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Get.find<CleanRoomController>().refreshRoomLayout(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: DashboardCard(
              padding: EdgeInsets.zero,
              child: RoomLayoutWidget(),
            ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.cyanAccent.withOpacity(.36), Colors.blueAccent.withOpacity(.32)]
              : [const Color(0xFF5aa6ff), const Color(0xFF7fc5ff)],
        ),
        border: Border.all(color: Colors.white.withOpacity(isDark ? .22 : .32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.26), blurRadius: 14, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.blueAccent.withOpacity(.18), blurRadius: 20, spreadRadius: -6),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String valueKey;
  final IconData icon;
  final Color color;

  const _StatTile({required this.title, required this.valueKey, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CleanRoomController>();

    String value() {
      switch (valueKey) {
        case 'total':
          return controller.totalSensors.value.toString();
        case 'online':
          return controller.onlineSensors.value.toString();
        case 'warning':
          return controller.warningSensors.value.toString();
        case 'offline':
          return controller.offlineSensors.value.toString();
        default:
          return '0';
      }
    }

    return DashboardCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0a2540),
                      ),
                ),
                const SizedBox(height: 6),
                Obx(
                  () => Text(
                    value(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0a2540),
                        ),
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

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(isDark ? .2 : .4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0a2540),
            ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final bool isDark;

  const _BackButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.cyanAccent.withOpacity(.36), Colors.blueAccent.withOpacity(.32)]
                : [const Color(0xFF5aa6ff), const Color(0xFF7fc5ff)],
          ),
          border: Border.all(color: Colors.white.withOpacity(isDark ? .22 : .32)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.26), blurRadius: 14, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.blueAccent.withOpacity(.18), blurRadius: 20, spreadRadius: -6),
          ],
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
      ),
    );
  }
}

class _AuroraBackdrop extends StatelessWidget {
  final bool isDark;

  const _AuroraBackdrop({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AuroraPainter(isDark: isDark),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final bool isDark;

  _AuroraPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF0d1f3c).withOpacity(.4), const Color(0xFF0a3a67).withOpacity(.35), const Color(0xFF0e5fa2).withOpacity(.3)]
            : [const Color(0xFFb7d4ff).withOpacity(.35), const Color(0xFFc6e0ff).withOpacity(.3), const Color(0xFFdbe9ff).withOpacity(.25)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * .2)
      ..quadraticBezierTo(size.width * .35, size.height * .1, size.width * .5, size.height * .3)
      ..quadraticBezierTo(size.width * .7, size.height * .5, size.width, size.height * .4)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [const Color(0xFF11c5ff).withOpacity(.16), Colors.transparent]
            : [const Color(0xFF8cc7ff).withOpacity(.2), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(size.width * .7, size.height * .2), radius: size.width * .35));

    canvas.drawCircle(Offset(size.width * .7, size.height * .2), size.width * .35, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
