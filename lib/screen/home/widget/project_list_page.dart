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
            child: InkWell(
              onTap: () {
                final key = (sub.screenType ?? '').trim();
                final hasChildren = sub.subProjects.isNotEmpty;

                if (hasChildren) {
                  debugPrint(
                    '>> TAP "${sub.name}" -> vào danh sách con (${sub.subProjects.length})',
                  );
                  Get.to(() => ProjectListPage(project: sub));
                  return;
                }

                if (key.isNotEmpty) {
                  debugPrint('>> TAP "${sub.name}" -> mở màn hình mapped: "$key"');
                  Get.to(() => buildProjectScreen(sub));
                  return;
                }

                debugPrint('>> TAP "${sub.name}" -> mở màn hình/chi tiết cuối');
                Get.to(() => buildProjectScreen(sub));
              },
              onDoubleTap: () {
                final key = (sub.screenType ?? '').trim();
                if (key.isEmpty) return;
                debugPrint(
                  '>> DOUBLE TAP "${sub.name}" -> mở trực tiếp màn hình mapped: "$key"',
                );
                Get.to(() => buildProjectScreen(sub));
              },
              onLongPress: () {
                final key = (sub.screenType ?? '').trim();
                if (key.isNotEmpty) {
                  debugPrint(
                    '>> LONG PRESS "${sub.name}" -> mở trực tiếp màn hình mapped: "$key"',
                  );
                  Get.to(() => buildProjectScreen(sub));
                  return;
                }

                if (sub.subProjects.isEmpty) return;
                debugPrint(
                  '>> LONG PRESS "${sub.name}" -> mở danh sách con (${sub.subProjects.length})',
                );
                Get.to(() => ProjectListPage(project: sub));
              },
              child: ListTile(
                leading: Icon(sub.icon ?? Icons.widgets),
                title: Text(sub.name),
                subtitle: Text("Trạng thái: ${sub.status}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sub.screenType?.trim().isNotEmpty == true)
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded),
                        tooltip: 'Mở trực tiếp màn hình này',
                        onPressed: () {
                          final key = (sub.screenType ?? '').trim();
                          debugPrint(
                            '>> TAP ICON "${sub.name}" -> mở trực tiếp màn hình mapped: "$key"',
                          );
                          Get.to(() => buildProjectScreen(sub));
                        },
                      ),
                    if (sub.subProjects.isNotEmpty)
                      const Icon(Icons.chevron_right),
                  ],
                ),
              ),
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
