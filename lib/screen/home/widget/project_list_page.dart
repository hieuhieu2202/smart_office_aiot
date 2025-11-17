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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _buildProjectTree(
          context: context,
          nodes: project.subProjects,
          depth: 0,
        ),
      ),
    );
  }

  List<Widget> _buildProjectTree({
    required BuildContext context,
    required List<AppProject> nodes,
    required int depth,
  }) {
    return nodes
        .map(
          (node) => _buildProjectNode(
            context: context,
            node: node,
            depth: depth,
          ),
        )
        .toList();
  }

  Widget _buildProjectNode({
    required BuildContext context,
    required AppProject node,
    required int depth,
  }) {
    final hasChildren = node.subProjects.isNotEmpty;
    final key = node.screenType.trim();

    final card = Card(
      margin: EdgeInsets.only(left: depth * 12.0, bottom: 10),
      child: hasChildren
          ? ExpansionTile(
              initiallyExpanded: depth == 0,
              leading: Icon(node.icon ?? Icons.widgets),
              title: Text(node.name),
              subtitle: Text("Trạng thái: ${node.status}"),
              children: _buildProjectTree(
                context: context,
                nodes: node.subProjects,
                depth: depth + 1,
              ),
            )
          : ListTile(
              leading: Icon(node.icon ?? Icons.widgets),
              title: Text(node.name),
              subtitle: Text("Trạng thái: ${node.status}"),
              onTap: () {
                if (key.isNotEmpty) {
                  debugPrint('>> TAP "${node.name}" -> mở màn hình mapped: "$key"');
                  Get.to(() => buildProjectScreen(node));
                  return;
                }

                debugPrint('>> TAP "${node.name}" -> mở màn hình/chi tiết cuối');
                Get.to(() => buildProjectScreen(node));
              },
            ),
    );

    return card;
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
