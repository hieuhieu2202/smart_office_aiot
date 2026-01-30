import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:smart_factory/screen/home/widget/aoivi/avi_dashboard_screen.dart';
import 'package:smart_factory/screen/home/widget/racks_monitor/racks_monitor_screen.dart';
import 'package:smart_factory/screen/home/widget/yield_report/yield_report_screen.dart';
import 'package:smart_factory/features/te_management/presentation/views/te_management_screen.dart';
import 'package:smart_factory/features/te_management/presentation/views/te_retest_rate_screen.dart';
import 'package:smart_factory/features/te_management/presentation/views/te_yield_rate_screen.dart';
import 'package:smart_factory/features/te_management/presentation/views/te_top10_error_code_screen.dart';
import 'package:smart_factory/features/nvidia_adapter/station_overview.dart';
import 'package:smart_factory/screen/home/widget/PCBA_LINE/CLEAN_SENSOR_ES2/pcba_line_dashboard_screen.dart';
import 'package:smart_factory/screen/home/widget/nvidia_lc_switch/Dashboard/Curing_Room_Monitoring_Screen.dart';
import 'package:smart_factory/screen/home/controller/cdu_controller.dart';
import 'package:smart_factory/screen/home/widget/nvidia_lc_switch/Cdu_Monitoring/cdu_monitoring_screen.dart';

import 'package:smart_factory/screen/home/widget/smt/stencil_monitor/stencil_monitor_screen.dart';
import '../model/AppModel.dart';
import '../features/nvidia_lc_switch_kanban/presentation/pages/output_tracking_page.dart';
import '../features/nvidia_lc_switch_kanban/presentation/pages/uph_tracking_page.dart';
import '../features/nvidia_lc_switch_kanban/presentation/pages/upd_tracking_page.dart';
import '../features/lcr_machine/presentation/pages/lcr_dashboard_page.dart';
import '../features/automation_resistor_machine/presentation/pages/automation_resistor_dashboard_page.dart';
import '../screen/home/widget/project_list_page.dart';
import '../features/clean_room/presentation/pages/clean_room_monitor_page.dart';

final Map<String, Widget Function(AppProject)> screenBuilderMap = {
  'pth_dashboard': (project) => AOIVIDashboardScreen(),
  'resistor_analysis': (project) => AutomationResistorDashboardPage(),
  'racks_monitor': (project) => GroupMonitorScreen(),
  'racks_monitor_f16': (project) => const GroupMonitorScreen(
        initialFactory: 'F16',
        initialFloor: '3F',
      ),
  'racks_monitor_f16_cto': (project) => const GroupMonitorScreen(
        initialFactory: 'F16',
        initialFloor: '3F',
        initialGroup: 'CTO',
      ),
  'racks_monitor_f16_ft': (project) => const GroupMonitorScreen(
        initialFactory: 'F16',
        initialFloor: '3F',
        initialGroup: 'FT',
      ),
  'racks_monitor_f16_jtag': (project) => const GroupMonitorScreen(
        initialFactory: 'F16',
        initialFloor: '3F',
        initialGroup: 'J_TAG',
      ),
  'racks_monitor_f17': (project) => const GroupMonitorScreen(
        initialFactory: 'F17',
        initialFloor: '3F',
      ),
  'racks_monitor_f17_cto': (project) => const GroupMonitorScreen(
        initialFactory: 'F17',
        initialFloor: '3F',
        initialGroup: 'CTO',
      ),
  'racks_monitor_f17_ft': (project) => const GroupMonitorScreen(
        initialFactory: 'F17',
        initialFloor: '3F',
        initialGroup: 'FT',
      ),
  'racks_monitor_f17_jtag': (project) => const GroupMonitorScreen(
        initialFactory: 'F17',
        initialFloor: '3F',
        initialGroup: 'J_TAG',
      ),
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
  'te_yield_rate': (project) => TEYieldRateScreen(
        title: project.name,
        controllerTag: 'te_yield_rate_default',
      ),
  'te_yield_rate_switch': (project) => TEYieldRateScreen(
        initialModelSerial: 'SWITCH',
        title: project.name,
        controllerTag: 'te_yield_rate_switch',
      ),
  'te_yield_rate_adapter': (project) => TEYieldRateScreen(
        initialModelSerial: 'ADAPTER',
        title: project.name,
        controllerTag: 'te_yield_rate_adapter',
      ),
  'te_top10_error_code': (project) => TETop10ErrorCodeScreen(
        title: project.name,
        controllerTag: 'te_top10_error_code_default',
      ),
  'te_top10_error_code_adapter': (project) => TETop10ErrorCodeScreen(
        initialModelSerial: 'ADAPTER',
        title: project.name,
        controllerTag: 'te_top10_error_code_adapter',
      ),
  'te_top10_error_code_switch': (project) => TETop10ErrorCodeScreen(
        initialModelSerial: 'SWITCH',
        title: project.name,
        controllerTag: 'te_top10_error_code_switch',
      ),
  'te_management_adapter': (project) => TEManagementScreen(
        initialModelSerial: 'ADAPTER',
        title: project.name,
        controllerTag: 'te_management_adapter',
      ),
  'pcba_line_dashboard': (project) => PcbaLineDashboardScreen(),
  'stencil_monitor': (project) => StencilMonitorScreen(
        title: project.name,
        controllerTag: 'stencil_monitor_${((project.screenType ?? '').trim()).replaceAll(' ', '_')}',
      ),
  'curing_monitoring_dashboard': (project) => CuringRoomMonitoringScreen(),
  'station_overview': (project) => StationOverviewPage(),
  'output_tracking': (project) => const OutputTrackingPage(),
  'lcr_machine_dashboard': (project) => const LcrDashboardPage(),
  'output_tracking_switch':
      (project) => const OutputTrackingPage(initialModelSerial: 'SWITCH'),
  'output_tracking_adapter':
      (project) => const OutputTrackingPage(initialModelSerial: 'ADAPTER'),
  'uph_tracking': (project) => const UphTrackingPage(),
  'uph_tracking_switch':
      (project) => const UphTrackingPage(initialModelSerial: 'SWITCH'),
  'uph_tracking_adapter':
      (project) => const UphTrackingPage(initialModelSerial: 'ADAPTER'),
  'upd_tracking': (project) => const UpdTrackingPage(),
  'upd_tracking_switch':
      (project) => const UpdTrackingPage(initialModelSerial: 'SWITCH'),
  'upd_tracking_adapter':
      (project) => const UpdTrackingPage(initialModelSerial: 'ADAPTER'),
  /// HUB CDU (mặc định F16-3F; có dropdown để đổi)
  'cdu_monitoring': (project) {
    final ctrl = Get.put(
      CduController(factory: 'F16', floor: '3F'),
      tag: 'CDU-HUB',
    );
    return CduMonitoringScreen(controller: ctrl);
  },

  'clean_room': (project) => const CleanRoomMonitorPage(),

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
