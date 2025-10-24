import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/responsive_helper.dart';
import '../../../../../widget/animation/loading/eva_loading_view.dart';
import '../../../controller/nvidia_lc_switch_dashboard_curing_monitoring_controller.dart';
import 'room_canvas.dart';
import 'right_sidebar.dart';

class CuringRoomMonitoringScreen extends StatelessWidget {
  const CuringRoomMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<CuringMonitoringController>()
        ? Get.find<CuringMonitoringController>()
        : Get.put(CuringMonitoringController(), permanent: true);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF041521) : const Color(0xFFF3F8FC);

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF083042), const Color(0xFF0B2433)]
                  : [Colors.white, const Color(0xFFE8F1F9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color:
                isDark ? Colors.cyanAccent.withOpacity(0.25) : Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.cyanAccent, size: 22),
                onPressed: () => Get.back(),
              ),
              const Icon(Icons.heat_pump_rounded,
                  color: Colors.cyanAccent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "NVIDIA SWITCH CURING MONITOR",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black87,
                    shadows: isDark
                        ? const [Shadow(color: Colors.cyanAccent, blurRadius: 6)]
                        : null,
                  ),
                ),
              ),
              IconButton(
                onPressed: c.refreshAll,
                icon: const Icon(Icons.refresh_rounded, size: 22),
                color: isDark ? Colors.white : Colors.black87,
              ),
            ],
          ),
        ),
      ),

      // ===================== BODY =====================
      body: GetBuilder<CuringMonitoringController>(
        builder: (_) {
          if (c.isLoading.value) return const EvaLoadingView(size: 260);
          if (c.errorMessage.isNotEmpty) {
            return Center(child: Text(c.errorMessage.value));
          }

          final canvasKey = ValueKey('canvas_${c.lastFetchIso.value}');
          final sidebarKey = ValueKey('sidebar_${c.lastFetchIso.value}');

          final room = RoomCanvas(
            key: canvasKey,
            sensors: c.sensorDatas,
            racks: c.rackDetails,
          );

          final sidebar = RightSidebar(
            key: sidebarKey,
            passDetails: c.passDetails,
            wip: c.wip,
            pass: c.pass,
          );

          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;
          final isTablet = screenWidth >= 600 && screenWidth < 1000;
          final isDesktop = screenWidth >= 1000;

          // 🖥️ Desktop
          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: room),
                Expanded(flex: 3, child: sidebar),
              ],
            );
          }

          // 💻 Tablet
          if (isTablet) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(flex: 6, child: room),
                Flexible(flex: 4, child: sidebar),
              ],
            );
          }

          // 📱 Mobile
          return SafeArea(
            child: SizedBox.expand( // ✅ ép kích thước rõ ràng cho toàn body
              child: RefreshIndicator(
                onRefresh: () async => c.refreshAll(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: room,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(minHeight: 400),
                      child: sidebar,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
