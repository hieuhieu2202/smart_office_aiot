import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/global_color.dart';
import '../../../../config/global_text_style.dart';
import '../../../../model/AppModel.dart';
import '../../controller/racks_monitor_controller.dart';

class RacksMonitorScreen extends StatelessWidget {
  final AppProject project;
  const RacksMonitorScreen({super.key, required this.project});

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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: racks.length,
            itemBuilder: (context, idx) {
              final rack = racks[idx];
              final slots = (rack['SlotDetails'] as List?) ?? [];
              final totalPass = rack['Total_Pass'] ?? 0;
              final yr = rack['YR'] ?? 0;
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rack['RackName']?.toString() ?? 'Rack',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text('Pass: $totalPass | YR: $yr%'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: List.generate(slots.length, (i) {
                          final slot = slots[i] as Map? ?? {};
                          final status = slot['Status']?.toString() ?? '';
                          final slotName = slot['SlotName'] ?? '';
                          final slotPass = slot['Total_Pass'] ?? 0;
                          final slotFail = slot['Fail'] ?? 0;
                          final slotYr = slot['YR'] ?? 0;
                          Color color;
                          if (status == 'Pass') {
                            color = Colors.green;
                          } else if (status == 'Fail') {
                            color = Colors.red;
                          } else {
                            color = Colors.blueGrey;
                          }
                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: color),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Slot $slotName',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                Text('$slotPass/${slotPass + slotFail}'),
                                Text('$slotYr%'),
                              ],
                            ),
                          );
                        }),
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
