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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.blueGrey.shade50;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.blueGrey.shade100;

    final indent = 8.0 + depth * 12.0;
    final radius = BorderRadius.circular(12);
    final basePadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    final title = Text(
      node.name,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    final statusRow = Row(
      children: [
        Icon(Icons.circle, size: 8, color: Colors.green.shade400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            node.status ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );

    final leadingIcon = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Icon(node.icon ?? Icons.widgets, size: 20),
    );

    final baseDecoration = BoxDecoration(
      color: bgColor,
      borderRadius: radius,
      border: Border.all(color: borderColor),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.blueGrey.shade100.withOpacity(0.6),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
    );

    if (hasChildren) {
      return Container(
        margin: EdgeInsets.only(left: indent, bottom: 10),
        decoration: baseDecoration,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: depth == 0,
            tilePadding: basePadding,
            childrenPadding:
                EdgeInsets.only(left: 12 + depth * 4.0, right: 8, bottom: 8),
            leading: leadingIcon,
            title: title,
            subtitle: statusRow,
            shape: RoundedRectangleBorder(borderRadius: radius),
            collapsedShape: RoundedRectangleBorder(borderRadius: radius),
            collapsedBackgroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            children: _buildProjectTree(
              context: context,
              nodes: node.subProjects,
              depth: depth + 1,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(left: indent, bottom: 10),
      decoration: baseDecoration,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: leadingIcon,
        title: title,
        subtitle: statusRow,
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
