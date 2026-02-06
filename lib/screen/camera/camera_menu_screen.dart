import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'camera_capture_page.dart';
import 'package:smart_factory/features/camera_test/view/camera_test_page.dart';

class CameraMenuScreen extends StatelessWidget {
  const CameraMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CAMERA MENU")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuItem(
            icon: Icons.camera_alt,
            title: "BigTab (Camera)",
            status: "Ready",
            onTap: () => Get.to(() => const CameraCapturePage()),
          ),
          _menuItem(
            icon: Icons.camera_alt,
            title: "TaiPanTab (Scan-Camera)",
            status: "Ready",
            onTap: () => Get.to(() => const CameraTestPage(autoScan: true)),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String status,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xff1E1E1E),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 38),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Trạng thái: $status",
                      style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54)
          ],
        ),
      ),
    );
  }
}
