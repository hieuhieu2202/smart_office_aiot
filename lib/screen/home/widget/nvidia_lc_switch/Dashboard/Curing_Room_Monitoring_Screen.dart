import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/nvidia_lc_switch_dashboard_curing_monitoring_controller.dart';
import 'Room_Canvas.dart';
import 'Right_Sidebar.dart';

class CuringRoomMonitoringScreen extends StatelessWidget {
  const CuringRoomMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<CuringMonitoringController>()
        ? Get.find<CuringMonitoringController>()
        : Get.put(CuringMonitoringController(), permanent: true);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B2433) : const Color(0xFFEFF6FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Obx(() => Text(
          'CURING ROOM MONITORING  •  WIP: ${c.wip}  •  PASS: ${c.pass}',
        )),
        backgroundColor: isDark ? const Color(0xFF081B27) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0B2433),
        elevation: 0.8,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: c.refreshAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.errorMessage.isNotEmpty) {
          return Center(child: Text(c.errorMessage.value));
        }

        // ÉP REBUILD widget con khi data đổi (tránh giữ props cũ)
        final canvasKey  = ValueKey('canvas_${c.lastFetchIso.value}');
        final sidebarKey = ValueKey('sidebar_${c.lastFetchIso.value}');

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 480;

            final room = ClipRect(
              child: RoomCanvas(
                key: canvasKey,
                sensors: c.sensorDatas,
                racks: c.rackDetails,
              ),
            );

            final sidebar = SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: RightSidebar(
                key: sidebarKey,
                passDetails: c.passDetails,
                wip: c.wip,
                pass: c.pass,
              ),
            );

            if (isNarrow) {
              return Column(
                children: [
                  Expanded(child: room),
                  const SizedBox(height: 8),
                  SizedBox(height: 360, child: sidebar),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(flex: 7, child: room),
                Flexible(flex: 3, child: sidebar),
              ],
            );
          },
        );
      }),
    );
  }
}
