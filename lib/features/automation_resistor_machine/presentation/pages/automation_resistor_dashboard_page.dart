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
                  ? 'AUTOMATION RESISTOR MACHINE DASHBOARD'
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
                        child: Obx(() => ResistorComboChart(
                              title: 'YIELD RATE AND OUTPUT',
                              series: view.sectionSeries,
                              alignToShiftWindows: true,
                              startSection: controller.startSection.value,
                            )),
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
          child: Obx(() => ResistorComboChart(
                title: 'YIELD RATE AND OUTPUT',
                series: view.sectionSeries,
                alignToShiftWindows: true,
                startSection: controller.startSection.value,
              )),
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
          child: Obx(() => ResistorComboChart(
                title: 'YIELD RATE AND OUTPUT',
                series: view.sectionSeries,
                alignToShiftWindows: true,
                startSection: controller.startSection.value,
              )),
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
  String _lastQuery = '';

  AutomationResistorDashboardController get controller => widget.controller;

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
          final bool isTablet = constraints.maxWidth >= 720;

          final searchSection = _buildSearchSection(
            matches: matches,
            isSearching: isSearching,
            selectedSerial: selectedSerial,
          );

          final detailSection = _buildDetailSection(
            context: context,
            record: record,
            tests: tests,
            selectedTest: selectedTest,
            isLoading: isLoadingRecord,
            isTablet: isTablet,
          );

          if (isWide) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 340, child: searchSection),
                  const SizedBox(width: 24),
                  Expanded(child: detailSection),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              searchSection,
              const SizedBox(height: 16),
              detailSection,
            ],
          );
        },
      );
    });
  }

  Widget _buildSearchSection({
    required List<ResistorMachineSerialMatch> matches,
    required bool isSearching,
    required ResistorMachineSerialMatch? selectedSerial,
  }) {
    final query = widget.searchController.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF021024).withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueGrey.shade900),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Serial Number',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.searchController,
            focusNode: widget.searchFocusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Enter at least 3 characters to search...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
              filled: true,
              fillColor: const Color(0xFF03132D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.cyanAccent),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          if (selectedSerial != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedSerial.serialNumber,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sequence ${selectedSerial.sequence}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          if (isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            )
          else if (matches.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: matches.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                itemBuilder: (context, index) {
                  final item = matches[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(Icons.confirmation_number,
                        color: Colors.cyanAccent),
                    title: Text(
                      item.serialNumber,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Sequence ${item.sequence}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.cyanAccent),
                    onTap: () => _onSerialTap(item),
                  );
                },
              ),
            )
          else
            Text(
              query.length >= 3
                  ? 'No serial numbers matched your search.'
                  : 'Type at least 3 characters to start searching.',
              style: const TextStyle(color: Colors.white54),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required BuildContext context,
    required ResistorMachineRecord? record,
    required List<ResistorMachineTestResult> tests,
    required ResistorMachineTestResult? selectedTest,
    required bool isLoading,
    required bool isTablet,
  }) {
    if (isLoading) {
      return Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    if (record == null) {
      return Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          'Select a serial number from the list to view tracking details.',
          style: TextStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(record, isTablet),
        const SizedBox(height: 16),
        _buildTestList(tests, selectedTest),
        const SizedBox(height: 16),
        _buildMeasurementCard(selectedTest),
      ],
    );
  }

  Widget _buildInfoCard(ResistorMachineRecord record, bool isTablet) {
    final info = <MapEntry<String, String>>[
      MapEntry('Machine', record.machineName),
      MapEntry('Serial', record.serialNumber ?? '-'),
      MapEntry('Work Date', record.workDate),
      MapEntry('Work Section', '${record.workSection}'),
      MapEntry('Station', '${record.stationSequence}'),
      MapEntry('Pass Qty', '${record.passQty}'),
      MapEntry('Fail Qty', '${record.failQty}'),
      MapEntry('Employee', record.employeeId ?? '-'),
      MapEntry('Error Code', record.errorCode ?? '-'),
    ];

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: info
                .map(
                  (entry) => _InfoChip(
                    label: entry.key,
                    value: entry.value,
                    width: isTablet ? 220 : null,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestList(
    List<ResistorMachineTestResult> tests,
    ResistorMachineTestResult? selectedTest,
  ) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Addresses',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (tests.isEmpty)
            const Text(
              'No test data available for this serial number.',
              style: TextStyle(color: Colors.white60),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                itemCount: tests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = tests[index];
                  final bool isSelected = selectedTest?.address == item.address;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isSelected
                        ? Colors.cyanAccent.withOpacity(0.15)
                        : Colors.transparent,
                    title: Text(
                      'Address ${item.address}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      item.result ? 'PASS' : 'FAIL',
                      style: TextStyle(
                        color: item.result ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: Colors.white54),
                    onTap: () => controller.selectTestResult(item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(ResistorMachineTestResult? test) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Measurement Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (test == null)
            const Text(
              'Select a test address to view measurement details.',
              style: TextStyle(color: Colors.white60),
            )
          else ...[
            _buildMeasurementsTable(test),
            const SizedBox(height: 16),
            _buildImagePreview(test),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementsTable(ResistorMachineTestResult test) {
    final rows = test.details
        .map(
          (detail) => DataRow(
            cells: [
              DataCell(Text(detail.name, style: const TextStyle(color: Colors.white))),
              DataCell(Text('${detail.row}',
                  style: const TextStyle(color: Colors.white70))),
              DataCell(Text('${detail.column}',
                  style: const TextStyle(color: Colors.white70))),
              DataCell(Text(
                detail.measurementValue.toStringAsFixed(3),
                style: const TextStyle(color: Colors.white),
              )),
              DataCell(Text(
                detail.lowSampleValue.toStringAsFixed(3),
                style: const TextStyle(color: Colors.white70),
              )),
              DataCell(Text(
                detail.highSampleValue.toStringAsFixed(3),
                style: const TextStyle(color: Colors.white70),
              )),
              DataCell(Text(
                detail.pass ? 'PASS' : 'FAIL',
                style: TextStyle(
                  color: detail.pass ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              )),
            ],
          ),
        )
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.white10),
        dataRowColor: MaterialStateProperty.all(Colors.white10.withOpacity(0.05)),
        columnSpacing: 24,
        columns: const [
          DataColumn(
            label: Text('Name', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('Row', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('Column', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('Measurement', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('Low Sample', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('High Sample', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('Status', style: TextStyle(color: Colors.white70)),
          ),
        ],
        rows: rows,
      ),
    );
  }

  Widget _buildImagePreview(ResistorMachineTestResult test) {
    if (test.imagePath.isEmpty) {
      return const Text(
        'No inspection image provided.',
        style: TextStyle(color: Colors.white60),
      );
    }

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
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
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.zoom_in, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF021024).withOpacity(0.9),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.blueGrey.shade900),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    this.width,
  });

  final String label;
  final String value;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: content,
    );
  }
}
