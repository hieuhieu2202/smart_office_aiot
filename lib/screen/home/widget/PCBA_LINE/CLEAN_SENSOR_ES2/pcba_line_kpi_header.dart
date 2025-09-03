import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/pcba_line_controller.dart';

class PcbaLineFilterPanel extends StatelessWidget {
  final PcbaLineDashboardController controller;
  const PcbaLineFilterPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

Future<void> showFilterDialog(
    BuildContext context,
    PcbaLineDashboardController controller,
    ) async {
  final TextEditingController machineController =
  TextEditingController(text: controller.machineName.value);

  await showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("Filter by Machine"),
        content: TextField(
          controller: machineController,
          decoration: const InputDecoration(
            labelText: "Machine name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              controller.applyMachine(machineController.text.trim());
              Navigator.of(context).pop();
            },
            child: const Text("Apply"),
          ),
        ],
      );
    },
  );
}
