import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../domain/entities/lcr_entities.dart';
import '../controllers/lcr_dashboard_controller.dart';
import '../viewmodels/lcr_dashboard_view_state.dart';
import '../widgets/lcr_chart_card.dart';
import '../widgets/lcr_machine_card.dart';
import '../widgets/lcr_record_detail.dart';
import '../widgets/lcr_summary_tile.dart';

class LcrDashboardPage extends StatefulWidget {
  const LcrDashboardPage({super.key});

  @override
  State<LcrDashboardPage> createState() => _LcrDashboardPageState();
}

class _LcrDashboardPageState extends State<LcrDashboardPage>
    with SingleTickerProviderStateMixin {
  late final LcrDashboardController controller;
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LcrDashboardController(), tag: 'LCR_MACHINE');
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
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
                    children: [
                      _DashboardTab(controller: controller),
                      _AnalysisTab(
                        controller: controller,
                        searchController: searchController,
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
          final isCompact = constraints.maxWidth < 640;

          Widget buildNavigationRow() {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Get.back<void>();
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white70,
                    size: 20,
                  ),
                  splashRadius: 22,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.memory, color: Colors.cyanAccent, size: 28),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'LCR MACHINE',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                  ),
                ),
              ],
            );
          }

          final actions = Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyanAccent,
                    side: const BorderSide(color: Colors.cyanAccent),
                    backgroundColor: const Color(0xFF03132D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    _showFilterSheet(context);
                  },
                  icon: const Icon(Icons.tune, size: 20),
                  label: const Text(
                    'FILTER',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => controller.resetToCurrentShiftAndReload(),
                icon: const Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact) ...[
                buildNavigationRow(),
                const SizedBox(height: 12),
                actions,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: buildNavigationRow()),
                    const SizedBox(width: 12),
                    actions,
                  ],
                ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Future<DateTimeRange?> _pickDashboardDateTimeRange(
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
              primary: Colors.cyan,
              surface: Color(0xFF03132D),
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

        if (startHour == 0 && startMinute == 0 && endHour == 0 && endMinute == 0) {
          startHour = 7;
          startMinute = 30;
          endHour = 19;
          endMinute = 30;
        }

        return StatefulBuilder(
          builder: (context, setState) {
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
              final format = DateFormat('yyyy/MM/dd HH:mm');
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: buildDropdown(
                                    label: 'Hour',
                                    value: startHour,
                                    items: hours,
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          startHour = value;
                                          if (_buildEndDate()
                                              .isBefore(_buildStartDate())) {
                                            endHour = startHour;
                                            endMinute = startMinute;
                                          }
                                        });
                                      }
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
                                      if (value != null) {
                                        setState(() {
                                          startMinute = value;
                                          if (_buildEndDate()
                                              .isBefore(_buildStartDate())) {
                                            endHour = startHour;
                                            endMinute = startMinute;
                                          }
                                        });
                                      }
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: buildDropdown(
                                    label: 'Hour',
                                    value: endHour,
                                    items: hours,
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          endHour = value;
                                          if (_buildEndDate()
                                              .isBefore(_buildStartDate())) {
                                            startHour = endHour;
                                            startMinute = endMinute;
                                          }
                                        });
                                      }
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
                                      if (value != null) {
                                        setState(() {
                                          endMinute = value;
                                          if (_buildEndDate()
                                              .isBefore(_buildStartDate())) {
                                            startHour = endHour;
                                            startMinute = endMinute;
                                          }
                                        });
                                      }
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
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF052043),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      previewText(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: applySelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_FilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var tempFactory = controller.selectedFactory.value;
        var tempDepartment = controller.selectedDepartment.value;
        var tempMachine = controller.selectedMachine.value;
        var tempStatus = controller.selectedStatus.value;
        var tempRange = controller.selectedDateRange.value;
        final initialRange = controller.selectedDateRange.value;

        return StatefulBuilder(
          builder: (context, setState) {
            final media = MediaQuery.of(context);
            final width = media.size.width;
            final useSideSheet = width >= 600;

            final factoryOptions = _factoryOptions();
            final departmentOptions = _departmentOptionsFor(tempFactory);
            if (!departmentOptions.contains(tempDepartment)) {
              tempDepartment = 'ALL';
            }
            final machineOptions =
                _machineOptionsFor(tempFactory, tempDepartment);
            if (!machineOptions.contains(tempMachine)) {
              tempMachine = 'ALL';
            }
            const statusOptions = ['ALL', 'PASS', 'FAIL'];

            final borderRadius = useSideSheet
                ? BorderRadius.circular(24)
                : const BorderRadius.vertical(top: Radius.circular(24));

            return SafeArea(
              child: Align(
                alignment:
                    useSideSheet ? Alignment.topRight : Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: useSideSheet ? 96 : 0,
                    right: useSideSheet ? 24 : 0,
                    left: useSideSheet ? 0 : 0,
                    bottom: media.viewInsets.bottom + (useSideSheet ? 24 : 0),
                  ),
                  child: ConstrainedBox(
                    constraints: useSideSheet
                        ? const BoxConstraints(minWidth: 380, maxWidth: 440)
                        : const BoxConstraints(),
                    child: FractionallySizedBox(
                      widthFactor: useSideSheet ? null : 1.0,
                      child: Material(
                        color: const Color(0xFF04122B),
                        borderRadius: borderRadius,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 28,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Filter',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Refine your query',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Date Range',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _FilterDateRangeTile(
                                  rangeLabel: _formatRangeLabel(tempRange),
                                  onPressed: () async {
                                    final picked = await _pickDashboardDateTimeRange(
                                      context,
                                      tempRange,
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        tempRange = picked;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),
                                _FilterSheetDropdown(
                                  label: 'Factory',
                                  value: tempFactory,
                                  items: factoryOptions,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      tempFactory = value;
                                      tempDepartment = 'ALL';
                                      tempMachine = 'ALL';
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                _FilterSheetDropdown(
                                  label: 'Department',
                                  value: tempDepartment,
                                  items: departmentOptions,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      tempDepartment = value;
                                      tempMachine = 'ALL';
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                _FilterSheetDropdown(
                                  label: 'Machine',
                                  value: tempMachine,
                                  items: machineOptions,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      tempMachine = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                _FilterSheetDropdown(
                                  label: 'Status',
                                  value: tempStatus,
                                  items: statusOptions,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      tempStatus = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white70,
                                          side: const BorderSide(color: Colors.white24),
                                          backgroundColor: const Color(0xFF0B1F3D),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            tempFactory = 'ALL';
                                            tempDepartment = 'ALL';
                                            tempMachine = 'ALL';
                                            tempStatus = 'ALL';
                                            tempRange = DateTimeRange(
                                              start: initialRange.start,
                                              end: initialRange.end,
                                            );
                                          });
                                        },
                                        child: const Text(
                                          'Reset',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.cyanAccent,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop(
                                            _FilterSelection(
                                              factory: tempFactory,
                                              department: tempDepartment,
                                              machine: tempMachine,
                                              status: tempStatus,
                                              dateRange: tempRange,
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'QUERY',
                                          style: TextStyle(fontWeight: FontWeight.w700),
                                        ),
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
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      controller.updateFactory(result.factory);
      controller.updateDepartment(result.department);
      controller.updateMachine(result.machine);
      controller.updateStatus(result.status);
      await controller.updateDateRange(result.dateRange);
    }
  }

  List<String> _factoryOptions() {
    final options = ['ALL'];
    for (final factory in controller.factories) {
      options.add(factory.name);
    }
    return options;
  }

  List<String> _departmentOptionsFor(String factory) {
    final names = <String>{};
    if (factory == 'ALL') {
      for (final item in controller.factories) {
        for (final dept in item.departments) {
          names.add(dept.name);
        }
      }
    } else {
      for (final item in controller.factories) {
        if (item.name == factory) {
          for (final dept in item.departments) {
            names.add(dept.name);
          }
          break;
        }
      }
    }
    final list = names.toList()..sort();
    return ['ALL', ...list];
  }

  List<String> _machineOptionsFor(String factory, String department) {
    final machines = <int>{};
    final departments = <LcrDepartment>[];

    if (factory == 'ALL') {
      for (final item in controller.factories) {
        departments.addAll(item.departments);
      }
    } else {
      for (final item in controller.factories) {
        if (item.name == factory) {
          departments.addAll(item.departments);
          break;
        }
      }
    }

    if (department != 'ALL') {
      departments.retainWhere((element) => element.name == department);
    }

    for (final dept in departments) {
      machines.addAll(dept.machines);
    }

    final sorted = machines.toList()..sort();
    final machineStrings = sorted.map((e) => e.toString()).toList();
    return ['ALL', ...machineStrings];
  }

  String _formatRangeLabel(DateTimeRange range) {
    final format = DateFormat('yyyy-MM-dd HH:mm');
    return '${format.format(range.start)} → ${format.format(range.end)}';
  }

  String _fmt(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.controller});

  final LcrDashboardController controller;

  double _factoryDistributionHeight(int itemCount) {
    if (itemCount <= 0) {
      return 260.0;
    }

    const headerHeight = 170.0;
    const perTile = 88.0;
    final computed = headerHeight + (itemCount * perTile);
    return math.max(260.0, computed);
  }

  double _machinePerformanceHeight(int itemCount) {
    if (itemCount <= 0) {
      return 260.0;
    }
    if (itemCount <= 4) {
      return 260.0;
    }
    if (itemCount <= 8) {
      return 320.0;
    }
    return 420.0;
  }

  Widget _buildPrimaryCharts({
    required LcrDashboardViewState data,
    required bool isMobile,
    required bool isTablet,
    required double primaryRowHeight,
  }) {
    final factoryCard = LcrChartCard(
      title: 'FACTORY DISTRIBUTION',
      height: primaryRowHeight,
      child: _FactoryDistributionList(data.factorySlices),
    );

    final machineCard = LcrChartCard(
      title: 'MACHINE PERFORMANCE',
      height: primaryRowHeight,
      child: _MachinesGrid(data.machineGauges),
    );

    final employeeCard = LcrChartCard(
      title: 'EMPLOYEE STATISTICS',
      height: primaryRowHeight,
      child: _EmployeeStatisticsChart(data.employeeSeries),
    );

    if (!isMobile && !isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: factoryCard),
          const SizedBox(width: 24),
          Expanded(flex: 6, child: machineCard),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: employeeCard),
        ],
      );
    }

    if (isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          machineCard,
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: factoryCard),
              const SizedBox(width: 16),
              Expanded(child: employeeCard),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        machineCard,
        const SizedBox(height: 16),
        factoryCard,
        const SizedBox(height: 16),
        employeeCard,
      ],
    );
  }

  Widget _buildSecondaryCharts({
    required LcrDashboardViewState data,
    required bool isMobile,
    required bool isTablet,
    double? availableHeight,
  }) {
    double resolveHeight(double base) {
      if (availableHeight == null || !availableHeight.isFinite) {
        return base;
      }
      return availableHeight!;
    }

    final departmentCard = LcrChartCard(
      title: 'DEPARTMENT ANALYSIS',
      height: resolveHeight(340),
      child: _StackedBarChart(data.departmentSeries),
    );

    final outputCard = LcrChartCard(
      title: 'YIELD RATE & OUTPUT',
      height: resolveHeight(360),
      backgroundGradient: const LinearGradient(
        colors: [
          Color(0xFF062349),
          Color(0xFF041127),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: _OutputChart(data.outputTrend),
    );

    final typeCard = LcrChartCard(
      title: 'TYPE ANALYSIS',
      height: resolveHeight(340),
      child: _StackedBarChart(
        data.typeSeries,
        xLabelStyle: const TextStyle(
          color: Color(0xFFE8F4FF),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          shadows: [
            Shadow(
              color: Color(0x88000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        xLabelIntersectAction: AxisLabelIntersectAction.wrap,
        maximumLabelWidth: 90,
      ),
    );

    if (!isMobile && !isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: departmentCard),
          const SizedBox(width: 24),
          Expanded(flex: 5, child: outputCard),
          const SizedBox(width: 24),
          Expanded(flex: 3, child: typeCard),
        ],
      );
    }

    if (isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          outputCard,
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: departmentCard),
              const SizedBox(width: 16),
              Expanded(child: typeCard),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        outputCard,
        const SizedBox(height: 16),
        departmentCard,
        const SizedBox(height: 16),
        typeCard,
      ],
    );
  }

  Future<void> _showStatusOverview(BuildContext context, bool showPass) async {
    final overview = controller.dashboardView.value?.overview;
    final expectedCount = overview == null
        ? null
        : showPass
            ? overview.pass
            : overview.fail;

    if (expectedCount != null && expectedCount <= 0) {
      final snackBar = SnackBar(
        backgroundColor: Colors.blueGrey.shade900,
        content: Text(
          'No ${showPass ? 'pass' : 'fail'} records available for the current filters.',
          style: const TextStyle(color: Colors.white),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      return;
    }

    List<LcrRecord> records = const <LcrRecord>[];

    try {
      final fetched = await controller.loadStatusRecords(pass: showPass);
      final filtered = fetched
          .where((record) => record.isPass == showPass)
          .toList();
      records = filtered.isEmpty && fetched.isNotEmpty
          ? List<LcrRecord>.from(fetched)
          : filtered;
    } catch (error) {
      if (context.mounted) {
        final snackBar = SnackBar(
          backgroundColor: Colors.redAccent.shade200,
          content: Text(
            'Unable to load ${showPass ? 'pass' : 'fail'} records. Please try again.',
            style: const TextStyle(color: Colors.white),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      return;
    }

    if (records.isEmpty) {
      if (context.mounted) {
        final snackBar = SnackBar(
          backgroundColor: Colors.blueGrey.shade900,
          content: Text(
            'No ${showPass ? 'pass' : 'fail'} records available for the current filters.',
            style: const TextStyle(color: Colors.white),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      return;
    }

    final sorted = List<LcrRecord>.from(records)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    if (!context.mounted) {
      return;
    }

    final accentColor = showPass
        ? const Color(0xFF2DE5FF)
        : const Color(0xFFFF77A9);

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => _StatusOverviewDialog(
        title: showPass ? 'PASS OVERVIEW' : 'FAIL OVERVIEW',
        highlightColor: accentColor,
        records: sorted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          if (controller.isLoading.value &&
              controller.dashboardView.value == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          final data = controller.dashboardView.value;
          if (data == null) {
            return Center(
              child: Text(
                controller.error.value ?? 'No data available',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final machineHeight =
              _machinePerformanceHeight(data.machineGauges.length);
          final factoryHeight =
              _factoryDistributionHeight(data.factorySlices.length);
          final primaryRowHeight = math.max(
            260.0,
            math.max(machineHeight, factoryHeight),
          );

          final maxWidth = constraints.maxWidth;
          final isMobile = maxWidth < 720;
          final isTablet = !isMobile && maxWidth < 1100;
          final horizontalPadding = isMobile ? 16.0 : 24.0;
          final verticalPadding = isMobile ? 16.0 : 24.0;
          final resolvedPrimaryHeight = (isMobile || isTablet)
              ? primaryRowHeight
              : math.max(320.0, machineHeight);

          final summaryWidget = _SummaryRow(
            overview: data.overview,
            onPassOverview: () => _showStatusOverview(context, true),
            onFailOverview: () => _showStatusOverview(context, false),
          );

          if (!isMobile && !isTablet) {
            const summaryEstimate = 140.0;
            const betweenSummaryAndPrimary = 12.0;
            const betweenRows = 16.0;
            const minSecondaryHeight = 360.0;

            final minRequiredHeight = (verticalPadding * 2) +
                summaryEstimate +
                betweenSummaryAndPrimary +
                resolvedPrimaryHeight +
                betweenRows +
                minSecondaryHeight;

            if (constraints.maxHeight >= minRequiredHeight) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 140),
                      child: summaryWidget,
                    ),
                    SizedBox(height: betweenSummaryAndPrimary),
                    Expanded(
                      flex: 8,
                      child: LayoutBuilder(
                        builder: (context, innerConstraints) {
                          final height = innerConstraints.maxHeight.isFinite
                              ? innerConstraints.maxHeight
                              : resolvedPrimaryHeight;
                          return _buildPrimaryCharts(
                            data: data,
                            isMobile: isMobile,
                            isTablet: isTablet,
                            primaryRowHeight: height,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: betweenRows),
                    Expanded(
                      flex: 11,
                      child: LayoutBuilder(
                        builder: (context, innerConstraints) {
                          final secondaryHeight =
                              innerConstraints.maxHeight.isFinite
                                  ? innerConstraints.maxHeight
                                  : null;
                          return _buildSecondaryCharts(
                            data: data,
                            isMobile: isMobile,
                            isTablet: isTablet,
                            availableHeight: secondaryHeight,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          }

          return SizedBox(
            width: maxWidth,
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              primary: false,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summaryWidget,
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildPrimaryCharts(
                      data: data,
                      isMobile: isMobile,
                      isTablet: isTablet,
                      primaryRowHeight: resolvedPrimaryHeight,
                    ),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildSecondaryCharts(
                      data: data,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.overview,
    this.onPassOverview,
    this.onFailOverview,
  });

  final LcrOverview overview;
  final VoidCallback? onPassOverview;
  final VoidCallback? onFailOverview;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      LcrSummaryTile(
        title: 'INPUT',
        value: overview.total.toString(),
        suffix: 'PCS',
        color: Colors.blueAccent,
      ),
      LcrSummaryTile(
        title: 'PASS',
        value: overview.pass.toString(),
        suffix: 'PCS',
        color: Colors.greenAccent,
        actionLabel: 'Overview',
        onActionTap: onPassOverview,
      ),
      LcrSummaryTile(
        title: 'FAIL',
        value: overview.fail.toString(),
        suffix: 'PCS',
        color: Colors.redAccent,
        actionLabel: 'Overview',
        onActionTap: onFailOverview,
      ),
      LcrSummaryTile(
        title: 'Y.R',
        value: overview.yieldRate.toStringAsFixed(2),
        suffix: '%',
        color: Colors.amberAccent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= 900) {
          return Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                Expanded(child: tiles[i]),
                if (i != tiles.length - 1) const SizedBox(width: 16),
              ],
            ],
          );
        }

        if (width >= 600) {
          final itemWidth = (width - 16) / 2;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: tiles
                .map((tile) => SizedBox(width: itemWidth, child: tile))
                .toList(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              tiles[i],
              if (i != tiles.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _StatusOverviewDialog extends StatefulWidget {
  const _StatusOverviewDialog({
    required this.title,
    required this.records,
    required this.highlightColor,
  });

  final String title;
  final List<LcrRecord> records;
  final Color highlightColor;

  @override
  State<_StatusOverviewDialog> createState() => _StatusOverviewDialogState();
}

class _StatusOverviewDialogState extends State<_StatusOverviewDialog> {
  late final ScrollController _verticalController;
  late final ScrollController _horizontalHeaderController;
  late final ScrollController _horizontalBodyController;
  late final TextEditingController _searchController;
  static const String _kAllFilter = 'ALL';
  static const String _kMissingValue = '-';
  static const double _kHeaderHeight = 48;
  static const double _kColumnSpacing = 6;
  static const double _kHorizontalMargin = 8;

  static const List<DataColumn> _tableColumns = <DataColumn>[
    DataColumn(label: _TableHeader('#')),
    DataColumn(label: _TableHeader('DATE TIME')),
    DataColumn(label: _TableHeader('SERIAL NO.')),
    DataColumn(label: _TableHeader('CUSTOMER P/N')),
    DataColumn(label: _TableHeader('DATE CODE')),
    DataColumn(label: _TableHeader('LOT CODE')),
    DataColumn(label: _TableHeader('QTY')),
    DataColumn(label: _TableHeader('EXT QTY')),
    DataColumn(label: _TableHeader('DESCRIPTION', maxLines: 2)),
    DataColumn(label: _TableHeader('MATERIAL TYPE')),
    DataColumn(label: _TableHeader('LOW SPEC')),
    DataColumn(label: _TableHeader('HIGH SPEC')),
    DataColumn(label: _TableHeader('MEASURE VALUE')),
    DataColumn(label: _TableHeader('EMPLOYEE ID')),
    DataColumn(label: _TableHeader('FACTORY')),
    DataColumn(label: _TableHeader('DEPARTMENT')),
    DataColumn(label: _TableHeader('MACHINE NO.')),
  ];

  late List<LcrRecord> _filteredRecords;
  List<String> _typeOptions = const <String>[];
  List<String> _employeeOptions = const <String>[];
  List<String> _factoryOptions = const <String>[];
  List<String> _departmentOptions = const <String>[];
  List<String> _machineOptions = const <String>[];

  String _selectedType = _kAllFilter;
  String _selectedEmployee = _kAllFilter;
  String _selectedFactory = _kAllFilter;
  String _selectedDepartment = _kAllFilter;
  String _selectedMachine = _kAllFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _verticalController = ScrollController();
    _horizontalHeaderController = ScrollController();
    _horizontalBodyController = ScrollController();
    _horizontalBodyController.addListener(_syncHorizontalControllers);
    _searchController = TextEditingController();
    _initializeFilters();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalBodyController.removeListener(_syncHorizontalControllers);
    _horizontalHeaderController.dispose();
    _horizontalBodyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _StatusOverviewDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.records, widget.records)) {
      setState(_initializeFilters);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final totalRecords = widget.records.length;
    final records = _filteredRecords;
    final highlightColor = widget.highlightColor;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final width = math.min(
      math.max(media.size.width * 0.92, media.size.width - 48),
      1800.0,
    );
    final tableMinWidth = math.max(width * 0.9, width - 96);
    final height = math.min(media.size.height * 0.8, 640.0);
    final dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final hasActiveFilters = _hasActiveFilters;
    final recordChipLabel = hasActiveFilters
        ? '${records.length} / $totalRecords records'
        : '${records.length} records';
    final emptyMessage = hasActiveFilters
        ? 'No records match the current filters.'
        : 'No records available for this status.';
    final headingTextStyle = theme.textTheme.labelSmall?.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ) ??
        const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        );
    final dataTextStyle = theme.textTheme.bodySmall?.copyWith(
          color: Colors.white.withOpacity(0.9),
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          color: Color(0xE6FFFFFF),
          fontWeight: FontWeight.w600,
        );
    final infoTextStyle = theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFF20E0FF),
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          color: Color(0xFF20E0FF),
          fontWeight: FontWeight.w700,
        );
    final warningTextStyle = theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFFFF77A9),
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          color: Color(0xFFFF77A9),
          fontWeight: FontWeight.w700,
        );
    final successTextStyle = theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFF5CFF8F),
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          color: Color(0xFF5CFF8F),
          fontWeight: FontWeight.w700,
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF020D24).withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 32,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: highlightColor.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      recordChipLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: highlightColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    splashRadius: 22,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: Colors.white12, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final filterControls = <Widget>[
                    _FilterDropdown(
                      label: 'TYPE',
                      value: _selectedType,
                      options: _typeOptions,
                      onChanged: (value) => _onFilterChanged(type: value),
                      width: 200,
                    ),
                    _FilterDropdown(
                      label: 'EMPLOYEE ID',
                      value: _selectedEmployee,
                      options: _employeeOptions,
                      onChanged: (value) => _onFilterChanged(employee: value),
                      width: 180,
                    ),
                    _FilterDropdown(
                      label: 'FACTORY',
                      value: _selectedFactory,
                      options: _factoryOptions,
                      onChanged: (value) => _onFilterChanged(factory: value),
                      width: 160,
                    ),
                    _FilterDropdown(
                      label: 'DEPARTMENT',
                      value: _selectedDepartment,
                      options: _departmentOptions,
                      onChanged: (value) => _onFilterChanged(department: value),
                      width: 180,
                    ),
                    _FilterDropdown(
                      label: 'MACHINE NO.',
                      value: _selectedMachine,
                      options: _machineOptions,
                      onChanged: (value) => _onFilterChanged(machine: value),
                      width: 150,
                    ),
                  ];

                  final searchField = _SearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  );

                  final isWide = constraints.maxWidth >= 1080;
                  final searchWidth = math.max(
                    220.0,
                    math.min(320.0, constraints.maxWidth * 0.35),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: filterControls,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: searchWidth,
                          child: searchField,
                        ),
                      ],
                    );
                  }

                  final compactSearchWidth = math.min(360.0, constraints.maxWidth);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: filterControls,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: compactSearchWidth,
                          child: searchField,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: records.isEmpty
                  ? _buildEmptyState(theme, emptyMessage)
                  : _buildRecordsTable(
                      records: records,
                      tableMinWidth: tableMinWidth,
                      dateTimeFormatter: dateTimeFormatter,
                      headingTextStyle: headingTextStyle,
                      dataTextStyle: dataTextStyle,
                      infoTextStyle: infoTextStyle,
                      warningTextStyle: warningTextStyle,
                      successTextStyle: successTextStyle,
                    ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState(ThemeData theme, String message) {
    final style = theme.textTheme.titleMedium?.copyWith(
          color: Colors.white60,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          color: Colors.white60,
          fontWeight: FontWeight.w600,
        );

    return Center(
      child: Text(
        message,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRecordsTable({
    required List<LcrRecord> records,
    required double tableMinWidth,
    required DateFormat dateTimeFormatter,
    required TextStyle headingTextStyle,
    required TextStyle dataTextStyle,
    required TextStyle infoTextStyle,
    required TextStyle warningTextStyle,
    required TextStyle successTextStyle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        color: Colors.white.withOpacity(0.03),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            _StickyTableHeader(
              horizontalController: _horizontalHeaderController,
              minWidth: tableMinWidth,
              columns: _tableColumns,
              headingTextStyle: headingTextStyle,
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: Colors.white12,
            ),
            Expanded(
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  primary: false,
                  child: SingleChildScrollView(
                    controller: _horizontalBodyController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: tableMinWidth,
                      ),
                      child: DataTable(
                        headingRowHeight: 0,
                        dataRowMinHeight: 44,
                        dataRowMaxHeight: 60,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.white.withOpacity(0.05),
                        ),
                        headingTextStyle: headingTextStyle,
                        dataTextStyle: dataTextStyle,
                        columnSpacing: _kColumnSpacing,
                        horizontalMargin: _kHorizontalMargin,
                        columns: _tableColumns,
                        rows: records.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final record = entry.value;
                          final rowTint = record.isPass
                              ? Colors.white.withOpacity(0.01)
                              : const Color(0xFFFF77A9).withOpacity(0.08);

                          return DataRow(
                            color: MaterialStateProperty.all(rowTint),
                            cells: <DataCell>[
                              DataCell(
                                _TableText(index.toString()),
                              ),
                              DataCell(
                                _TableText(
                                  dateTimeFormatter.format(record.dateTime),
                                ),
                              ),
                              DataCell(
                                _TableText(
                                  record.serialNumber ?? '-',
                                  style: infoTextStyle,
                                ),
                              ),
                              DataCell(
                                _TableText(record.customerPn ?? '-'),
                              ),
                              DataCell(
                                _TableText(record.dateCode ?? '-'),
                              ),
                              DataCell(
                                _TableText(record.lotCode ?? '-'),
                              ),
                              DataCell(
                                _TableText(
                                  record.qty?.toString() ?? '-',
                                ),
                              ),
                              DataCell(
                                _TableText(
                                  record.extQty?.toString() ?? '-',
                                ),
                              ),
                              DataCell(
                                _TableText(
                                  record.description ?? '-',
                                  maxLines: 2,
                                ),
                              ),
                              DataCell(
                                _TableText(
                                  _stringValue(record.materialType),
                                ),
                              ),
                              DataCell(
                                _TableText(
                                  record.lowSpec ?? '-',
                                  style: infoTextStyle,
                                ),
                              ),
                              DataCell(
                                _TableText(
                                  record.highSpec ?? '-',
                                  style: warningTextStyle,
                                ),
                              ),
                              DataCell(
                                _TableText(
                                  record.measureValue ?? '-',
                                  style: successTextStyle,
                                ),
                              ),
                              DataCell(
                                _TableText(
                                  _stringValue(record.employeeId),
                                ),
                              ),
                              DataCell(
                                _TableText(
                                  _stringValue(record.factory),
                                ),
                              ),
                              DataCell(
                                _TableText(
                                  _stringValue(record.department),
                                ),
                              ),
                              DataCell(
                                _TableText(
                                  _machineValue(record.machineNo),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
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

  bool get _hasActiveFilters =>
      _selectedType != _kAllFilter ||
      _selectedEmployee != _kAllFilter ||
      _selectedFactory != _kAllFilter ||
      _selectedDepartment != _kAllFilter ||
      _selectedMachine != _kAllFilter ||
      _searchQuery.isNotEmpty;

  void _initializeFilters() {
    final records = widget.records;
    _typeOptions = _buildStringOptions(records.map((record) => record.materialType));
    _employeeOptions =
        _buildStringOptions(records.map((record) => record.employeeId));
    _factoryOptions = _buildStringOptions(records.map((record) => record.factory));
    _departmentOptions =
        _buildStringOptions(records.map((record) => record.department));
    _machineOptions = _buildMachineOptions(records.map((record) => record.machineNo));
    _selectedType = _kAllFilter;
    _selectedEmployee = _kAllFilter;
    _selectedFactory = _kAllFilter;
    _selectedDepartment = _kAllFilter;
    _selectedMachine = _kAllFilter;
    _searchQuery = '';
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    _filteredRecords = List<LcrRecord>.from(records);
    _resetScrollPositions();
  }

  void _onFilterChanged({
    String? type,
    String? employee,
    String? factory,
    String? department,
    String? machine,
  }) {
    setState(() {
      if (type != null) _selectedType = type;
      if (employee != null) _selectedEmployee = employee;
      if (factory != null) _selectedFactory = factory;
      if (department != null) _selectedDepartment = department;
      if (machine != null) _selectedMachine = machine;
      _filteredRecords = _applyFilters();
    });
    _resetScrollPositions();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _filteredRecords = _applyFilters();
    });
    _resetScrollPositions();
  }

  List<LcrRecord> _applyFilters() {
    final query = _searchQuery.toLowerCase();
    final hasQuery = query.isNotEmpty;

    return widget.records.where((record) {
      if (_selectedType != _kAllFilter &&
          _stringValue(record.materialType) != _selectedType) {
        return false;
      }
      if (_selectedEmployee != _kAllFilter &&
          _stringValue(record.employeeId) != _selectedEmployee) {
        return false;
      }
      if (_selectedFactory != _kAllFilter &&
          _stringValue(record.factory) != _selectedFactory) {
        return false;
      }
      if (_selectedDepartment != _kAllFilter &&
          _stringValue(record.department) != _selectedDepartment) {
        return false;
      }
      if (_selectedMachine != _kAllFilter &&
          _machineValue(record.machineNo) != _selectedMachine) {
        return false;
      }
      if (hasQuery && !_matchesSearch(record, query)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _matchesSearch(LcrRecord record, String query) {
    bool matchString(String? value) =>
        value != null && value.toLowerCase().contains(query);
    bool matchInt(int? value) =>
        value != null && value != 0 && value.toString().contains(query);

    if (matchString(record.serialNumber)) return true;
    if (matchString(record.customerPn)) return true;
    if (matchString(record.dateCode)) return true;
    if (matchString(record.lotCode)) return true;
    if (matchString(record.description)) return true;
    if (matchString(record.materialType)) return true;
    if (_stringValue(record.materialType).toLowerCase().contains(query)) {
      return true;
    }
    if (matchString(record.lowSpec)) return true;
    if (matchString(record.highSpec)) return true;
    if (matchString(record.measureValue)) return true;
    if (matchString(record.employeeId)) return true;
    if (_stringValue(record.employeeId).toLowerCase().contains(query)) {
      return true;
    }
    if (matchString(record.vendor)) return true;
    if (matchString(record.vendorNo)) return true;
    if (matchString(record.location)) return true;
    if (matchInt(record.qty)) return true;
    if (matchInt(record.extQty)) return true;
    if (record.workDate.isNotEmpty &&
        record.workDate.toLowerCase().contains(query)) {
      return true;
    }
    if (record.className.isNotEmpty &&
        record.className.toLowerCase().contains(query)) {
      return true;
    }
    if (record.classDate.isNotEmpty &&
        record.classDate.toLowerCase().contains(query)) {
      return true;
    }
    if (record.recordId.isNotEmpty &&
        record.recordId.toLowerCase().contains(query)) {
      return true;
    }
    final factoryValue = record.factory.toLowerCase();
    if (factoryValue.contains(query)) return true;
    if (matchString(record.department)) return true;
    if (_stringValue(record.department).toLowerCase().contains(query)) {
      return true;
    }
    final machineValue = _machineValue(record.machineNo).toLowerCase();
    if (machineValue.contains(query)) return true;
    final statusLabel = record.isPass ? 'pass' : 'fail';
    if (statusLabel.contains(query)) return true;
    final dateString = record.dateTime.toIso8601String().toLowerCase();
    if (dateString.contains(query)) return true;
    if (matchInt(record.workSection)) return true;
    return false;
  }

  List<String> _buildStringOptions(Iterable<String?> values) {
    final unique = <String, String>{};
    var includeMissing = false;
    for (final raw in values) {
      final trimmed = raw?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        includeMissing = true;
        continue;
      }
      final key = trimmed.toLowerCase();
      unique.putIfAbsent(key, () => trimmed);
    }
    final options = <String>[_kAllFilter];
    if (includeMissing) {
      options.add(_kMissingValue);
    }
    final sortedKeys = SplayTreeSet<String>()..addAll(unique.keys);
    for (final key in sortedKeys) {
      options.add(unique[key]!);
    }
    return options;
  }

  List<String> _buildMachineOptions(Iterable<int> values) {
    final sorted = SplayTreeSet<int>();
    var includeMissing = false;
    for (final machine in values) {
      if (machine == 0) {
        includeMissing = true;
      } else {
        sorted.add(machine);
      }
    }
    final options = <String>[_kAllFilter];
    if (includeMissing) {
      options.add(_kMissingValue);
    }
    for (final machine in sorted) {
      options.add(machine.toString());
    }
    return options;
  }

  String _stringValue(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return _kMissingValue;
    }
    return trimmed;
  }

  String _machineValue(int machine) {
    return machine == 0 ? _kMissingValue : machine.toString();
  }

  void _syncHorizontalControllers() {
    if (!_horizontalHeaderController.hasClients) {
      return;
    }
    final offset = _horizontalBodyController.offset;
    if (_horizontalHeaderController.offset == offset) {
      return;
    }
    _horizontalHeaderController.jumpTo(offset);
  }

  void _resetScrollPositions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_verticalController.hasClients) {
        _verticalController.jumpTo(0);
      }
      if (_horizontalBodyController.hasClients) {
        _horizontalBodyController.jumpTo(0);
      }
      if (_horizontalHeaderController.hasClients) {
        _horizontalHeaderController.jumpTo(0);
      }
    });
  }
}

class _StickyTableHeader extends StatelessWidget {
  const _StickyTableHeader({
    required this.horizontalController,
    required this.minWidth,
    required this.columns,
    required this.headingTextStyle,
  });

  final ScrollController horizontalController;
  final double minWidth;
  final List<DataColumn> columns;
  final TextStyle headingTextStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _StatusOverviewDialogState._kHeaderHeight,
      child: SingleChildScrollView(
        controller: horizontalController,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth),
          child: DataTable(
            headingRowHeight: _StatusOverviewDialogState._kHeaderHeight,
            dataRowMinHeight: 0,
            dataRowMaxHeight: 0,
            headingRowColor: MaterialStateProperty.all(
              Colors.white.withOpacity(0.05),
            ),
            headingTextStyle: headingTextStyle,
            columnSpacing: _StatusOverviewDialogState._kColumnSpacing,
            horizontalMargin: _StatusOverviewDialogState._kHorizontalMargin,
            columns: columns,
            rows: const <DataRow>[],
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label, {this.maxLines = 1});

  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 56),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: maxLines > 1,
      ),
    );
  }
}

class _TableText extends StatelessWidget {
  const _TableText(
    this.value, {
    this.style,
    this.maxLines = 1,
  });

  final String value;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: maxLines > 1,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
          color: Colors.white54,
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.w500,
        );
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: textStyle,
      cursorColor: const Color(0xFF20E0FF),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        hintText: 'Search records',
        hintStyle: hintStyle,
        prefixIcon:
            const Icon(Icons.search, color: Colors.white54, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF20E0FF)),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.width = 180,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ) ??
        const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        );

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 6),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                dropdownColor: const Color(0xFF04122F),
                isExpanded: true,
                style: valueStyle,
                onChanged: (newValue) {
                  if (newValue == null) return;
                  onChanged(newValue);
                },
                items: options
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactoryDistributionList extends StatefulWidget {
  const _FactoryDistributionList(this.slices);

  final List<LcrPieSlice> slices;

  @override
  State<_FactoryDistributionList> createState() =>
      _FactoryDistributionListState();
}

class _FactoryDistributionListState extends State<_FactoryDistributionList> {
  late final ScrollController _scrollController;

  List<LcrPieSlice> get slices => widget.slices;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const Map<String, List<Color>> _namedGradients = {
    'F17': [Color(0xFF6DD5FA), Color(0xFF2980B9)],
    'F16': [Color(0xFFFFD26F), Color(0xFFFB8D34)],
    'B03': [Color(0xFFFF758C), Color(0xFFFED6E3)],
    'F06': [Color(0xFFFFB88C), Color(0xFFDE6262)],
  };

  static const List<List<Color>> _fallbackGradients = <List<Color>>[
    [Color(0xFF6DD5FA), Color(0xFF2980B9)],
    [Color(0xFFFFD26F), Color(0xFFFB8D34)],
    [Color(0xFFFF758C), Color(0xFFFED6E3)],
    [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    [Color(0xFF84FAB0), Color(0xFF00C6FB)],
    [Color(0xFFFFC3A0), Color(0xFFFFAFBD)],
  ];

  List<Color> _gradientFor(String label, int index) {
    final key = label.trim().toUpperCase();
    final mapped = _namedGradients[key];
    if (mapped != null) {
      return mapped;
    }
    return _fallbackGradients[index % _fallbackGradients.length];
  }

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white54)),
      );
    }

    final sorted = slices.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (prev, element) => prev + element.value);

    Widget _buildHeader() {
      return Center(
        child: Column(
          children: [
            Text(
              'TOTAL',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.cyanAccent.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    fontSize: 12,
                  ) ??
                  const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 6),
            _PulsingTotalBadge(total: total),
          ],
        ),
      );
    }

    Widget buildTile(int index) {
      final slice = sorted[index];
      final percent = total == 0 ? 0.0 : slice.value / total;
      final gradient = _gradientFor(slice.label, index);
      return _FactoryDistributionTile(
        label: slice.label,
        value: slice.value,
        percent: percent,
        gradient: gradient,
      );
    }

    const headerEstimate = 140.0;
    const tileEstimate = 72.0;
    final estimatedHeight =
        headerEstimate + (sorted.length * tileEstimate); // conservative

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : double.infinity;

        if (estimatedHeight <= maxHeight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              ...List.generate(sorted.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == sorted.length - 1 ? 0 : 12,
                  ),
                  child: buildTile(index),
                );
              }),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) => buildTile(index),
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FactoryDistributionTile extends StatelessWidget {
  const _FactoryDistributionTile({
    required this.label,
    required this.value,
    required this.percent,
    required this.gradient,
  });

  final String label;
  final int value;
  final double percent;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final percentText = (percent * 100).toStringAsFixed(1);
    return Tooltip(
      decoration: BoxDecoration(
        color: const Color(0xFF09264D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33092046),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      waitDuration: const Duration(milliseconds: 120),
      showDuration: const Duration(milliseconds: 3500),
      verticalOffset: 18,
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      richMessage: TextSpan(
        text: label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
        children: [
          const TextSpan(text: '\n'),
          TextSpan(
            text: '$value pcs',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          const TextSpan(text: '  •  '),
          TextSpan(
            text: '$percentText%',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '$percentText%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _GradientProgressBar(
            value: percent.clamp(0.0, 1.0),
            gradient: gradient,
          ),
          const SizedBox(height: 4),
          Text(
            '$value pcs',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PulsingTotalBadge extends StatefulWidget {
  const _PulsingTotalBadge({required this.total});

  final int total;

  @override
  State<_PulsingTotalBadge> createState() => _PulsingTotalBadgeState();
}

class _PulsingTotalBadgeState extends State<_PulsingTotalBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: 0.9,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        );

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332980B9),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Text(widget.total.toString(), style: textStyle),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: badge,
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({
    required this.value,
    required this.gradient,
  });

  final double value;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeValue = value.clamp(0.0, 1.0);
        final activeWidth = constraints.maxWidth * safeValue;

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white12.withOpacity(0.22),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  width: activeWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
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
}

class _StackedBarChart extends StatelessWidget {
  const _StackedBarChart(
    this.series, {
    this.rotateLabels = false,
    this.xLabelStyle,
    this.xLabelIntersectAction,
    this.maximumLabelWidth,
  });

  final LcrStackedSeries series;
  final bool rotateLabels;
  final TextStyle? xLabelStyle;
  final AxisLabelIntersectAction? xLabelIntersectAction;
  final double? maximumLabelWidth;

  static const LinearGradient _passGradient = LinearGradient(
    colors: [Color(0xFF21D4FD), Color(0xFF2152FF)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const LinearGradient _failGradient = LinearGradient(
    colors: [Color(0xFFFF9CCF), Color(0xFFFF3D7F)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  @override
  Widget build(BuildContext context) {
    if (series.categories.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white54)),
      );
    }
    final data = List.generate(series.categories.length, (index) {
      return _StackedBarItem(
        category: series.categories[index],
        pass: series.pass[index],
        fail: series.fail[index],
      );
    });

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipPosition: TooltipPosition.pointer,
        header: '',
        builder: (dynamic item, dynamic point, dynamic series, int pointIndex,
            int seriesIndex) {
          final bar = item as _StackedBarItem;
          return _BarTooltip(
            title: bar.category,
            pass: bar.pass,
            fail: bar.fail,
            yieldRate: bar.yieldRate,
          );
        },
      ),
      primaryXAxis: CategoryAxis(
        labelStyle: xLabelStyle ??
            const TextStyle(color: Colors.white70, fontSize: 12),
        majorGridLines: const MajorGridLines(width: 0),
        labelRotation: rotateLabels ? -45 : 0,
        labelIntersectAction:
            xLabelIntersectAction ?? AxisLabelIntersectAction.hide,
        maximumLabelWidth: maximumLabelWidth,
      ),
      primaryYAxis: NumericAxis(
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(color: Colors.white10.withOpacity(0.4)),
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: const TextStyle(color: Colors.white70),
      ),
      series: <CartesianSeries<dynamic, dynamic>>[
        StackedColumnSeries<dynamic, dynamic>(
          name: 'PASS',
          dataSource: data,
          xValueMapper: (item, _) => (item as _StackedBarItem).category,
          yValueMapper: (item, _) => (item as _StackedBarItem).pass,
          gradient: _passGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          width: 0.6,
          spacing: 0.2,
          legendIconType: LegendIconType.rectangle,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.outer,
            builder: (dynamic item, dynamic point, dynamic series,
                int pointIndex, int seriesIndex) {
              final bar = item as _StackedBarItem;
              final total = bar.pass + bar.fail;
              return Text(
                '$total',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        StackedColumnSeries<dynamic, dynamic>(
          name: 'FAIL',
          dataSource: data,
          xValueMapper: (item, _) => (item as _StackedBarItem).category,
          yValueMapper: (item, _) => (item as _StackedBarItem).fail,
          gradient: _failGradient,
          color: _EmployeeStatisticsChart._failColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          width: 0.6,
          spacing: 0.2,
          legendIconType: LegendIconType.rectangle,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.outer,
            builder: (dynamic item, dynamic point, dynamic series,
                int pointIndex, int seriesIndex) {
              final bar = item as _StackedBarItem;
              if (bar.fail <= 0) {
                return const SizedBox.shrink();
              }
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x33FF3D7F),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFFF5FA5),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    '${bar.fail}',
                    style: const TextStyle(
                      color: Color(0xFFFFD6EC),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmployeeStatisticsChart extends StatelessWidget {
  const _EmployeeStatisticsChart(this.series);

  final LcrStackedSeries series;

  static const _barGradient = LinearGradient(
    colors: [Color(0xFF1A6DFF), Color(0xFF40C4FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const _failGradient = LinearGradient(
    colors: [Color(0xFFFF77A9), Color(0xFFFF3D7F)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const _failColor = Color(0xFFFF3D7F);

  @override
  Widget build(BuildContext context) {
    if (series.categories.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white54)),
      );
    }

    final rows = List.generate(series.categories.length, (index) {
      final pass = series.pass[index];
      final fail = series.fail[index];
      return _EmployeeBarData(
        name: series.categories[index],
        pass: pass,
        fail: fail,
      );
    })
      ..sort((a, b) => b.total.compareTo(a.total));

    final maxTotal = rows.fold<int>(0, (maxValue, item) {
      return math.max(maxValue, item.total);
    });
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final item = rows[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _EmployeeStatBar(
            data: item,
            maxTotal: maxTotal == 0 ? 1 : maxTotal,
          ),
        );
      },
    );
  }
}


class _EmployeeStatBar extends StatefulWidget {
  const _EmployeeStatBar({required this.data, required this.maxTotal});

  final _EmployeeBarData data;
  final int maxTotal;

  @override
  State<_EmployeeStatBar> createState() => _EmployeeStatBarState();
}

class _EmployeeStatBarState extends State<_EmployeeStatBar> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _tooltipEntry;

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _toggleTooltip() {
    if (_tooltipEntry != null) {
      _removeTooltip();
    } else {
      _showTooltip();
    }
  }

  void _showTooltip() {
    final overlayState = Overlay.of(context);
    if (overlayState == null) return;

    _tooltipEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeTooltip,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, -60),
              child: Material(
                color: Colors.transparent,
                child: _BarTooltip(
                  title: widget.data.name,
                  pass: widget.data.pass,
                  fail: widget.data.fail,
                  yieldRate: widget.data.yieldRate,
                ),
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(_tooltipEntry!);
  }

  void _removeTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleTooltip,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                widget.data.name,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxTotal = widget.maxTotal == 0 ? 1 : widget.maxTotal;

                  Widget buildBar({
                    required String label,
                    required int value,
                    Gradient? gradient,
                    Color? color,
                  }) {
                    final widthFactor =
                        (value / maxTotal).clamp(0.0, 1.0).toDouble();
                    final barWidth = constraints.maxWidth * widthFactor;

                    return SizedBox(
                      height: 22,
                      child: Stack(
                        children: [
                          Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          if (barWidth > 0)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: barWidth,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: color,
                                  gradient: gradient,
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    value.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '($label)',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildBar(
                        label: 'PASS',
                        value: widget.data.pass,
                        gradient: _EmployeeStatisticsChart._barGradient,
                      ),
                      const SizedBox(height: 8),
                      buildBar(
                        label: 'FAIL',
                        value: widget.data.fail,
                        gradient: _EmployeeStatisticsChart._failGradient,
                        color: _EmployeeStatisticsChart._failColor,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeBarData {
  const _EmployeeBarData({
    required this.name,
    required this.pass,
    required this.fail,
  });

  final String name;
  final int pass;
  final int fail;

  int get total => pass + fail;
  double get yieldRate => total == 0 ? 0 : pass / total * 100;
}

class _BarTooltip extends StatelessWidget {
  const _BarTooltip({
    required this.title,
    required this.pass,
    required this.fail,
    required this.yieldRate,
  });

  final String title;
  final num pass;
  final num fail;
  final double yieldRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF021024).withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            _TooltipEntry(
              label: 'PASS',
              value: pass.toString(),
              color: Colors.cyanAccent,
            ),
            const SizedBox(height: 4),
            _TooltipEntry(
              label: 'FAIL',
              value: fail.toString(),
              color: _EmployeeStatisticsChart._failColor,
            ),
            const SizedBox(height: 4),
            _TooltipEntry(
              label: 'YIELD RATE',
              value: _formatYieldRate(yieldRate),
              color: Colors.amberAccent,
            ),
          ],
        ),
      ),
    );
  }

  String _formatYieldRate(double value) {
    if (value.isNaN || value.isInfinite) {
      return '0%';
    }
    final rounded = value.roundToDouble();
    final text = rounded == value
        ? rounded.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text%';
  }
}

class _TooltipEntry extends StatelessWidget {
  const _TooltipEntry({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Text(value),
      ],
    );
  }
}

class _OutputChart extends StatelessWidget {
  const _OutputChart(this.trend);

  final LcrOutputTrend trend;

  @override
  Widget build(BuildContext context) {
    if (trend.categories.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white54)),
      );
    }
    final data = List.generate(trend.categories.length, (index) {
      return _OutputItem(
        category: trend.categories[index],
        pass: trend.pass[index],
        fail: trend.fail[index],
        yr: trend.yieldRate[index],
      );
    });

    final maxOutput = data.fold<int>(0, (prev, item) {
      final value = item.total;
      return value > prev ? value : prev;
    });
    final double yMax;
    final double interval;
    if (maxOutput == 0) {
      yMax = 10;
      interval = 2;
    } else {
      final step = (maxOutput / 5).ceil().clamp(1, 1000);
      interval = step.toDouble();
      yMax = (step * 6).toDouble();
    }

    final annotations = <CartesianChartAnnotation>[
      if (data.isNotEmpty)
        CartesianChartAnnotation(
          widget: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.6)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                'Target (98%)',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          coordinateUnit: CoordinateUnit.point,
          x: data.last.category,
          y: 98,
          yAxisName: 'yrAxis',
          horizontalAlignment: ChartAlignment.far,
          verticalAlignment: ChartAlignment.near,
        ),
    ];

    return SfCartesianChart(
      margin: const EdgeInsets.fromLTRB(12, 18, 12, 12),
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      plotAreaBackgroundColor: Colors.transparent,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipPosition: TooltipPosition.pointer,
        header: '',
        builder: (dynamic item, dynamic point, dynamic series, int pointIndex,
            int seriesIndex) {
          if (item is! _OutputItem) {
            return const SizedBox.shrink();
          }
          return _BarTooltip(
            title: item.category,
            pass: item.pass,
            fail: item.fail,
            yieldRate: item.yr,
          );
        },
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineType: TrackballLineType.none,
        tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
        tooltipSettings: const InteractiveTooltip(enable: false),
        markerSettings: const TrackballMarkerSettings(
          markerVisibility: TrackballVisibilityMode.visible,
          height: 10,
          width: 10,
          borderWidth: 1.5,
          borderColor: Colors.black,
          color: Colors.amberAccent,
        ),
      ),
      legend: const Legend(isVisible: false),
      primaryXAxis: CategoryAxis(
        labelStyle: const TextStyle(
          color: Color(0xFFE8F4FF),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          shadows: [
            Shadow(
              color: Color(0x99000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        majorGridLines: const MajorGridLines(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        axisLine: AxisLine(color: Colors.white.withOpacity(0.25), width: 0.8),
        labelAlignment: LabelAlignment.center,
        labelIntersectAction: AxisLabelIntersectAction.multipleRows,
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: yMax,
        interval: interval,
        isVisible: false,
        majorGridLines: const MajorGridLines(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        axisLine: const AxisLine(width: 0),
      ),
      axes: <ChartAxis>[
        NumericAxis(
          name: 'yrAxis',
          minimum: 0,
          maximum: 100,
          isVisible: false,
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
        ),
      ],
      annotations: annotations,
      series: <CartesianSeries<dynamic, dynamic>>[
        ColumnSeries<dynamic, dynamic>(
          name: 'OUTPUT',
          dataSource: data,
          xValueMapper: (item, _) => (item as _OutputItem).category,
          yValueMapper: (item, _) => (item as _OutputItem).total,
          width: 0.58,
          spacing: 0.22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          gradient: const LinearGradient(
            colors: [Color(0xFF21D4FD), Color(0xFF2152FF)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.outer,
            builder: (dynamic item, dynamic point, dynamic series, int pointIndex,
                int seriesIndex) {
              final entry = item as _OutputItem;
              return Text(
                '${entry.total}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  shadows: [
                    Shadow(
                      color: Color(0xAA000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        LineSeries<dynamic, dynamic>(
          name: 'TARGET',
          dataSource: data,
          xValueMapper: (item, _) => (item as _OutputItem).category,
          yValueMapper: (_, __) => 98,
          yAxisName: 'yrAxis',
          color: Colors.greenAccent,
          width: 2,
          dashArray: const <double>[6, 6],
          markerSettings: const MarkerSettings(isVisible: false),
        ),
        SplineSeries<dynamic, dynamic>(
          name: 'YIELD RATE',
          dataSource: data,
          xValueMapper: (item, _) => (item as _OutputItem).category,
          yValueMapper: (item, _) => (item as _OutputItem).yr,
          yAxisName: 'yrAxis',
          color: Colors.amberAccent,
          width: 3,
          splineType: SplineType.monotonic,
          enableTooltip: true,
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            borderColor: Colors.black,
            borderWidth: 2,
            height: 10,
            width: 10,
          ),
          emptyPointSettings:
              const EmptyPointSettings(mode: EmptyPointMode.zero),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            builder: (dynamic item, dynamic point, dynamic series,
                int pointIndex, int seriesIndex) {
              final entry = item as _OutputItem;
              final value = entry.yr;
              final formatted = value == value.roundToDouble()
                  ? value.toInt().toString()
                  : value.toStringAsFixed(1);
              return Text(
                '$formatted%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  shadows: [
                    Shadow(
                      color: Color(0xAA000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MachinesGrid extends StatelessWidget {
  const _MachinesGrid(this.list);

  final List<LcrMachineGauge> list;

  @override
  Widget build(BuildContext context) {
    final map = {for (final gauge in list) gauge.machineNo: gauge};
    final machineNumbers = [1, 2, 3, 4];
    final cards = [
      for (final number in machineNumbers)
        map[number] ??
            LcrMachineGauge(
              machineNo: number,
              total: 0,
              pass: 0,
              fail: 0,
            ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == cards.length - 1 ? 0 : 16),
              child: LcrMachineCard(data: cards[i]),
            ),
          ),
      ],
    );
  }
}


class _AnalysisTab extends StatelessWidget {
  const _AnalysisTab({
    required this.controller,
    required this.searchController,
  });

  final LcrDashboardController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Serial Number Search',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.cyanAccent,
                          ),
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
                        ),
                        onChanged: controller.searchSerial,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Obx(() {
                          final RxList<LcrRecord> reactiveList =
                              controller.serialSearchResults.isNotEmpty
                                  ? controller.serialSearchResults
                                  : controller.analysisRecords;
                          final results = reactiveList.toList();
                          if (controller.isSearching.value) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(color: Colors.cyanAccent),
                            );
                          }
                          if (results.isEmpty) {
                            return const Center(
                              child: Text('No serial numbers',
                                  style: TextStyle(color: Colors.white54)),
                            );
                          }
                          return ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final record = results[index];
                              return _ResultTile(
                                record: record,
                                onTap: () => controller.selectRecord(record.id),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: Obx(() {
                    if (controller.isLoadingRecord.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.cyanAccent),
                      );
                    }
                    final record = controller.selectedRecord.value;
                    if (record == null) {
                      return const Center(
                        child: Text('Select a record to view details',
                            style: TextStyle(color: Colors.white54)),
                      );
                    }
                    return LcrRecordDetail(record: record);
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.record, required this.onTap});

  final LcrRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: const Color(0xFF03132D).withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        record.serialNumber ?? 'UNKNOWN',
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '${record.factory} • ${record.department ?? '-'}\n${record.employeeId ?? '-'}',
        style: const TextStyle(color: Colors.white60),
      ),
      trailing: Text(
        _fmt(record.dateTime),
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }

  String _fmt(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _StackedBarItem {
  const _StackedBarItem({
    required this.category,
    required this.pass,
    required this.fail,
  });

  final String category;
  final int pass;
  final int fail;

  double get yieldRate {
    final total = pass + fail;
    if (total == 0) {
      return 0;
    }
    return pass / total * 100;
  }
}

class _OutputItem {
  const _OutputItem({
    required this.category,
    required this.pass,
    required this.fail,
    required this.yr,
  });

  final String category;
  final int pass;
  final int fail;
  final double yr;

  int get total => pass + fail;
}

class _FilterDateRangeTile extends StatelessWidget {
  const _FilterDateRangeTile({
    required this.rangeLabel,
    required this.onPressed,
  });

  final String rangeLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1F3D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                rangeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.calendar_month, color: Colors.cyanAccent),
          ],
        ),
      ),
    );
  }
}

class _FilterSelection {
  const _FilterSelection({
    required this.factory,
    required this.department,
    required this.machine,
    required this.status,
    required this.dateRange,
  });

  final String factory;
  final String department;
  final String machine;
  final String status;
  final DateTimeRange dateRange;
}

class _FilterSheetDropdown extends StatelessWidget {
  const _FilterSheetDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF03132D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF03132D),
            underline: const SizedBox.shrink(),
            iconEnabledColor: Colors.cyanAccent,
            style: const TextStyle(color: Colors.white),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
