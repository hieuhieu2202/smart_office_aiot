import 'dart:math' as math;

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
  final LayerLink _groupLink = LayerLink();
  final LayerLink _machineLink = LayerLink();
  final LayerLink _modelLink = LayerLink();
  final GlobalKey _groupFieldKey = GlobalKey();
  final GlobalKey _machineFieldKey = GlobalKey();
  final GlobalKey _modelFieldKey = GlobalKey();
  OverlayEntry? _activeOverlay;
  String? _activeOverlayField;
  TextEditingController? _overlaySearchController;

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
    _removeActiveOverlay();
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
      _removeActiveOverlay();
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
    _removeActiveOverlay();
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
    _removeActiveOverlay();
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
    _removeActiveOverlay();
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

  BoxDecoration _tileDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark
          ? GlobalColors.inputDarkFill.withOpacity(0.24)
          : const Color(0xFFF5F6FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color:
            isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE0E4EC),
      ),
    );
  }

  void _removeActiveOverlay() {
    _overlaySearchController?.dispose();
    _overlaySearchController = null;
    _activeOverlay?.remove();
    _activeOverlay = null;
    _activeOverlayField = null;
  }

  void _showOptionsOverlay({
    required String fieldId,
    required GlobalKey fieldKey,
    required LayerLink fieldLink,
    required List<String> options,
    required String label,
    required String? selectedValue,
    required ValueChanged<String> onSelected,
    bool enableSearch = false,
  }) {
    if (!mounted || options.isEmpty) {
      _removeActiveOverlay();
      return;
    }

    final overlay = Overlay.of(context);
    final fieldContext = fieldKey.currentContext;
    if (overlay == null || fieldContext == null) return;

    final renderBox = fieldContext.findRenderObject();
    if (renderBox is! RenderBox) return;

    final fieldSize = renderBox.size;
    final fieldOffset = renderBox.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    final availableBelow =
        media.size.height - (fieldOffset.dy + fieldSize.height) - media.padding.bottom - 16;
    final availableAbove = fieldOffset.dy - media.padding.top - 16;
    const double upwardGap = 44;
    final bool canOpenUpward = availableAbove > upwardGap + 160;
    final bool openUpward = availableBelow < 180 && canOpenUpward;
    final maxUsableHeight = openUpward
        ? availableAbove - upwardGap
        : availableBelow;
    final overlayHeight = math.max(120.0, math.min(maxUsableHeight, 320.0));
    final offset = openUpward
        ? Offset(0, -overlayHeight - upwardGap)
        : Offset(0, fieldSize.height + 8);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE0E4EC);
    final dividerColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE3E7ED);
    final highlightColor =
        isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight;
    final textColor = isDark ? Colors.white : const Color(0xFF1D1D35);
    final hintColor = isDark ? Colors.white54 : Colors.black45;
    final searchFillColor = isDark
        ? GlobalColors.inputDarkFill.withOpacity(0.4)
        : const Color(0xFFF4F6FC);

    _removeActiveOverlay();

    final allOptions = List<String>.from(options);
    TextEditingController? searchController;
    if (enableSearch) {
      _overlaySearchController?.dispose();
      _overlaySearchController = TextEditingController();
      searchController = _overlaySearchController;
    } else {
      _overlaySearchController?.dispose();
      _overlaySearchController = null;
    }
    String searchQuery = '';

    final overlayEntry = OverlayEntry(
      builder: (_) {
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
              _removeActiveOverlay();
            },
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: fieldLink,
                  showWhenUnlinked: false,
                  offset: offset,
                  child: Material(
                    color: Colors.transparent,
                    child: StatefulBuilder(
                      builder: (context, setOverlayState) {
                        final query = searchQuery.trim().toLowerCase();
                        final filteredOptions = query.isEmpty
                            ? allOptions
                            : allOptions
                                .where((option) => option.toLowerCase().contains(query))
                                .toList();
                        return Container(
                          width: fieldSize.width,
                          constraints: BoxConstraints(
                            maxHeight: overlayHeight,
                            minWidth: fieldSize.width,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark ? GlobalColors.cardDarkBg : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.16),
                                blurRadius: 18,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (enableSearch)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                                  child: TextField(
                                    controller: searchController,
                                    autofocus: true,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Tìm kiếm $label',
                                      hintStyle: TextStyle(
                                        color: hintColor,
                                        fontSize: 14,
                                      ),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 12,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        size: 18,
                                        color: hintColor,
                                      ),
                                      suffixIcon: query.isNotEmpty
                                          ? IconButton(
                                              splashRadius: 18,
                                              icon: Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                                color: hintColor,
                                              ),
                                              onPressed: () {
                                                searchController?.clear();
                                                setOverlayState(() {
                                                  searchQuery = '';
                                                });
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: searchFillColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white12
                                              : const Color(0xFFD1D7E3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white12
                                              : const Color(0xFFD1D7E3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: highlightColor,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setOverlayState(() {
                                        searchQuery = value;
                                      });
                                    },
                                  ),
                                ),
                              if (enableSearch)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: dividerColor,
                                ),
                              Expanded(
                                child: filteredOptions.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Không tìm thấy kết quả phù hợp',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? Colors.white54 : Colors.black45,
                                          ),
                                        ),
                                      )
                                    : Scrollbar(
                                        thumbVisibility: filteredOptions.length > 6,
                                        child: ListView.separated(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 0, vertical: 8),
                                          itemCount: filteredOptions.length,
                                          separatorBuilder: (_, __) => Divider(
                                            height: 1,
                                            thickness: 1,
                                            indent: 16,
                                            endIndent: 16,
                                            color: dividerColor,
                                          ),
                                          itemBuilder: (context, index) {
                                            final option = filteredOptions[index];
                                            final isSelected = option == selectedValue;
                                            return Material(
                                              color: isSelected
                                                  ? highlightColor.withOpacity(0.12)
                                                  : Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  FocusScope.of(context).unfocus();
                                                  _removeActiveOverlay();
                                                  onSelected(option);
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          option,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: isSelected
                                                                ? FontWeight.w600
                                                                : FontWeight.w500,
                                                            color: isSelected
                                                                ? highlightColor
                                                                : textColor,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        Icon(
                                                          Icons.check_rounded,
                                                          size: 18,
                                                          color: highlightColor,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
    _activeOverlay = overlayEntry;
    _activeOverlayField = fieldId;
  }

  Widget _buildSelectionField({
    required String label,
    required String placeholder,
    required String? value,
    required List<String> options,
    required bool isDark,
    required bool isLoading,
    required ValueChanged<String> onSelected,
    required GlobalKey fieldKey,
    required LayerLink fieldLink,
    required String fieldId,
  }) {
    if ((isLoading || options.isEmpty) && _activeOverlayField == fieldId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeOverlayField == fieldId) {
          _removeActiveOverlay();
        }
      });
    }

    final textStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: value == null
          ? (isDark ? Colors.white54 : Colors.black45)
          : (isDark ? Colors.white : const Color(0xFF1D1D35)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF455A64),
          ),
        ),
        const SizedBox(height: 10),
        CompositedTransformTarget(
          link: fieldLink,
          child: Stack(
            children: [
              Container(
                key: fieldKey,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: _tileDecoration(isDark),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          value ?? placeholder,
                          key: ValueKey(value ?? placeholder),
                          style: textStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _activeOverlayField == fieldId ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: (isLoading || options.isEmpty)
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            if (_activeOverlayField == fieldId) {
                              _removeActiveOverlay();
                            } else {
                              _showOptionsOverlay(
                                fieldId: fieldId,
                                fieldKey: fieldKey,
                                fieldLink: fieldLink,
                                options: options,
                                label: label,
                                selectedValue: value,
                                onSelected: onSelected,
                                enableSearch: true,
                              );
                            }
                          },
                  ),
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? GlobalColors.cardDarkBg.withOpacity(0.36)
                          : Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
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
          ),
        ),
        if (!isLoading && options.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Không có dữ liệu khả dụng',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateRangeField(bool isDark) {
    final valueText = _rangeController.text.trim();
    final hasValue = valueText.isNotEmpty;
    final displayText = hasValue ? valueText : 'Chọn khoảng thời gian';
    final textColor = hasValue
        ? (isDark ? Colors.white : const Color(0xFF1D1D35))
        : (isDark ? Colors.white54 : Colors.black45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date range',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF455A64),
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: _tileDecoration(isDark),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
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
                      final format = DateFormat('yyyy/MM/dd HH:mm');
                      setState(() {
                        _dateRange = picked;
                        _rangeController.text =
                            '${format.format(picked.start)} - ${format.format(picked.end)}';
                      });
                    }
                  },
                ),
              ),
            ),
          ],
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
                _removeActiveOverlay();
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
                                _removeActiveOverlay();
                                widget.onClose();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  final groups =
                                      dashboardController.groupNames.toList();
                                  return _buildSelectionField(
                                    label: 'Group',
                                    placeholder: 'Chọn group',
                                    value: _group,
                                    options: groups,
                                    isDark: isDark,
                                    isLoading:
                                        dashboardController.isGroupLoading.value,
                                    fieldKey: _groupFieldKey,
                                    fieldLink: _groupLink,
                                    fieldId: 'group',
                                    onSelected: (val) {
                                      if (val != _group) {
                                        _onGroupChanged(val);
                                      }
                                    },
                                  );
                                }),
                                const SizedBox(height: 22),
                                Obx(() {
                                  final machines =
                                      dashboardController.machineNames.toList();
                                  return _buildSelectionField(
                                    label: 'Machine',
                                    placeholder: 'Chọn machine',
                                    value: _machine,
                                    options: machines,
                                    isDark: isDark,
                                    isLoading:
                                        dashboardController.isMachineLoading.value,
                                    fieldKey: _machineFieldKey,
                                    fieldLink: _machineLink,
                                    fieldId: 'machine',
                                    onSelected: (val) {
                                      if (val != _machine) {
                                        _onMachineChanged(val);
                                      }
                                    },
                                  );
                                }),
                                const SizedBox(height: 22),
                                Obx(() {
                                  final models =
                                      dashboardController.modelNames.toList();
                                  return _buildSelectionField(
                                    label: 'Model',
                                    placeholder: 'Chọn model',
                                    value: _model,
                                    options: models,
                                    isDark: isDark,
                                    isLoading:
                                        dashboardController.isModelLoading.value,
                                    fieldKey: _modelFieldKey,
                                    fieldLink: _modelLink,
                                    fieldId: 'model',
                                    onSelected: (val) {
                                      if (val != _model) {
                                        setState(() {
                                          _model = val;
                                        });
                                      }
                                    },
                                  );
                                }),
                                const SizedBox(height: 24),
                                _buildDateRangeField(isDark),
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
                                    _removeActiveOverlay();
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
                                          _removeActiveOverlay();
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
