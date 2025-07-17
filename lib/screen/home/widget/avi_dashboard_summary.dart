import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Nếu chưa có, nhớ import GetX!
import 'package:smart_factory/screen/home/widget/avi_dashboard_detail_screen.dart';
import '../../../config/global_color.dart';
import '../../../config/global_text_style.dart';
import '../controller/avi_dashboard_controller.dart';

class PTHDashboardSummary extends StatelessWidget {
  final Map data;
  const PTHDashboardSummary({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = data['summary'] ?? {};
    final controller = Get.find<PTHDashboardController>(); // Lấy filter từ controller

    final statList = [
      {
        "label": "PASS",
        "icon": Icons.check_circle,
        "color": Colors.green,
        "value": summary['pass'] ?? 0,
        "status": "Pass"
      },
      {
        "label": "FAIL",
        "icon": Icons.cancel,
        "color": Colors.red,
        "value": summary['fail'] ?? 0,
        "status": "Fail"
      },
      {
        "label": "YR (%)",
        "icon": Icons.percent,
        "color": Colors.blue,
        "value": summary['yr'] ?? 0,
      },
      {
        "label": "FPR (%)",
        "icon": Icons.flag,
        "color": Colors.purple,
        "value": summary['fpr'] ?? 0,
      },
      {
        "label": "RR (%)",
        "icon": Icons.refresh,
        "color": Colors.orange,
        "value": summary['rr'] ?? 0,
      },
    ];

    return Card(
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: statList.map((stat) {
            final showDetail = (stat['label'] == 'PASS' || stat['label'] == 'FAIL');
            return _StatCard(
              icon: stat["icon"] as IconData,
              label: stat["label"] as String,
              value: stat["value"].toString(),
              color: stat["color"] as Color,
              isDark: isDark,
              showDetail: showDetail,
              onDetail: showDetail
                  ? () {
                // LẤY GIÁ TRỊ TỪ CONTROLLER (KHÔNG BAO GIỜ RỖNG)
                Get.to(() => PTHDashboardDetailScreen(
                  status: stat["status"] as String,
                  groupName: controller.selectedGroup.value,
                  machineName: controller.selectedMachine.value,
                  modelName: controller.selectedModel.value,
                  rangeDateTime: controller.selectedRangeDateTime.value,
                ));
              }
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final bool showDetail;
  final VoidCallback? onDetail;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.showDetail = false,
    this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          if (showDetail && onDetail != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onDetail,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, color: color, size: 16),
                    const SizedBox(width: 3),
                    Text(
                      "Chi tiết",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
