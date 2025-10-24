import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Nếu chưa có, nhớ import GetX!
import 'package:responsive_builder/responsive_builder.dart';
import 'package:smart_factory/screen/home/widget/aoivi/avi_dashboard_detail_screen.dart';
import '../../../../config/global_color.dart';
import '../../../../config/global_text_style.dart';
import '../../controller/avi_dashboard_controller.dart';

class PTHDashboardSummary extends StatelessWidget {
  final Map data;
  const PTHDashboardSummary({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = data['summary'] ?? {};
    final controller = Get.find<AOIVIDashboardController>(); // Lấy filter từ controller

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

    return ResponsiveBuilder(
      builder: (context, sizingInfo) {
        final bool isMobile =
            sizingInfo.deviceScreenType == DeviceScreenType.mobile;
        final bool isDesktop =
            sizingInfo.deviceScreenType == DeviceScreenType.desktop;
        final double horizontalPadding = isMobile ? 0 : (isDesktop ? 18 : 14);
        final double verticalPadding = isMobile ? 10 : (isDesktop ? 14 : 12);
        final double cardWidth = isMobile ? 64 : (isDesktop ? 136 : 112);
        final EdgeInsetsGeometry cardMargin = isMobile
            ? const EdgeInsets.symmetric(horizontal: 2)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
        final double wrapSpacing = isDesktop ? 22 : 18;
        final double iconSize = isMobile ? 30 : (isDesktop ? 46 : 36);
        final double labelSize = isMobile ? 13 : (isDesktop ? 16 : 14);
        final double valueSize = isMobile ? 18 : (isDesktop ? 28 : 20);

        final stats = statList.map((stat) {
          final showDetail =
              (stat['label'] == 'PASS' || stat['label'] == 'FAIL');
          return _StatCard(
            icon: stat["icon"] as IconData,
            label: stat["label"] as String,
            value: stat["value"].toString(),
            color: stat["color"] as Color,
            isDark: isDark,
            showDetail: showDetail,
            onDetail: showDetail
                ? () {
                    Get.to(() => PTHDashboardDetailScreen(
                          status: stat["status"] as String,
                          groupName: controller.selectedGroup.value,
                          machineName: controller.selectedMachine.value,
                          modelName: controller.selectedModel.value,
                          rangeDateTime:
                              controller.selectedRangeDateTime.value,
                        ));
                  }
                : null,
            width: cardWidth,
            margin: cardMargin,
            iconSize: iconSize,
            labelSize: labelSize,
            valueSize: valueSize,
          );
        }).toList();

        final Widget content = isMobile
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: stats,
              )
            : Wrap(
                alignment: WrapAlignment.spaceEvenly,
                runAlignment: WrapAlignment.center,
                spacing: wrapSpacing,
                runSpacing: wrapSpacing * 0.7,
                children: stats,
              );

        return Card(
          color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 14),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: horizontalPadding,
            ),
            child: content,
          ),
        );
      },
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
  final double width;
  final EdgeInsetsGeometry margin;
  final double iconSize;
  final double labelSize;
  final double valueSize;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.showDetail = false,
    this.onDetail,
    this.width = 64,
    this.margin = const EdgeInsets.symmetric(horizontal: 2),
    this.iconSize = 30,
    this.labelSize = 13,
    this.valueSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: margin,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: labelSize,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: valueSize,
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
