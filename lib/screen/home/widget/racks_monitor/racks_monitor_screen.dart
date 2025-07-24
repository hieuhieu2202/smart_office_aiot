import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/widget/racks_monitor/summary_stat_box.dart';
import '../../../../config/global_color.dart';
import '../../../../config/global_text_style.dart';
import '../../../../model/AppModel.dart';
import '../../../setting/controller/setting_controller.dart';
import '../../controller/racks_monitor_controller.dart';
import 'rack_card.dart';

class RacksMonitorScreen extends StatefulWidget {
  final AppProject project;

  const RacksMonitorScreen({super.key, required this.project});

  @override
  State<RacksMonitorScreen> createState() => _RacksMonitorScreenState();
}

class _RacksMonitorScreenState extends State<RacksMonitorScreen> with TickerProviderStateMixin {
  late final AnimationController _rackAnimationController;
  late final AnimationController _slotAnimationController;

  @override
  void initState() {
    super.initState();
    _rackAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _slotAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rackAnimationController.dispose();
    _slotAnimationController.dispose();
    super.dispose();
  }
  Color statusColor(String status) {
    switch (status) {
      case 'Pass': return Colors.green;
      case 'Fail': return Colors.red;
      case 'Testing': return Colors.blueAccent;
      case 'Waiting': return Colors.orangeAccent;
      case 'NotUsed':
      default: return Colors.grey;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'Pass': return Icons.check_circle;
      case 'Fail': return Icons.cancel;
      case 'Testing': return Icons.autorenew;
      case 'Waiting': return Icons.hourglass_bottom;
      case 'NotUsed':
      default: return Icons.remove_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RacksMonitorController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingController = Get.find<SettingController>();

    return Scaffold(
      backgroundColor: isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
      appBar: AppBar(
        title: Text('${widget.project.name}',
          style: GlobalTextStyles.bodyLarge(isDark: isDark).copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
        iconTheme: IconThemeData(color: isDark ? GlobalColors.appBarDarkText : GlobalColors.appBarLightText),
      ),
      body: Obx(() {
        final racks = controller.racks;
        return Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            children: [
              // Stats
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 26),
                decoration: BoxDecoration(
                  color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    SummaryStatBox(icon: Icons.percent, label: 'UT', value: '${controller.totalUT.toStringAsFixed(1)}%', iconColor: Colors.blue, valueColor: Colors.blue, isDark: isDark),
                    SummaryStatBox(icon: Icons.input, label: 'Input', value: '${controller.totalInput}', iconColor: Colors.teal, valueColor: Colors.teal, isDark: isDark),
                    SummaryStatBox(icon: Icons.percent, label: 'YR', value: '${controller.totalYR.toStringAsFixed(1)}%', iconColor: Colors.green, valueColor: Colors.green, isDark: isDark),
                    SummaryStatBox(icon: Icons.check_circle, label: 'Pass', value: '${controller.totalPass}', iconColor: Colors.greenAccent, valueColor: Colors.greenAccent, isDark: isDark),
                    SummaryStatBox(icon: Icons.cancel, label: 'Fail', value: '${controller.totalFail}', iconColor: Colors.redAccent, valueColor: Colors.redAccent, isDark: isDark),
                    SummaryStatBox(icon: Icons.work, label: 'WIP', value: '${controller.totalWIP}', iconColor: Colors.orangeAccent, valueColor: Colors.orangeAccent, isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Racks
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: racks.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 3 : MediaQuery.of(context).size.width > 1000 ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  itemBuilder: (context, index) {
                    final rack = racks[index];
                    final slots = (rack['SlotDetails'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                    final rackName = rack['RackName'] ?? 'Rack';
                    final model = rack['ModelName'] ?? '';
                    final totalPass = rack['Total_Pass'] ?? 0;
                    final yr = (rack['YR'] ?? 0).toDouble();
                    final ut = (rack['UT'] ?? 0).toDouble();
                    final isInactive = slots.every((e) => e['Status'] == 'NotUsed');

                    return RackCard(
                      rackName: rackName,
                      modelName: model,
                      totalPass: totalPass,
                      yr: yr,
                      ut: ut,
                      slots: slots,
                      isInactive: isInactive,
                      animation: _rackAnimationController,
                      slotAnimation: _slotAnimationController,
                      getStatusColor: statusColor,
                      getStatusIcon: statusIcon,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
