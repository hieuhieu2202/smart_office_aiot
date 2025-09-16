import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/racks_monitor_controller.dart';

class RackFilterSheet extends StatelessWidget {
  const RackFilterSheet({super.key, required this.controller});

  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black87,
      fontWeight: FontWeight.w600,
      fontSize: 12,
      letterSpacing: .2,
    );

    InputDecoration _dec(String hint) => InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );

    Widget _dd({
      required String label,
      required RxString value,
      required List<String> items,
    }) {
      return Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: value.value,
              items:
                  items
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (v) => value.value = v ?? items.first,
              decoration: _dec(label),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 44,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            LayoutBuilder(
              builder: (ctx, cts) {
                final isWide = cts.maxWidth > 520;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isWide ? (cts.maxWidth - 12) / 2 : cts.maxWidth,
                      child: _dd(
                        label: 'Factory',
                        value: controller.selFactory,
                        items: controller.factories,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? (cts.maxWidth - 12) / 2 : cts.maxWidth,
                      child: _dd(
                        label: 'Floor',
                        value: controller.selFloor,
                        items: controller.floors,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? (cts.maxWidth - 12) / 2 : cts.maxWidth,
                      child: _dd(
                        label: 'Room',
                        value: controller.selRoom,
                        items: controller.rooms,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? (cts.maxWidth - 12) / 2 : cts.maxWidth,
                      child: _dd(
                        label: 'Group',
                        value: controller.selGroup,
                        items: controller.groups,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? (cts.maxWidth - 12) / 2 : cts.maxWidth,
                      child: _dd(
                        label: 'Model',
                        value: controller.selModel,
                        items: controller.models,
                      ),
                    ),
                  ],
                );
              },
            ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.clearFiltersKeepFactory();
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('QUERY'),
                    onPressed: () async {
                      await controller.refresh();
                      if (context.mounted) Navigator.of(context).maybePop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
