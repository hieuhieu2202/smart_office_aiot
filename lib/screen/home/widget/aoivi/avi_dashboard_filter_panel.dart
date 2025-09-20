import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/global_color.dart';
import '../../controller/avi_dashboard_controller.dart';

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
  late AOIVIDashboardController dashboardController;

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
      duration: const Duration(milliseconds: 250),
    );
    _offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (widget.show) _controller.forward();

    dashboardController = Get.find<AOIVIDashboardController>();
    _syncFormWithController();
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
    if (widget.show && !oldWidget.show) {
      _controller.forward();
      _syncFormWithController(useSetState: true, refreshOptions: true);
    } else if (!widget.show && oldWidget.show) {
      _controller.reverse();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
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

  void _syncFormWithController({bool useSetState = false, bool refreshOptions = false}) {
    void assignValues() {
      _group = dashboardController.selectedGroup.value;
      _machine = dashboardController.selectedMachine.value;
      _model = dashboardController.selectedModel.value;
    }

    _parseRange(dashboardController.selectedRangeDateTime.value);

    if (useSetState && mounted) {
      setState(assignValues);
    } else {
      assignValues();
    }

    if (refreshOptions) {
      final selectedMachine = dashboardController.selectedMachine.value;
      dashboardController.loadMachines(
        dashboardController.selectedGroup.value,
        updateSelection: false,
        preferredMachine:
            selectedMachine.isNotEmpty ? selectedMachine : null,
      );
    }
  }

  Future<void> _onGroupChanged(String value) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _group = value;
      _machine = null;
      _model = null;
    });

    final machines = await dashboardController.loadMachines(
      value,
      updateSelection: false,
    );
    if (!mounted) return;

    final machineList = List<String>.from(machines);
    final modelList = dashboardController.modelNames.toList();

    setState(() {
      _machine = machineList.isNotEmpty ? machineList.first : null;
      _model = modelList.isNotEmpty ? modelList.first : null;
    });
  }

  Future<void> _onMachineChanged(String value) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _machine = value;
      _model = null;
    });

    final currentGroup =
        (_group != null && _group!.isNotEmpty)
            ? _group!
            : dashboardController.selectedGroup.value;

    final models = await dashboardController.loadModels(
      currentGroup,
      value,
      updateSelection: false,
    );
    if (!mounted) return;

    final modelList = List<String>.from(models);
    setState(() {
      _model = modelList.isNotEmpty ? modelList.first : null;
    });
  }

  Future<void> _onResetPressed() async {
    FocusScope.of(context).unfocus();
    final defaultRange = dashboardController.getDefaultRange();
    _parseRange(defaultRange);

    setState(() {
      _group = dashboardController.defaultGroup;
      _machine = null;
      _model = null;
      _rangeController.text = defaultRange;
    });

    final machines = await dashboardController.loadMachines(
      dashboardController.defaultGroup,
      updateSelection: false,
      preferredMachine: dashboardController.defaultMachine,
    );
    if (!mounted) return;

    final machineList = List<String>.from(machines);
    final models = dashboardController.modelNames.toList();
    final defaultMachine = dashboardController.defaultMachine;
    final defaultModel = dashboardController.defaultModel;

    setState(() {
      _machine = machineList.contains(defaultMachine)
          ? defaultMachine
          : (machineList.isNotEmpty ? machineList.first : null);
      _model = models.contains(defaultModel)
          ? defaultModel
          : (models.isNotEmpty ? models.first : null);
    });
  }

  InputDecoration _inputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: isDark
          ? GlobalColors.inputDarkFill.withOpacity(0.16)
          : GlobalColors.inputLightFill.withOpacity(0.18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required bool isDark,
    required bool isLoading,
    required ValueChanged<String?>? onChanged,
  }) {
    final List<String> options = List<String>.from(items);
    final String? selectedValue =
        (value != null && options.contains(value)) ? value : null;

    final dropdown = DropdownButtonFormField<String>(
      value: selectedValue,
      items: options
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: isLoading ? null : onChanged,
      isExpanded: true,
      menuMaxHeight: 320,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: _inputDecoration(label, isDark),
      hint: const Text('Chọn giá trị'),
    );

    return Stack(
      children: [
        dropdown,
        if (isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? GlobalColors.cardDarkBg.withOpacity(0.38)
                    : Colors.white.withOpacity(0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelWidth = width >= 900 ? 420.0 : width * 0.85;

    return IgnorePointer(
      ignoring: !widget.show,
      child: AnimatedOpacity(
        opacity: widget.show ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                widget.onClose();
              },
              child: Container(color: Colors.transparent),
            ),
            SlideTransition(
              position: _offset,
              child: Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  elevation: 10,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: panelWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 14,
                          offset: const Offset(-4, 2),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Bộ lọc dữ liệu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A237E),
                              ),
                            ),
                            const Spacer(),
                            Obx(() {
                              final disabled = dashboardController.isLoading.value ||
                                  dashboardController.isGroupLoading.value ||
                                  dashboardController.isMachineLoading.value ||
                                  dashboardController.isModelLoading.value;
                              return TextButton.icon(
                                onPressed: disabled ? null : _onResetPressed,
                                icon: const Icon(Icons.restart_alt_rounded, size: 20),
                                label: const Text('Đặt lại'),
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark
                                      ? Colors.white70
                                      : GlobalColors.primaryButtonLight,
                                ),
                              );
                            }),
                            IconButton(
                              icon: const Icon(Icons.close, size: 26),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                widget.onClose();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  final groups =
                                      dashboardController.groupNames.toList();
                                  return _buildDropdownField(
                                    label: 'Group',
                                    value: _group,
                                    items: groups,
                                    isDark: isDark,
                                    isLoading:
                                        dashboardController.isGroupLoading.value,
                                    onChanged: (val) {
                                      if (val != null) {
                                        _onGroupChanged(val);
                                      }
                                    },
                                  );
                                }),
                                const SizedBox(height: 16),
                                Obx(() {
                                  final machines =
                                      dashboardController.machineNames.toList();
                                  return _buildDropdownField(
                                    label: 'Machine',
                                    value: _machine,
                                    items: machines,
                                    isDark: isDark,
                                    isLoading:
                                        dashboardController.isMachineLoading.value,
                                    onChanged: (val) {
                                      if (val != null) {
                                        _onMachineChanged(val);
                                      }
                                    },
                                  );
                                }),
                                const SizedBox(height: 16),
                                Obx(() {
                                  final models =
                                      dashboardController.modelNames.toList();
                                  return _buildDropdownField(
                                    label: 'Model',
                                    value: _model,
                                    items: models,
                                    isDark: isDark,
                                    isLoading:
                                        dashboardController.isModelLoading.value,
                                    onChanged: (val) {
                                      setState(() {
                                        _model = val;
                                      });
                                    },
                                  );
                                }),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _rangeController,
                                  readOnly: true,
                                  style: const TextStyle(fontSize: 15),
                                  onTap: () async {
                                    FocusScope.of(context).unfocus();
                                    final now = DateTime.now();
                                    final picked = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(now.year - 1),
                                      lastDate: DateTime(now.year + 1),
                                      initialDateRange: _dateRange,
                                    );
                                    if (picked != null) {
                                      final format =
                                          DateFormat('yyyy/MM/dd HH:mm');
                                      setState(() {
                                        _dateRange = picked;
                                        _rangeController.text =
                                            '${format.format(picked.start)} - ${format.format(picked.end)}';
                                      });
                                    }
                                  },
                                  decoration:
                                      _inputDecoration('Date range', isDark)
                                          .copyWith(
                                    suffixIcon: const Icon(
                                      Icons.calendar_today_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Obx(() {
                          final isBusy = dashboardController.isLoading.value;
                          final isOptionsBusy =
                              dashboardController.isGroupLoading.value ||
                                  dashboardController.isMachineLoading.value ||
                                  dashboardController.isModelLoading.value;
                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark
                                        ? Colors.white70
                                        : Colors.grey[800],
                                    side: BorderSide(
                                      color: (isDark
                                              ? Colors.white24
                                              : Colors.grey.shade400)
                                          .withOpacity(0.7),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    widget.onClose();
                                  },
                                  child: const Text('Hủy'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: (isBusy || isOptionsBusy)
                                      ? null
                                      : () {
                                          FocusScope.of(context).unfocus();
                                          final range =
                                              _rangeController.text.trim();
                                          widget.onApply({
                                            'groupName': _group,
                                            'machineName': _machine,
                                            'modelName': _model,
                                            'rangeDateTime': range,
                                          });
                                        },
                                  child: isBusy
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text('Áp dụng'),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
