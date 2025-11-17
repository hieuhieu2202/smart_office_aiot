import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/racks_monitor_controller.dart';

class RackFilterPanel extends StatelessWidget {
  final GroupMonitorController controller;

  const RackFilterPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Filter',
      icon: const Icon(Icons.filter_alt),
      onPressed: () => _openSlidePanel(context),
    );
  }

  Future<void> _openSlidePanel(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showGeneralDialog(
      context: context,
      barrierLabel: 'Filter',
      barrierColor: Colors.black26,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));

        return SlideTransition(
          position: offset,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              elevation: 10,
              borderRadius: BorderRadius.circular(12),
              child: _RackFilterForm(
                controller: controller,
                isDark: isDark,
                onCancel: () => Navigator.of(ctx).pop(),
                onApply: () async {
                  await controller.refresh();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RackFilterForm extends StatelessWidget {
  final GroupMonitorController controller;
  final bool isDark;
  final VoidCallback onCancel;
  final Future<void> Function() onApply;

  const _RackFilterForm({
    required this.controller,
    required this.isDark,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232F34) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.16), blurRadius: 20),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close
          Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 28),
                onPressed: onCancel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Filter',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Form các dropdown (2 cột khi đủ rộng)
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, cts) {
                final isWide = cts.maxWidth >= 240; // vừa đủ cho 2 cột nhỏ gọn
                final fieldW = isWide ? (cts.maxWidth - 12) / 2 : cts.maxWidth;

                return SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: fieldW,
                        child: _DropDownField(
                          label: 'Factory',
                          isDark: isDark,
                          value: controller.selFactory,
                          items: controller.factories,
                        ),
                      ),
                      SizedBox(
                        width: fieldW,
                        child: _DropDownField(
                          label: 'Room',
                          isDark: isDark,
                          value: controller.selRoom,
                          items: controller.rooms,
                        ),
                      ),
                      SizedBox(
                        width: fieldW,
                        child: _DropDownField(
                          label: 'Group',
                          isDark: isDark,
                          value: controller.selGroup,
                          items: controller.groups,
                        ),
                      ),
                      SizedBox(
                        width: fieldW,
                        child: _DropDownField(
                          label: 'Model',
                          isDark: isDark,
                          value: controller.selModel,
                          items: controller.models,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Buttons: Reset / Apply
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.grey[700] : Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    controller.clearFiltersKeepFactory();
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onApply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropDownField extends StatelessWidget {
  final String label;
  final bool isDark;
  final RxString value;
  final List<String> items;

  const _DropDownField({
    required this.label,
    required this.isDark,
    required this.value,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
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

    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value:
                value.value.isNotEmpty
                    ? value.value
                    : (items.isNotEmpty ? items.first : null),
            items:
                items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            isExpanded: true,
            onChanged: (v) {
              if (v == null && items.isNotEmpty) {
                value.value = items.first;
              } else if (v != null) {
                value.value = v;
              }
            },
            decoration: _dec(label),
          ),
        ],
      ),
    );
  }
}
