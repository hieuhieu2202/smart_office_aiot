import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../model/AppModel.dart';
import 'package:smart_factory/routes/screen_factory.dart'; // <-- Import hàm mapping

class ProjectListPage extends StatelessWidget {
  final AppProject project;
  final String? title;

  const ProjectListPage({super.key, required this.project, this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Nếu không có subProjects, có thể mở dashboard hoặc hiện thông báo
    if (project.subProjects.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title ?? project.name)),
        body: Center(child: Text("Không có subproject.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? project.name),
        backgroundColor: isDark ? Colors.blueGrey : Colors.blue,
      ),
      body: ListView.builder(
        itemCount: project.subProjects.length,
        itemBuilder: (context, idx) {
          final sub = project.subProjects[idx];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: ListTile(
              leading: Icon(sub.icon ?? Icons.widgets),
              title: Text(sub.name),
              subtitle: Text("Trạng thái: ${sub.status}"),
              trailing: sub.subProjects.isNotEmpty
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: () {
                if (sub.subProjects.isNotEmpty) {
                  // Có con: tiếp tục đi sâu
                  Get.to(() => ProjectListPage(project: sub));
                } else {
                  // Node cuối cùng: mở đúng dashboard theo mapping
                  Get.to(() => buildProjectScreen(sub));
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// Trang detail dự phòng (chỉ mở nếu node cuối chưa mapping screenType)
class ProjectDetailPage extends StatelessWidget {
  final AppProject project;
  const ProjectDetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(project.name)),
      body: Center(child: Text("Chi tiết cho: ${project.name}")),
    );
  }
}
