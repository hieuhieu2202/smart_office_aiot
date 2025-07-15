import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../config/global_color.dart';
import '../controller/pth_dashboard_controller.dart';

class PTHDashboardFilterPanel extends StatefulWidget {
  final bool show;
  final void Function() onClose;
  final void Function(Map<String, dynamic> filters) onApply;
  const PTHDashboardFilterPanel({
    super.key,
    required this.show,
    required this.onClose,
    required this.onApply,
  });

  @override
  State<PTHDashboardFilterPanel> createState() => _PTHDashboardFilterPanelState();
}

class _PTHDashboardFilterPanelState extends State<PTHDashboardFilterPanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;
  late PTHDashboardController dashboardController;

  String? _group;
  String? _machine;
  String? _model;
  DateTimeRange? _dateRange;
  final TextEditingController _rangeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offset = Tween<Offset>(begin: const Offset(1,0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (widget.show) _controller.forward();

    dashboardController = Get.find<PTHDashboardController>();
    _group = dashboardController.selectedGroup.value;
    _machine = dashboardController.selectedMachine.value;
    _model = dashboardController.selectedModel.value;

    _parseRange(dashboardController.selectedRangeDateTime.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PTHDashboardFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _parseRange(String range) {
    final format = DateFormat('yyyy/MM/dd HH:mm');
    try {
      final parts = range.split(' - ');
      if (parts.length == 2) {
        final start = format.parse(parts[0]);
        final end = format.parse(parts[1]);
        _dateRange = DateTimeRange(start: start, end: end);
        _rangeController.text = range;
        return;
      }
    } catch (_) {}
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
    _rangeController.text =
        '${format.format(_dateRange!.start)} - ${format.format(_dateRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      ignoring: !widget.show,
      child: AnimatedOpacity(
        opacity: widget.show ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: SlideTransition(
          position: _offset,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: w * 0.8,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(-4, 2),
                    )
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 30),
                          onPressed: widget.onClose,
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final groups = dashboardController.groupNames;
                      return DropdownButtonFormField<String>(
                        value: _group,
                        items: groups
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _group = val;
                            _machine = null;
                            _model = null;
                          });
                          dashboardController.loadMachines(val);
                        },
                        decoration: InputDecoration(
                          labelText: 'Group',
                          filled: true,
                          fillColor: isDark
                              ? GlobalColors.inputDarkFill.withOpacity(0.16)
                              : GlobalColors.inputLightFill.withOpacity(0.18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() {
                      final machines = dashboardController.machineNames;
                      return DropdownButtonFormField<String>(
                        value: _machine,
                        items: machines
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _machine = val;
                            _model = null;
                          });
                          dashboardController.loadModels(_group ?? '', val);
                        },
                        decoration: InputDecoration(
                          labelText: 'Machine',
                          filled: true,
                          fillColor: isDark
                              ? GlobalColors.inputDarkFill.withOpacity(0.16)
                              : GlobalColors.inputLightFill.withOpacity(0.18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() {
                      final models = dashboardController.modelNames;
                      return DropdownButtonFormField<String>(
                        value: _model,
                        items: models
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _model = val;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Model',
                          filled: true,
                          fillColor: isDark
                              ? GlobalColors.inputDarkFill.withOpacity(0.16)
                              : GlobalColors.inputLightFill.withOpacity(0.18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _rangeController,
                      readOnly: true,
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 1),
                          initialDateRange: _dateRange,
                        );
                        if (picked != null) {
                          final format = DateFormat('yyyy/MM/dd HH:mm');
                          setState(() {
                            _dateRange = picked;
                            _rangeController.text =
                                '${format.format(picked.start)} - ${format.format(picked.end)}';
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Date range',
                        filled: true,
                        fillColor: isDark
                            ? GlobalColors.inputDarkFill.withOpacity(0.16)
                            : GlobalColors.inputLightFill.withOpacity(0.18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onClose,
                            child: const Text("Hủy"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onApply({
                                'groupName': _group,
                                'machineName': _machine,
                                'modelName': _model,
                                'rangeDateTime': _rangeController.text,
                              });
                            },
                            child: const Text("Áp dụng"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
