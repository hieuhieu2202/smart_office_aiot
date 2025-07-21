import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/global_color.dart';
import '../../../../config/global_text_style.dart';
import '../../../../model/AppModel.dart';
import '../../controller/racks_monitor_controller.dart';

class RacksMonitorScreen extends StatelessWidget {
  final AppProject project;
  const RacksMonitorScreen({super.key, required this.project});

  Color _statusColor(num value) {
    if (value is num) {
      if (value > 50) return Colors.green;
      if (value > 30) return Colors.orange;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RacksMonitorController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
      appBar: AppBar(
        title: Text(
          project.name,
          style: GlobalTextStyles.bodyLarge(isDark: isDark).copyWith(
            color: isDark
                ? GlobalColors.appBarDarkText
                : GlobalColors.appBarLightText,
          ),
        ),
        backgroundColor:
            isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
        iconTheme: IconThemeData(
          color:
              isDark ? GlobalColors.appBarDarkText : GlobalColors.appBarLightText,
        ),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }
        final racks = controller.racks;
        if (racks.isEmpty) {
          return const Center(child: Text('No data'));
        }
        return RefreshIndicator(
          onRefresh: controller.loadRacks,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: racks.length,
            itemBuilder: (context, idx) {
              final rack = racks[idx];
              final slots = (rack['SlotDetails'] as List?) ?? [];
              final totalPass = rack['Total_Pass'] ?? 0;
              final yr = rack['YR'] ?? 0;
              return Card(
                color: isDark
                    ? GlobalColors.cardDarkBg
                    : GlobalColors.cardLightBg,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rack['RackName']?.toString() ?? 'Rack',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Pass: $totalPass | YR: $yr%'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (yr is num ? yr.clamp(0, 100) : 0) / 100,
                        minHeight: 6,
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.grey.shade300,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_statusColor(yr)),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: List.generate(slots.length, (i) {
                              final slot = slots[i] as Map? ?? {};
                              final slotName = slot['SlotName'] ?? '';
                              final slotPass = slot['Total_Pass'] ?? 0;
                              final slotFail = slot['Fail'] ?? 0;
                              final slotYr = slot['YR'] ?? 0;
                              return Container(
                                width: 80,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border:
                                      Border.all(color: _statusColor(slotYr)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Slot $slotName',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    LinearProgressIndicator(
                                      value: (slotYr is num
                                              ? slotYr.clamp(0, 100)
                                              : 0) /
                                          100,
                                      minHeight: 4,
                                      backgroundColor: isDark
                                          ? Colors.white12
                                          : Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          _statusColor(slotYr)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$slotPass/${slotPass + slotFail}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      '${slotYr.toString()}%',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
