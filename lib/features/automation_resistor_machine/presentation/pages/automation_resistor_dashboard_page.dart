import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

import '../controllers/automation_resistor_dashboard_controller.dart';
import '../../domain/entities/resistor_machine_entities.dart';
import '../viewmodels/resistor_dashboard_view_state.dart';
import '../widgets/resistor_combo_chart.dart';
import '../widgets/resistor_fail_distribution_chart.dart';
import '../widgets/resistor_filters_bar.dart';
import '../widgets/resistor_summary_tile.dart';

class AutomationResistorDashboardPage extends StatefulWidget {
  const AutomationResistorDashboardPage({super.key});

  @override
  State<AutomationResistorDashboardPage> createState() =>
      _AutomationResistorDashboardPageState();
}

class _AutomationResistorDashboardPageState
    extends State<AutomationResistorDashboardPage> {
  late final AutomationResistorDashboardController controller;
  late final TextEditingController searchController;
  late final FocusNode searchFocusNode;
  final GlobalKey _filterButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      AutomationResistorDashboardController(),
      tag: 'AUTOMATION_RESISTOR_DASHBOARD',
    );
    searchController = TextEditingController();
    searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF010A1B),
        body: SafeArea(
          child: MediaQuery.removeViewInsets(
            removeBottom: true,
            context: context,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF001B3A), Color(0xFF020B1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(context),
                  const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.cyanAccent,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                    tabs: [
                      Tab(text: 'DASHBOARD'),
                      Tab(text: 'SN ANALYSIS'),
                    ],
                  ),
                  Expanded(
                    child: SizedBox.expand(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          LayoutBuilder(
                            builder: (context, _) {
                              return SizedBox.expand(
                                child: Obx(() {
                                  if (controller.isLoading.value) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.cyanAccent,
                                      ),
                                    );
                                  }
                                  return _DashboardBody(controller: controller);
                                }),
                              );
                            },
                          ),
                          LayoutBuilder(
                            builder: (context, _) {
                              return SizedBox.expand(
                                child: _SnAnalysisTab(
                                  controller: controller,
                                  searchController: searchController,
                                  searchFocusNode: searchFocusNode,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;
          final tabController = DefaultTabController.of(context);
          if (tabController == null) {
            return const SizedBox.shrink();
          }

          return AnimatedBuilder(
            animation: tabController,
            builder: (context, _) {
              final bool showFilters = tabController.index == 0;
              final String title = tabController.index == 0
                  ? 'RESISTOR MACHINE '
                  : 'SERIAL NUMBER ANALYSIS';

              return Column(
                crossAxisAlignment: isCompact
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _handleBack,
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                      if (showFilters) ...[
                        const SizedBox(width: 12),
                        _buildFilterButton(() => _showFiltersSheet(context)),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          if (tabController.index == 0) {
                            controller.loadDashboard();
                            controller.loadStatus();
                          } else {
                            searchController.clear();
                            controller.clearSerialSearch();
                            controller.clearSelectedSerial();
                          }
                        },
                        icon:
                            const Icon(Icons.refresh, color: Colors.cyanAccent),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  Widget _buildFilterButton(VoidCallback onPressed) {
    return OutlinedButton.icon(
      key: _filterButtonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.cyanAccent,
        side: const BorderSide(color: Colors.cyanAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      icon: const Icon(Icons.tune, size: 18),
      label: const Text(
        'FILTER',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _showFiltersSheet(BuildContext context) async {
    final renderBox =
        _filterButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayState = Overlay.of(context);
    final overlay = overlayState?.context.findRenderObject() as RenderBox?;
    final overlaySize = overlay?.size ?? MediaQuery.of(context).size;
    Offset? buttonOffset;
    Size buttonSize = Size.zero;

    if (renderBox != null && overlay != null) {
      buttonOffset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
      buttonSize = renderBox.size;
    }

    final mediaQuery = MediaQuery.of(context);
    final double screenWidth = overlaySize.width;
    final bool narrowLayout = screenWidth < 720;
    final double baseTop = mediaQuery.padding.top + 72;
    final double buttonTop = buttonOffset?.dy ?? baseTop;
    final double topOffset = buttonTop + (buttonSize.height == 0 ? 0 : buttonSize.height) + 12;
    final double computedRight = overlaySize.width -
        ((buttonOffset?.dx ?? overlaySize.width) + buttonSize.width);
    final double rightInset = computedRight < 24 ? 24 : computedRight;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filters',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final bottomInset = MediaQuery.of(dialogContext).viewInsets.bottom;

        return SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  Positioned(
                    top: narrowLayout
                        ? MediaQuery.of(dialogContext).padding.top + 24
                        : topOffset,
                    left: narrowLayout ? 24 : null,
                    right: narrowLayout ? 24 : rightInset,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {},
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomInset + 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _FilterDialogContent(
                            onClose: () => Navigator.of(dialogContext).pop(),
                            controller: controller,
                            onPickDate: (currentRange) =>
                                _pickDateTimeRange(dialogContext, currentRange),
                            onQuery: (
                              range,
                              machine,
                              status,
                            ) {
                              controller.applyFilters(
                                range: range,
                                machine: machine,
                                status: status,
                              );
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
    );
  }

  Future<DateTimeRange?> _pickDateTimeRange(
    BuildContext context,
    DateTimeRange initialRange,
  ) async {
    final pickedDates = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Date',
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              surface: Color(0xFF04102A),
              onSurface: Colors.white,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 840,
                maxHeight: 640,
              ),
              child: child!,
            ),
          ),
        );
      },
    );

    if (pickedDates == null) {
      return null;
    }

    return showDialog<DateTimeRange>(
      context: context,
      builder: (context) {
        final hours = List<int>.generate(24, (index) => index);
        const minutes = [0, 30];

        int startHour = initialRange.start.hour;
        int startMinute = initialRange.start.minute >= 30 ? 30 : 0;
        int endHour = initialRange.end.hour;
        int endMinute = initialRange.end.minute >= 30 ? 30 : 0;

        if (startHour == 0 &&
            startMinute == 0 &&
            endHour == 0 &&
            endMinute == 0) {
          startHour = 7;
          startMinute = 30;
          endHour = 19;
          endMinute = 30;
        }

        DateTime _buildStartDate() => DateTime(
              pickedDates.start.year,
              pickedDates.start.month,
              pickedDates.start.day,
              startHour,
              startMinute,
            );

        DateTime _buildEndDate() => DateTime(
              pickedDates.end.year,
              pickedDates.end.month,
              pickedDates.end.day,
              endHour,
              endMinute,
            );

        String previewText() {
          final format = DateFormat('yyyy-MM-dd HH:mm');
          return '${format.format(_buildStartDate())} → ${format.format(_buildEndDate())}';
        }

        void applySelection() {
          final start = _buildStartDate();
          final end = _buildEndDate();
          final normalizedEnd = end.isBefore(start) ? start : end;
          Navigator.of(context).pop(
            DateTimeRange(start: start, end: normalizedEnd),
          );
        }

        Widget buildDropdown({
          required String label,
          required int value,
          required List<int> items,
          required ValueChanged<int?> onChanged,
        }) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF052043),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                ),
                child: DropdownButton<int>(
                  value: value,
                  dropdownColor: const Color(0xFF03132D),
                  underline: const SizedBox(),
                  iconEnabledColor: Colors.cyanAccent,
                  style: const TextStyle(color: Colors.white),
                  items: items
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item,
                          child: Text(item.toString().padLeft(2, '0')),
                        ),
                      )
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ],
          );
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF03132D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Select Time Range',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: buildDropdown(
                                    label: 'Hour',
                                    value: startHour,
                                    items: hours,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => startHour = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: buildDropdown(
                                    label: 'Minute',
                                    value: startMinute,
                                    items: minutes,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => startMinute = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'End',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: buildDropdown(
                                    label: 'Hour',
                                    value: endHour,
                                    items: hours,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => endHour = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: buildDropdown(
                                    label: 'Minute',
                                    value: endMinute,
                                    items: minutes,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => endMinute = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF052043),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.cyanAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            previewText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: applySelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('APPLY'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FilterDialogContent extends StatefulWidget {
  const _FilterDialogContent({
    required this.controller,
    required this.onClose,
    required this.onPickDate,
    required this.onQuery,
  });

  final AutomationResistorDashboardController controller;
  final VoidCallback onClose;
  final Future<DateTimeRange?> Function(DateTimeRange currentRange) onPickDate;
  final void Function(DateTimeRange range, String machine, String status) onQuery;

  @override
  State<_FilterDialogContent> createState() => _FilterDialogContentState();
}

class _FilterDialogContentState extends State<_FilterDialogContent> {
  late DateTimeRange _range;
  late String _machine;
  late String _shift;
  late String _status;

  @override
  void initState() {
    super.initState();
    final controller = widget.controller;
    _range = controller.selectedRange.value;
    _machine = controller.selectedMachine.value;
    _shift = controller.selectedShift.value;
    _status = controller.selectedStatus.value;
  }

  Future<void> _selectDate() async {
    final picked = await widget.onPickDate(_range);
    if (picked != null) {
      setState(() {
        _range = picked;
        _shift = widget.controller.inferShiftFromRange(picked);
      });
    }
  }

  void _changeShift(String value) {
    setState(() {
      _shift = value;
      _range = widget.controller.rangeForShift(_range, value);
    });
  }

  void _resetFilters() {
    setState(() {
      _machine = 'ALL';
      _status = 'ALL';
      _shift = 'D';
      _range = widget.controller.rangeForShift(_range, 'D');
    });
  }

  void _submit() {
    final normalizedShift = widget.controller.inferShiftFromRange(_range);
    if (normalizedShift != _shift) {
      setState(() {
        _shift = normalizedShift;
      });
    }
    widget.onQuery(_range, _machine, _status);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF021026),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'FILTER',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white60),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white12, thickness: 1, height: 24),
              const SizedBox(height: 8),
              const Text(
                'Refine your query',
                style: TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                final machines =
                    widget.controller.machineNames.toList(growable: false);
                var machineSelection = _machine;
                if (!machines.contains(machineSelection)) {
                  machineSelection = machines.isNotEmpty ? machines.first : 'ALL';
                  if (machineSelection != _machine) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        _machine = machineSelection;
                      });
                    });
                  }
                }

                return ResistorFiltersBar(
                  machineOptions: machines,
                  selectedMachine: machineSelection,
                  onMachineChanged: (value) {
                    setState(() {
                      _machine = value;
                    });
                  },
                  shiftOptions: const ['D', 'N'],
                  selectedShift: _shift,
                  onShiftChanged: _changeShift,
                  statusOptions: const ['ALL', 'PASS', 'FAIL'],
                  selectedStatus: _status,
                  onStatusChanged: (value) {
                    setState(() {
                      _status = value;
                    });
                  },
                  dateRange: _range,
                  onSelectDate: () async {
                    await _selectDate();
                  },
                );
              }),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        backgroundColor: const Color(0xFF031C3A),
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _resetFilters,
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text(
                        'QUERY',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.controller});

  final AutomationResistorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final view = controller.dashboardView.value;
    if (view == null) {
      return Center(
        child: Text(
          controller.error.value ?? 'Unable to load dashboard data',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return _DesktopLayout(view: view, controller: controller);
        }
        if (constraints.maxWidth >= 800) {
          return _TabletLayout(view: view, controller: controller);
        }
        return _MobileLayout(view: view, controller: controller);
      },
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.view, required this.controller});

  final ResistorDashboardViewState view;
  final AutomationResistorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummarySection(view: view),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: _DashboardPanel(
                    child: ResistorFailDistributionChart(
                      slices: view.failDistributionSlices,
                      total: view.failTotal,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Expanded(
                        child: Obx(() {
                          final alignToShift = !controller.isMultiDayRange.value;
                          return ResistorComboChart(
                            title: 'YIELD RATE AND OUTPUT',
                            series: view.sectionSeries,
                            alignToShiftWindows: alignToShift,
                            startSection: controller.startSection.value,
                            shiftStartTime: controller.shiftStartTime.value,
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ResistorComboChart(
                          title: 'MACHINE DISTRIBUTION',
                          series: view.machineSeries,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({required this.view, required this.controller});

  final ResistorDashboardViewState view;
  final AutomationResistorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummarySection(view: view),
            const SizedBox(height: 20),
            SizedBox(
              height: 360,
              child: _DashboardPanel(
                child: ResistorFailDistributionChart(
                  slices: view.failDistributionSlices,
                  total: view.failTotal,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 420,
              child: Obx(() {
                final alignToShift = !controller.isMultiDayRange.value;
                return ResistorComboChart(
                  title: 'YIELD RATE AND OUTPUT',
                  series: view.sectionSeries,
                  alignToShiftWindows: alignToShift,
                  startSection: controller.startSection.value,
                  shiftStartTime: controller.shiftStartTime.value,
                );
              }),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 420,
              child: ResistorComboChart(
                title: 'MACHINE DISTRIBUTION',
                series: view.machineSeries,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.view, required this.controller});

  final ResistorDashboardViewState view;
  final AutomationResistorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummarySection(view: view),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: _DashboardPanel(
            child: ResistorFailDistributionChart(
              slices: view.failDistributionSlices,
              total: view.failTotal,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 340,
          child: Obx(() {
            final alignToShift = !controller.isMultiDayRange.value;
            return ResistorComboChart(
              title: 'YIELD RATE AND OUTPUT',
              series: view.sectionSeries,
              alignToShiftWindows: alignToShift,
              startSection: controller.startSection.value,
              shiftStartTime: controller.shiftStartTime.value,
            );
          }),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 340,
          child: ResistorComboChart(
            title: 'MACHINE DISTRIBUTION',
            series: view.machineSeries,
          ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.view});

  final ResistorDashboardViewState view;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = 4;
        if (width < 520) {
          columns = 1;
        } else if (width < 820) {
          columns = 2;
        } else if (width < 1100) {
          columns = 3;
        }

        final spacing = 18.0;
        final itemWidth = (width - spacing * (columns - 1)) / columns;
        final tileHeight = 130.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: view.summaryTiles
              .map(
                (tile) => SizedBox(
                  width: itemWidth,
                  height: tileHeight,
                  child: ResistorSummaryTile(data: tile),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF041B3E), Color(0xFF020B23)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _SnAnalysisTab extends StatefulWidget {
  const _SnAnalysisTab({
    required this.controller,
    required this.searchController,
    required this.searchFocusNode,
  });

  final AutomationResistorDashboardController controller;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  @override
  State<_SnAnalysisTab> createState() => _SnAnalysisTabState();
}

class _SnAnalysisTabState extends State<_SnAnalysisTab>
    with AutomaticKeepAliveClientMixin {
  _SnAnalysisTabState();

  final NumberFormat _numberFormat = NumberFormat('0.###');
  String _lastQuery = '';
  bool _isSearchFocused = false;

  AutomationResistorDashboardController get controller => widget.controller;

  late final ScrollController _searchResultsController;
  late final ScrollController _addressListController;
  late final ScrollController _gridHorizontalController;
  late final ScrollController _gridVerticalController;
  late final ScrollController _productInfoScrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchResultsController = ScrollController();
    _addressListController = ScrollController();
    _gridHorizontalController = ScrollController();
    _gridVerticalController = ScrollController();
    _productInfoScrollController = ScrollController();
    widget.searchFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.searchFocusNode.removeListener(_handleFocusChange);
    _searchResultsController.dispose();
    _addressListController.dispose();
    _gridHorizontalController.dispose();
    _gridVerticalController.dispose();
    _productInfoScrollController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isSearchFocused = widget.searchFocusNode.hasFocus;
    });
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    if (query.length < 3) {
      controller.clearSerialSearch();
      _lastQuery = '';
      return;
    }
    if (query == _lastQuery) return;
    _lastQuery = query;
    controller.searchSerial(query);
  }

  void _onSerialTap(ResistorMachineSerialMatch match) {
    widget.searchController.text = match.serialNumber;
    controller.selectSerial(match);
    widget.searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool hasFiniteHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final bool hasFiniteWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite;
        final Size screenSize = MediaQuery.sizeOf(context);
        final double constrainedHeight =
            hasFiniteHeight ? constraints.maxHeight : screenSize.height;
        final double constrainedWidth =
            hasFiniteWidth ? constraints.maxWidth : screenSize.width;

        final Widget analysisContent = _buildAnalysisContent(
          constraints: constraints,
          hasFiniteHeight: hasFiniteHeight,
        );

        if (hasFiniteHeight) {
          return SizedBox(
            width: constrainedWidth,
            height: constrainedHeight,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constrainedHeight,
                    minWidth: constrainedWidth,
                  ),
                  child: analysisContent,
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: constrainedWidth,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constrainedWidth),
                child: analysisContent,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisContent({
    required BoxConstraints constraints,
    required bool hasFiniteHeight,
  }) {
    return Obx(() {
      final matches = controller.serialMatches;
      final isSearching = controller.isSearchingSerial.value;
      final isLoadingRecord = controller.isLoadingRecord.value;
      final record = controller.selectedRecord.value;
      final tests = controller.recordTestResults;
      final selectedTest = controller.selectedTestResult.value;
      final selectedSerial = controller.selectedSerial.value;

      final bool isWide = constraints.maxWidth >= 1100;
      final EdgeInsets padding = isWide
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
          : const EdgeInsets.all(16);

      final double? availableHeight = hasFiniteHeight
          ? math.max(0, constraints.maxHeight - padding.vertical)
          : null;

      final Widget content = isWide
          ? _buildWideLayout(
              maxHeight: availableHeight,
              matches: matches,
              isSearching: isSearching,
              isLoadingRecord: isLoadingRecord,
              record: record,
              tests: tests,
              selectedTest: selectedTest,
              selectedSerial: selectedSerial,
            )
          : _buildStackedLayout(
              maxHeight: availableHeight,
              matches: matches,
              isSearching: isSearching,
              isLoadingRecord: isLoadingRecord,
              record: record,
              tests: tests,
              selectedTest: selectedTest,
              selectedSerial: selectedSerial,
            );

      return Padding(
        padding: padding,
        child: content,
      );
    });
  }

  Widget _buildWideLayout({
    required double? maxHeight,
    required List<ResistorMachineSerialMatch> matches,
    required bool isSearching,
    required bool isLoadingRecord,
    required ResistorMachineRecord? record,
    required List<ResistorMachineTestResult> tests,
    required ResistorMachineTestResult? selectedTest,
    required ResistorMachineSerialMatch? selectedSerial,
  }) {
    final bool hasMaxHeight =
        maxHeight != null && maxHeight.isFinite && maxHeight > 0;
    final bool fillHeight = hasMaxHeight;

    final row = Row(
      crossAxisAlignment:
          fillHeight ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 360,
          child: _buildSerialAnalysisCard(
            matches: matches,
            isSearching: isSearching,
            isLoadingRecord: isLoadingRecord,
            tests: tests,
            selectedTest: selectedTest,
            selectedSerial: selectedSerial,
            fillHeight: fillHeight,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildDetailColumn(
            record: record,
            selectedTest: selectedTest,
            isLoadingRecord: isLoadingRecord,
            fillHeight: fillHeight,
          ),
        ),
      ],
    );

    if (fillHeight) {
      return SizedBox(
        height: maxHeight!,
        child: row,
      );
    }

    return row;
  }

  Widget _buildStackedLayout({
    required double? maxHeight,
    required List<ResistorMachineSerialMatch> matches,
    required bool isSearching,
    required bool isLoadingRecord,
    required ResistorMachineRecord? record,
    required List<ResistorMachineTestResult> tests,
    required ResistorMachineTestResult? selectedTest,
    required ResistorMachineSerialMatch? selectedSerial,
  }) {
    final double minHeight =
        (maxHeight != null && maxHeight.isFinite && maxHeight > 0)
            ? maxHeight!
            : 0;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSerialAnalysisCard(
            matches: matches,
            isSearching: isSearching,
            isLoadingRecord: isLoadingRecord,
            tests: tests,
            selectedTest: selectedTest,
            selectedSerial: selectedSerial,
            fillHeight: false,
          ),
          const SizedBox(height: 20),
          _buildDetailColumn(
            record: record,
            selectedTest: selectedTest,
            isLoadingRecord: isLoadingRecord,
            fillHeight: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSerialAnalysisCard({
    required List<ResistorMachineSerialMatch> matches,
    required bool isSearching,
    required bool isLoadingRecord,
    required List<ResistorMachineTestResult> tests,
    required ResistorMachineTestResult? selectedTest,
    required ResistorMachineSerialMatch? selectedSerial,
    required bool fillHeight,
  }) {
    final List<Widget> children = [
      ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFF00FFFF), // xanh sáng
            Color(0xFFADFF2F), // xanh lá vàng nhạt
            Color(0xFFFFD700), // vàng tươi
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          'Serial Number Analysis'
              '${selectedSerial != null ? '\n${selectedSerial.serialNumber}' : ''}',
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Colors.white, // bị ShaderMask override
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            fontSize: 16.5,
            height: 1.3,
          ),
        ),
      ),
      const SizedBox(height: 16),
      _buildSearchField(),
    ];

    final bool showSearchResults =
        (matches.isNotEmpty || isSearching) &&
        (_isSearchFocused || widget.searchController.text.trim().length >= 3);

    if (showSearchResults) {
      children
        ..add(const SizedBox(height: 8))
        ..add(_buildSearchResults(matches, isSearching));
    }

    children.add(const SizedBox(height: 16));

    if (fillHeight) {
      children.add(
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAddressHeaderRow(),
              const SizedBox(height: 12),
              Expanded(
                child: _buildAddressTable(
                  isLoadingRecord: isLoadingRecord,
                  selectedSerial: selectedSerial,
                  tests: tests,
                  selectedTest: selectedTest,
                  constrainHeight: false,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      children
        ..add(_buildAddressHeaderRow())
        ..add(const SizedBox(height: 12))
        ..add(
          _buildAddressTable(
            isLoadingRecord: isLoadingRecord,
            selectedSerial: selectedSerial,
            tests: tests,
            selectedTest: selectedTest,
            constrainHeight: true,
          ),
        );
    }

    return Container(
      height: fillHeight ? double.infinity : null,
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: widget.searchController,
      focusNode: widget.searchFocusNode,
      onChanged: _onSearchChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        hintText: 'Serial Number Search',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    List<ResistorMachineSerialMatch> matches,
    bool isSearching,
  ) {
    final bool hasResults = matches.isNotEmpty;

    Widget child;
    if (!hasResults) {
      if (isSearching) {
        child = const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          ),
        );
      } else {
        child = const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No serial numbers match your search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
        );
      }
    } else {
      child = ListView.separated(
        controller: _searchResultsController,
        primary: false,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: matches.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: Color(0x22FFFFFF),
        ),
        itemBuilder: (context, index) {
          final match = matches[index];
          return InkWell(
            onTap: () => _onSerialTap(match),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      match.serialNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E2B4F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${match.sequence}',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontFamily: 'SourceCodePro',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF04142D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      constraints: const BoxConstraints(maxHeight: 280),
      child: hasResults
          ? Scrollbar(
              controller: _searchResultsController,
              thumbVisibility: true,
              child: child,
            )
          : child,
    );
  }

  Widget _buildAddressHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF003366), // xanh navy đậm
            Color(0xFF005C97), // xanh lam trung
            Color(0xFF00A8C8), // xanh ngọc sáng
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 52,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              'Location',
              style: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Status',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'Error',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTable({
    required bool isLoadingRecord,
    required ResistorMachineSerialMatch? selectedSerial,
    required List<ResistorMachineTestResult> tests,
    required ResistorMachineTestResult? selectedTest,
    required bool constrainHeight,
  }) {
    Widget content;
    if (isLoadingRecord) {
      content = _buildCardPlaceholder(
        message: 'Loading serial details…',
        showLoader: true,
      );
    } else if (selectedSerial == null) {
      content = _buildCardPlaceholder(
        message: 'Select a serial number to view the test positions.',
      );
    } else if (tests.isEmpty) {
      content = _buildCardPlaceholder(
        message: 'No test data available for this serial number.',
      );
    } else {
      content = _buildAddressList(tests, selectedTest);
    }

    if (constrainHeight) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: content,
      );
    }
    return content;
  }

  Widget _buildAddressList(
    List<ResistorMachineTestResult> tests,
    ResistorMachineTestResult? selectedTest,
  ) {
    return Scrollbar(
      controller: _addressListController,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _addressListController,
        primary: false,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: tests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final result = tests[index];
          final bool isSelected = selectedTest?.address == result.address;
          return _buildAddressRow(result, isSelected);
        },
      ),
    );
  }

  Widget _buildAddressRow(
    ResistorMachineTestResult result,
    bool isSelected,
  ) {
    final bool hasOpen = result.details.any(
      (detail) => detail.measurementValue > detail.highSampleValue,
    );
    final bool hasShort = result.details.any(
      (detail) => detail.measurementValue < detail.lowSampleValue,
    );

    final Color borderColor = isSelected
        ? Colors.cyanAccent.withOpacity(0.5)
        : Colors.white12;
    final Color background = isSelected
        ? Colors.cyanAccent.withOpacity(0.12)
        : Colors.white.withOpacity(0.02);

    return InkWell(
      onTap: () => controller.selectTestResult(result),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                '${result.address}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                'Paladin ${result.address}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                result.result ? 'PASS' : 'FAIL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: result.result ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (hasOpen)
                      const Text(
                        '⚠️ OPEN',
                        style: TextStyle(
                          color: Color(0xFFFFAF56),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (hasShort)
                      const Text(
                        '⛔ SHORT',
                        style: TextStyle(
                          color: Color(0xFFFF4C62),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (!hasOpen && !hasShort)
                      const Text(
                        '-',
                        style: TextStyle(color: Colors.white54),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn({
    required ResistorMachineRecord? record,
    required ResistorMachineTestResult? selectedTest,
    required bool isLoadingRecord,
    required bool fillHeight,
  }) {
    final children = <Widget>[
      _buildTopInfoRow(
        record: record,
        selectedTest: selectedTest,
        isLoadingRecord: isLoadingRecord,
        fillHeight: fillHeight,
      ),
      const SizedBox(height: 16),
    ];

    final dataCard = _buildDataDetailsCard(
      selectedTest: selectedTest,
      isLoadingRecord: isLoadingRecord,
      fillHeight: fillHeight,
    );

    if (fillHeight) {
      children.add(Expanded(child: dataCard));
    } else {
      children.add(dataCard);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildTopInfoRow({
    required ResistorMachineRecord? record,
    required ResistorMachineTestResult? selectedTest,
    required bool isLoadingRecord,
    required bool fillHeight,
  }) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildProductInfoCard(
            record: record,
            isLoadingRecord: isLoadingRecord,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildImageCard(
            selectedTest: selectedTest,
            isLoadingRecord: isLoadingRecord,
          ),
        ),
      ],
    );

    if (fillHeight) {
      return SizedBox(height: 260, child: row);
    }
    return row;
  }

  Widget _buildProductInfoCard({
    required ResistorMachineRecord? record,
    required bool isLoadingRecord,
  }) {
    final _numberFormat = NumberFormat("#,##0.###");

    if (isLoadingRecord) {
      return _buildCardPlaceholder(
        message: 'Loading record information…',
        showLoader: true,
      );
    }
    if (record == null) {
      return _buildCardPlaceholder(
        message: 'Select a serial number to view its information.',
      );
    }

    final infoItems = [
      _InfoEntry(Icons.qr_code_2, 'PRODUCT SN', record.serialNumber ?? '-'),
      _InfoEntry(Icons.confirmation_num, 'SEQUENCE', record.stationSequence.toString()),
      _InfoEntry(Icons.precision_manufacturing, 'MACHINE NAME', record.machineName),
      _InfoEntry(Icons.memory, 'MODEL NAME', record.modelName ?? '-'),
      _InfoEntry(
        Icons.access_time,
        'INSPECTION TIME',
        DateFormat('yyyy-MM-dd HH:mm:ss').format(record.inStationTime),
      ),
      _InfoEntry(
        Icons.verified,
        'STATUS',
        record.isPass ? 'PASS' : 'FAIL',
        color: record.isPass ? Colors.greenAccent : Colors.redAccent,
      ),
      _InfoEntry(
        Icons.timer,
        'CYCLE TIME',
        record.cycleTime != null
            ? '${_numberFormat.format(record.cycleTime)} (second)'
            : '-',
      ),
      _InfoEntry(Icons.person, 'VALIDATOR', record.employeeId ?? '-'),
    ];

    return Container(
      height: 265,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // 🌈 Gradient nền “luxury” kiểu web NVIDIA
        gradient: const LinearGradient(
          colors: [
            Color(0xFF021426),
            Color(0xFF043C52),
            Color(0xFF045E60),
            Color(0xFF022638),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.25),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.12),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: const TableBorder(
          horizontalInside: BorderSide(
            color: Color(0xFF0E354B),
            width: 1,
          ),
        ),
        columnWidths: const {
          0: FixedColumnWidth(24),
          1: FlexColumnWidth(2.4),
          2: FlexColumnWidth(3),
        },
        children: infoItems.map((e) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Icon(
                  e.icon,
                  color: Colors.cyanAccent.withOpacity(0.9),
                  size: 15,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  e.label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  e.value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: e.color ?? Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageCard({
    required ResistorMachineTestResult? selectedTest,
    required bool isLoadingRecord,
  }) {
    Widget content;
    if (isLoadingRecord) {
      content = _buildCardPlaceholder(
        message: 'Preparing image…',
        showLoader: true,
      );
    } else if (selectedTest == null || selectedTest.imagePath.isEmpty) {
      content = const Center(
        child: Text(
          'Select a test to view the captured image.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60),
        ),
      );
    } else {
      content = _buildImagePreview(selectedTest);
    }

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }

  Widget _buildDataDetailsCard({
    required ResistorMachineTestResult? selectedTest,
    required bool isLoadingRecord,
    required bool fillHeight,
  }) {
    Widget body;
    if (isLoadingRecord) {
      body = _buildCardPlaceholder(
        message: 'Loading measurement data…',
        showLoader: true,
      );
    } else if (selectedTest == null) {
      body = _buildCardPlaceholder(
        message: 'Select a test row to inspect the measurements.',
      );
    } else if (selectedTest.details.isEmpty) {
      body = _buildCardPlaceholder(
        message: 'No measurement data available for this test.',
      );
    } else {
      body = _buildMeasurementGrid(selectedTest);
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF00FFFF), // Cyan
              Color(0xFFFFD700), // Vàng
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'DATA DETAILS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (fillHeight)
          Expanded(child: body)
        else
          body,
      ],
    );

    return Container(
      height: fillHeight ? double.infinity : null,
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: column,
    );
  }

  Widget _buildMeasurementGrid(ResistorMachineTestResult test) {
    final Map<int, Map<int, List<ResistorMachineResultDetail>>> matrix = {};
    for (final detail in test.details) {
      matrix.putIfAbsent(detail.row, () => <int, List<ResistorMachineResultDetail>>{});
      matrix[detail.row]!
          .putIfAbsent(detail.column, () => <ResistorMachineResultDetail>[])
          .add(detail);
    }

    final List<int> rows = matrix.keys.toList()..sort();
    final List<int> columns = test.details
        .map((detail) => detail.column)
        .toSet()
        .toList()
      ..sort();

    final table = Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: Colors.white12, width: 1),
      columnWidths: {
        0: const FixedColumnWidth(60),
        for (int i = 1; i <= columns.length; i++)
          i: const FixedColumnWidth(130),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF004C8C),
                Color(0xFF007B8A),
                Color(0xFF001F3F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          children: [
            _buildTableHeaderCell('#'),
            ...columns.map(
              (col) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'COL $col',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ...rows.map(
          (row) => TableRow(
            children: [
              _buildRowHeaderCell(row),
              ...columns.map(
                (col) => SizedBox(
                  width: 130,
                  child: _buildMeasurementCell(
                    matrix[row]?[col] ?? const <ResistorMachineResultDetail>[],
                    row,
                    col,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Scrollbar(
      controller: _gridHorizontalController,
      thumbVisibility: true,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.horizontal,
      child: SingleChildScrollView(
        controller: _gridHorizontalController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Scrollbar(
          controller: _gridVerticalController,
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.vertical,
          child: SingleChildScrollView(
            controller: _gridVerticalController,
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(),
            child: table,
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF004C8C),
            Color(0xFF007B8A),
            Color(0xFF001F3F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFFB3ECFF),
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
            letterSpacing: 0.8,
            shadows: [
              Shadow(
                offset: Offset(0, 1.2),
                blurRadius: 2,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildRowHeaderCell(int row) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Text(
        '$row',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  OverlayEntry? _popupEntry;

  void _showDetailPopup(
      Offset position,
      int? row,
      int? col,
      ResistorMachineResultDetail? top,
      ResistorMachineResultDetail? bottom,
      ) {
    _removePopup();
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _popupEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + 12,
        top: position.dy + 12,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 230,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF071E3D), Color(0xFF021124)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.35), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header ROW - COL
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E0FF), Color(0xFF0078FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      'ROW $row - COL $col',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                if (top != null)
                  _buildPinSection(
                    title: 'TOP PIN',
                    titleGradient: const LinearGradient(
                      colors: [Color(0xFF6A00F4), Color(0xFF00F0FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    bgGradient: const LinearGradient(
                      colors: [Color(0xFF1E0E43), Color(0xFF09264A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    detail: top,
                  ),
                if (bottom != null) ...[
                  const SizedBox(height: 10),
                  _buildPinSection(
                    title: 'BOT PIN',
                    titleGradient: const LinearGradient(
                      colors: [Color(0xFFFFC300), Color(0xFFFF5733)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    bgGradient: const LinearGradient(
                      colors: [Color(0xFF3A2500), Color(0xFF5A3D00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    detail: bottom,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_popupEntry!);
  }

  void _removePopup() {
    _popupEntry?.remove();
    _popupEntry = null;
  }

  Widget _buildPinSection({
    required String title,
    required LinearGradient titleGradient,
    required LinearGradient bgGradient,
    required ResistorMachineResultDetail detail,
  }) {
    String _fmt(num? v) {
      if (v == null) return '-';
      final str = v.toStringAsFixed(3);
      return str.replaceFirst(RegExp(r'\.?0+$'), ''); // ✂️ bỏ số 0 dư
    }

    Widget buildLine(String label, num? value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          Text(
            _fmt(value),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => titleGradient.createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          buildLine('HIGH SAMPLE', detail.highSampleValue),
          buildLine('LOW SAMPLE', detail.lowSampleValue),
          buildLine('MEASUREMENT', detail.measurementValue),
        ],
      ),
    );
  }

  Widget _buildMeasurementCell(List<ResistorMachineResultDetail> details,
      [int? row, int? col]) {
    if (details.isEmpty) {
      return Container(
        height: 72,
        alignment: Alignment.center,
        child: const Text('-', style: TextStyle(color: Colors.white38)),
      );
    }

    final sorted = List<ResistorMachineResultDetail>.from(details)
      ..sort((a, b) => b.name.compareTo(a.name));
    final top = sorted.isNotEmpty ? sorted.first : null;
    final bottom = sorted.length > 1 ? sorted[1] : null;

    bool isFail(ResistorMachineResultDetail? d) =>
        d != null &&
            (d.measurementValue > d.highSampleValue ||
                d.measurementValue < d.lowSampleValue);

    final bool hasFail = isFail(top) || isFail(bottom);

    return GestureDetector(
      onTapDown: (detailsTap) =>
          _showDetailPopup(detailsTap.globalPosition, row, col, top, bottom),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (event) =>
            _showDetailPopup(event.position, row, col, top, bottom),
        onExit: (_) => _removePopup(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: hasFail ? Colors.red.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (top != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildMeasurementLine(top, isFail(top)),
                ),
              if (bottom != null) _buildMeasurementLine(bottom, isFail(bottom)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMeasurementLine(
      ResistorMachineResultDetail detail,
      bool isFail,
      ) {
    final String label = _resolvePinLabel(detail.name);

    String _fmt(num? v) {
      if (v == null) return '-';
      if (v.abs() >= 100000 || v.abs() < 0.001) {
        return v.toStringAsExponential(1);
      }
      final str = v.toStringAsFixed(3);
      return str.replaceFirst(RegExp(r'\.?0+$'), '');
    }

    final String value = _fmt(detail.measurementValue);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) {
            if (detail.name.trim().toUpperCase().startsWith('T')) {
              return const LinearGradient(
                colors: [Color(0xFF00FFFF), Color(0xFFB388FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            } else {
              return const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF9900)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            }
          },
          child: Text(
            '${detail.name.trim().toUpperCase()[0]}:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Tooltip(
            message: value,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: isFail ? Colors.redAccent : Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _resolvePinLabel(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '-';
    return trimmed[0].toUpperCase();
  }

  ImageProvider _resolveTestImage(String? rawPath) {
    const placeholder = AssetImage('assets/images/logo.png');
    if (rawPath == null) {
      return placeholder;
    }

    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) {
      return placeholder;
    }

    final normalized = trimmed.replaceAll('\\', '/');
    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.hasScheme) {
      final scheme = uri.scheme.toLowerCase();
      if ((scheme == 'http' || scheme == 'https') && uri.host.isNotEmpty) {
        return NetworkImage(uri.toString());
      }
    }

    const baseImageUrl =
        'https://10.220.130.117/newweb/api/image/raw';
    final sanitizedPath = normalized.startsWith('/')
        ? normalized
        : '/$normalized';

    return NetworkImage('$baseImageUrl$sanitizedPath');
  }

  Widget _buildCardPlaceholder({
    required String message,
    bool showLoader = false,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLoader) ...[
            const SizedBox(height: 8),
            const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 16),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ResistorMachineTestResult test) {
    final imageProvider = _resolveTestImage(test.imagePath);

    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.black87,
              insetPadding: const EdgeInsets.all(24),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: PhotoView(
                  imageProvider: imageProvider,
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.transparent),
                ),
              ),
            );
          },
        );
      },
      child: Image(
        image: imageProvider,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF010A1B),
          alignment: Alignment.center,
          child: const Text(
            'Unable to load image',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF021024).withOpacity(0.92),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.blueGrey.shade900),
    );
  }
}

class _InfoEntry {
  const _InfoEntry(this.icon, this.label, this.value, {this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
}
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isStatus = false,
    this.isPass = true,
  });

  final String label;
  final String value;
  final bool isStatus;
  final bool isPass;

  @override
  Widget build(BuildContext context) {
    final Color valueColor;
    if (isStatus) {
      valueColor = isPass ? Colors.greenAccent : Colors.redAccent;
    } else {
      valueColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
