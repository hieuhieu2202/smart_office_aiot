import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:smart_factory/screen/home/widget/aoivi/avi_dashboard_screen.dart';
import 'package:smart_factory/screen/home/widget/clean_room/clean_room_screen.dart';
import 'package:smart_factory/screen/home/widget/racks_monitor/racks_monitor_screen.dart';
import 'package:smart_factory/screen/home/widget/yield_report/yield_report_screen.dart';
import 'package:smart_factory/features/te_management/presentation/views/te_management_screen.dart';
import 'package:smart_factory/features/te_management/presentation/views/te_retest_rate_screen.dart';
import 'package:smart_factory/screen/home/widget/PCBA_LINE/CLEAN_SENSOR_ES2/pcba_line_dashboard_screen.dart';
import 'package:smart_factory/screen/home/widget/nvidia_lc_switch/Dashboard/Curing_Room_Monitoring_Screen.dart';
import 'package:smart_factory/screen/home/controller/cdu_controller.dart';
import 'package:smart_factory/screen/home/widget/nvidia_lc_switch/Cdu_Monitoring/cdu_monitoring_screen.dart';

import 'package:smart_factory/screen/home/widget/smt/stencil_monitor/stencil_monitor_screen.dart';
import '../model/AppModel.dart';
import '../features/nvidia_lc_switch_kanban/presentation/pages/output_tracking_page.dart';
import '../screen/home/widget/project_list_page.dart';

final Map<String, Widget Function(AppProject)> screenBuilderMap = {
  'pth_dashboard': (project) => AOIVIDashboardScreen(),
  'racks_monitor': (project) => GroupMonitorScreen(),
  'yield_report': (project) => YieldReportScreen(
        title: project.name,
        controllerTag: 'yield_report_all',
        reportType: 'SWITCH',
      ),
  'yield_report_adapter': (project) => YieldReportScreen(
        title: project.name,
        controllerTag: 'yield_report_adapter',
        reportType: 'ADAPTER',
      ),
  'yield_report_switch': (project) => YieldReportScreen(
        title: project.name,
        controllerTag: 'yield_report_switch',
        reportType: 'SWITCH',
      ),
  'te_management': (project) => TEManagementScreen(
        title: project.name,
        controllerTag: 'te_management_default',
      ),
  'te_management_switch': (project) => TEManagementScreen(
        initialModelSerial: 'SWITCH',
        title: project.name,
        controllerTag: 'te_management_switch',
      ),
  'te_retest_rate': (project) => TERetestRateScreen(
        title: project.name,
        controllerTag: 'te_retest_rate_default',
      ),
  'te_retest_rate_switch': (project) => TERetestRateScreen(
        initialModelSerial: 'SWITCH',
        title: project.name,
        controllerTag: 'te_retest_rate_switch',
      ),
  'te_retest_rate_adapter': (project) => TERetestRateScreen(
        initialModelSerial: 'ADAPTER',
        title: project.name,
        controllerTag: 'te_retest_rate_adapter',
      ),
  'te_management_adapter': (project) => TEManagementScreen(
        initialModelSerial: 'ADAPTER',
        title: project.name,
        controllerTag: 'te_management_adapter',
      ),
  'clean_room': (project) => CleanRoomScreen(),
  'pcba_line_dashboard': (project) => PcbaLineDashboardScreen(),
  'stencil_monitor': (project) => StencilMonitorScreen(
        title: project.name,
        controllerTag: 'stencil_monitor_${((project.screenType ?? '').trim()).replaceAll(' ', '_')}',
      ),
  'curing_monitoring_dashboard': (project) => CuringRoomMonitoringScreen(),
  'output_tracking': (project) => const OutputTrackingPage(),
  'output_tracking_switch':
      (project) => const OutputTrackingPage(initialModelSerial: 'SWITCH'),
  'output_tracking_adapter':
      (project) => const OutputTrackingPage(initialModelSerial: 'ADAPTER'),
  /// HUB CDU (mặc định F16-3F; có dropdown để đổi)
  'cdu_monitoring': (project) {
    final ctrl = Get.put(
      CduController(factory: 'F16', floor: '3F'),
      tag: 'CDU-HUB',
    );
    return CduMonitoringScreen(controller: ctrl);
  },

  /// Mở trực tiếp từng tầng
  'f16_3f': (project) {
    final ctrl = Get.put(
      CduController(factory: 'F16', floor: '3F'),
      tag: 'CDU-F16-3F',
    );
    return CduMonitoringScreen(controller: ctrl);
  },
  'f17_3f': (project) {
    final ctrl = Get.put(
      CduController(factory: 'F17', floor: '3F'),
      tag: 'CDU-F17-3F',
    );
    return CduMonitoringScreen(controller: ctrl);
  },
};

Widget buildProjectScreen(AppProject project) {
  final raw = project.screenType ?? '';
  final key = raw.trim();
  print('>> DEBUG: screenType node cuối (raw): "$raw" -> key: "$key"');
  print('>> MAP contains key "$key": ${screenBuilderMap.containsKey(key)}');

  /// tra theo key đã trim
  final builder = screenBuilderMap[key];
  if (builder != null) {
    print('>> DEBUG: Đã mapping, mở dashboard đúng');
    return builder(project);
  }
  print('>> DEBUG: Không mapping được, trả về ProjectDetailPage');
  return ProjectDetailPage(project: project);
}
