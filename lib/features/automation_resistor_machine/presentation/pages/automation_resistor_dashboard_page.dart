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
        backgroundColor: const Color(0xFF010A1B),
        body: SafeArea(
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
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.cyanAccent,
                            ),
                          );
                        }
                        return _DashboardBody(controller: controller);
                      }),
                      _SnAnalysisTab(
                        controller: controller,
                        searchController: searchController,
                        searchFocusNode: searchFocusNode,
                      ),
                    ],
                  ),
                ),
              ],
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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

class _SnAnalysisTabState extends State<_SnAnalysisTab> {
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

  static const LinearGradient _dataDetailsTitleGradient = LinearGradient(
    colors: [Color(0xFF7F5CFF), Color(0xFF2AF4FF)],
  );

  static const LinearGradient _topPinGradient = LinearGradient(
    colors: [Color(0xFFB388FF), Color(0xFF7C8BFF)],
  );

  static const LinearGradient _bottomPinGradient = LinearGradient(
    colors: [Color(0xFFFFE082), Color(0xFFFFB74D)],
  );

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
    return Obx(() {
      final matches = controller.serialMatches;
      final isSearching = controller.isSearchingSerial.value;
      final isLoadingRecord = controller.isLoadingRecord.value;
      final record = controller.selectedRecord.value;
      final tests = controller.recordTestResults;
      final selectedTest = controller.selectedTestResult.value;
      final selectedSerial = controller.selectedSerial.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 1100;
          final EdgeInsets padding = isWide
              ? const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
              : const EdgeInsets.all(16);

          final Widget content = isWide
              ? _buildWideLayout(
                  constraints: constraints,
                  matches: matches,
                  isSearching: isSearching,
                  isLoadingRecord: isLoadingRecord,
                  record: record,
                  tests: tests,
                  selectedTest: selectedTest,
                  selectedSerial: selectedSerial,
                )
              : _buildStackedLayout(
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
        },
      );
    });
  }

  Widget _buildWideLayout({
    required BoxConstraints constraints,
    required List<ResistorMachineSerialMatch> matches,
    required bool isSearching,
    required bool isLoadingRecord,
    required ResistorMachineRecord? record,
    required List<ResistorMachineTestResult> tests,
    required ResistorMachineTestResult? selectedTest,
    required ResistorMachineSerialMatch? selectedSerial,
  }) {
    final bool enableVerticalScroll = constraints.maxHeight < 720;
    final bool fillHeight = !enableVerticalScroll;

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

    if (enableVerticalScroll) {
      return SingleChildScrollView(child: row);
    }

    return SizedBox(
      height: constraints.maxHeight,
      child: row,
    );
  }

  Widget _buildStackedLayout({
    required List<ResistorMachineSerialMatch> matches,
    required bool isSearching,
    required bool isLoadingRecord,
    required ResistorMachineRecord? record,
    required List<ResistorMachineTestResult> tests,
    required ResistorMachineTestResult? selectedTest,
    required ResistorMachineSerialMatch? selectedSerial,
  }) {
    return SingleChildScrollView(
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
      Text(
        'Serial Number Analysis'
        '${selectedSerial != null ? ' ${selectedSerial.serialNumber}' : ''}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
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
    Widget child;
    if (isLoadingRecord) {
      child = _buildCardPlaceholder(
        message: 'Loading record information…',
        showLoader: true,
      );
    } else if (record == null) {
      child = _buildCardPlaceholder(
        message: 'Select a serial number to view its information.',
      );
    } else {
      final entries = <_InfoEntry>[
        _InfoEntry('Product SN', record.serialNumber ?? '-'),
        _InfoEntry('Sequence', record.stationSequence.toString()),
        _InfoEntry('Machine Name', record.machineName),
        _InfoEntry('Model Name', record.modelName ?? '-'),
        _InfoEntry(
          'Inspection Time',
          DateFormat('yyyy-MM-dd HH:mm:ss').format(record.inStationTime),
        ),
        _InfoEntry('Status', record.isPass ? 'PASS' : 'FAIL'),
        _InfoEntry(
          'Cycle Time',
          record.cycleTime != null
              ? '${_numberFormat.format(record.cycleTime)} (second)'
              : '-',
        ),
        _InfoEntry('Validator', record.employeeId ?? '-'),
      ];

      child = Scrollbar(
        controller: _productInfoScrollController,
        thumbVisibility: false,
        child: SingleChildScrollView(
          controller: _productInfoScrollController,
          child: Column(
            children: entries
                .map(
                  (entry) => _InfoRow(
                    label: entry.label,
                    value: entry.value,
                    isStatus: entry.label == 'Status',
                    isPass: record.isPass,
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: child,
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
        _GradientText(
          'DATA DETAILS',
          gradient: _dataDetailsTitleGradient,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 18,
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
      matrix.putIfAbsent(detail.row, () => {});
      matrix[detail.row]!.putIfAbsent(detail.column, () => <ResistorMachineResultDetail>[]);
      matrix[detail.row]![detail.column]!.add(detail);
    }

    final rows = matrix.keys.toList()..sort();
    final columns = test.details
        .map((detail) => detail.column)
        .toSet()
        .toList()
      ..sort();

    final Map<int, TableColumnWidth> widths = {
      0: const FixedColumnWidth(72),
    };
    for (int index = 0; index < columns.length; index++) {
      widths[index + 1] = const FixedColumnWidth(168);
    }

    final table = Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: Colors.white12, width: 1),
      columnWidths: widths,
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
          ),
          children: [
            _buildTableHeaderCell('#'),
            ...columns.map((column) => _buildTableHeaderCell('COL $column')),
          ],
        ),
        ...rows.map(
          (row) => TableRow(
            children: [
              _buildRowHeaderCell(row),
              ...columns.map(
                (column) => _buildMeasurementCell(
                  matrix[row]?[column] ?? const <ResistorMachineResultDetail>[],
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
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: columns.length * 168.0 + 72),
          child: Scrollbar(
            controller: _gridVerticalController,
            thumbVisibility: true,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.vertical,
            child: SingleChildScrollView(
              controller: _gridVerticalController,
              child: table,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
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

  Widget _buildMeasurementCell(List<ResistorMachineResultDetail> details) {
    if (details.isEmpty) {
      return Container(
        height: 72,
        alignment: Alignment.center,
        child: const Text(
          '-',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final sorted = List<ResistorMachineResultDetail>.from(details)
      ..sort((a, b) => b.name.compareTo(a.name));
    final top = sorted.isNotEmpty ? sorted.first : null;
    final bottom = sorted.length > 1 ? sorted[1] : null;

    bool isFail(ResistorMachineResultDetail? detail) {
      if (detail == null) return false;
      return detail.measurementValue > detail.highSampleValue ||
          detail.measurementValue < detail.lowSampleValue;
    }

    final bool topFail = isFail(top);
    final bool bottomFail = isFail(bottom);
    final bool hasFail = topFail || bottomFail;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: hasFail ? Colors.red.withOpacity(0.18) : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (top != null)
            _buildMeasurementLine(top, topFail),
          if (bottom != null) ...[
            const Divider(height: 8, color: Colors.white12),
            _buildMeasurementLine(bottom, bottomFail),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementLine(
    ResistorMachineResultDetail detail,
    bool isFail,
  ) {
    final String label = _resolvePinLabel(detail.name);
    final String value = _numberFormat.format(detail.measurementValue);

    final Gradient gradient = label == 'B'
        ? _bottomPinGradient
        : _topPinGradient;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GradientText(
          '$label:',
          gradient: gradient,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isFail ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.w700,
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
                  imageProvider: NetworkImage(test.imagePath),
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.transparent),
                ),
              ),
            );
          },
        );
      },
      child: Image.network(
        test.imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFF010A1B),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: Colors.cyanAccent,
            ),
          );
        },
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
  const _InfoEntry(this.label, this.value);
  final String label;
  final String value;
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

class _GradientText extends StatelessWidget {
  const _GradientText(
    this.text, {
    super.key,
    required this.gradient,
    required this.style,
    this.textAlign,
  });

  final String text;
  final Gradient gradient;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width == 0 ? 1 : bounds.width, bounds.height == 0 ? style.fontSize ?? 16 : bounds.height),
        );
      },
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: textAlign,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}
