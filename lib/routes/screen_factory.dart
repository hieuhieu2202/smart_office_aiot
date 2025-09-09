import 'package:flutter/cupertino.dart';
import 'package:smart_factory/screen/home/widget/aoivi/avi_dashboard_screen.dart';
import 'package:smart_factory/screen/home/widget/clean_room/clean_room_screen.dart';
import 'package:smart_factory/screen/home/widget/racks_monitor/racks_monitor_screen.dart';
import 'package:smart_factory/screen/home/widget/yield_report/yield_report_screen.dart';
import 'package:smart_factory/screen/home/widget/te_management/te_management_screen.dart';
import 'package:smart_factory/screen/home/widget/PCBA_LINE/CLEAN_SENSOR_ES2/pcba_line_dashboard_screen.dart';
import 'package:smart_factory/screen/home/widget/nvidia_lc_switch/Dashboard/Curing_Room_Monitoring_Screen.dart';


import '../model/AppModel.dart';
import '../screen/home/widget/project_list_page.dart';

final Map<String, Widget Function(AppProject)> screenBuilderMap = {
  'pth_dashboard': (project) => AOIVIDashboardScreen(),
  'racks_monitor': (project) => RacksMonitorScreen(project: project),
  'yield_report': (project) =>  YieldReportScreen(),
  'te_management': (project) => TEManagementScreen(),
  'clean_room': (project) => CleanRoomScreen(),
  'pcba_line_dashboard': (project) => PcbaLineDashboardScreen(),
  'curing_monitoring_dashboard': (project) => CuringRoomMonitoringScreen(),

};
/// Hàm trả về đúng màn hình dựa trên AppProject
Widget buildProjectScreen(AppProject project) {
  final raw = project.screenType ?? '';
  final key = raw.trim();
  print('>> DEBUG: screenType node cuối (raw): "$raw" -> key: "$key"');
  print('>> MAP contains key "$key": ${screenBuilderMap.containsKey(key)}');

  final builder = screenBuilderMap[project.screenType];
  if (builder != null) {
    print('>> DEBUG: Đã mapping, mở dashboard đúng');
    return builder(project);
  }
  print('>> DEBUG: Không mapping được, trả về ProjectDetailPage');
  return ProjectDetailPage(project: project);
}

