import 'package:flutter/cupertino.dart';

import '../model/AppModel.dart';
import '../screen/home/widget/project_list_page.dart';
import '../screen/home/widget/avi_dashboard_screen.dart';

final Map<String, Widget Function(AppProject)> screenBuilderMap = {
  'pth_dashboard': (project) => PTHDashboardScreen(),
};
/// Hàm trả về đúng màn hình dựa trên AppProject
Widget buildProjectScreen(AppProject project) {
  print('>> DEBUG: screenType node cuối: "${project.screenType}"');
  final builder = screenBuilderMap[project.screenType];
  if (builder != null) {
    print('>> DEBUG: Đã mapping, mở dashboard đúng');
    return builder(project);
  }
  print('>> DEBUG: Không mapping được, trả về ProjectDetailPage');
  return ProjectDetailPage(project: project);
}

