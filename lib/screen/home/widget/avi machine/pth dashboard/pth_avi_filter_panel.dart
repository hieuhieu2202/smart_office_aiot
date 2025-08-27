import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/pth_avi_controller.dart';

class PthAviFilterPanel extends StatelessWidget {
  final PthAviController controller;

  const PthAviFilterPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Machine dropdown
            Row(
              children: [
                const Text("Machine: "),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => DropdownButton<String>(
                    isExpanded: true,
                    value: controller.selectedMachine.value,
                    items: controller.machineNames
                        .map((name) => DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedMachine.value = value;
                        controller.loadModelNames(); // Load models khi chọn máy
                      }
                    },
                  )),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Model dropdown
            Row(
              children: [
                const Text("Model: "),
                const SizedBox(width: 18),
                Expanded(
                  child: Obx(() => DropdownButton<String>(
                    isExpanded: true,
                    value: controller.selectedModel.value,
                    items: controller.modelNames
                        .map((model) => DropdownMenuItem(
                      value: model,
                      child: Text(model),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedModel.value = value;
                      }
                    },
                  )),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Nút tải dữ liệu
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Load Data"),
                onPressed: controller.fetchDashboardData,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
