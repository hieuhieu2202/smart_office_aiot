import 'package:flutter/material.dart';

class AppProject {
  final String name;
  final double progress;
  final String status;
  final IconData? icon;
  final String screenType;
  final List<AppProject> subProjects; // Danh sách dự án con

  AppProject({
    required this.name,
    required this.progress,
    required this.status,
    this.icon,
    required this.screenType,
    this.subProjects = const [], // Mặc định là danh sách rỗng
  });
}