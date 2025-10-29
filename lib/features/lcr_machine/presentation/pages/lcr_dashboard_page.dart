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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Get.back<void>();
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white70, size: 20),
                splashRadius: 22,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.memory, color: Colors.cyanAccent, size: 28),
              const SizedBox(width: 12),
              Text(
                'LCR MACHINE',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => controller.resetToCurrentShiftAndReload(),
                icon: const Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'DATE RANGE',
                  value: Obx(() {
                    final range = controller.selectedDateRange.value;
                    return Text(
                      _formatRangeLabel(range),
                      style: const TextStyle(color: Colors.white),
                    );
                  }),
                  onPressed: () async {
                    final current = controller.selectedDateRange.value;
                    final picked =
                        await _pickDashboardDateTimeRange(context, current);
                    if (picked != null) {
                      await controller.updateDateRange(picked);
                    }
                  },
                ),
                const SizedBox(width: 12),
                Obx(() {
                  final list = ['ALL', ...controller.factories.map((e) => e.name)];
                  return _DropdownFilter(
                    label: 'FACTORY',
                    value: controller.selectedFactory.value,
                    items: list,
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateFactory(value);
                      }
                    },
                  );
                }),
                const SizedBox(width: 12),
                Obx(() {
                  final list = ['ALL', ...controller.departments.map((e) => e.name)];
                  return _DropdownFilter(
                    label: 'DEPARTMENT',
                    value: controller.selectedDepartment.value,
                    items: list,
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateDepartment(value);
                      }
                    },
                  );
                }),
                const SizedBox(width: 12),
                Obx(() {
                  final machineItems = <String>['ALL',
                    ...controller.machines.map((e) => e.toString()),
                  ];
                  return _DropdownFilter(
                    label: 'MACHINE',
                    value: controller.selectedMachine.value,
                    items: machineItems,
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateMachine(value);
                      }
                    },
                  );
                }),
                const SizedBox(width: 12),
                Obx(() {
                  return _DropdownFilter(
                    label: 'STATUS',
                    value: controller.selectedStatus.value,
                    items: const ['ALL', 'PASS', 'FAIL'],
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateStatus(value);
                      }
                    },
                  );
                }),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => controller.loadTrackingData(),
                  icon: const Icon(Icons.search),
                  label: const Text(
                    'QUERY',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF052043),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
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

  double _machinePerformanceHeight(int itemCount) {
    if (itemCount <= 0) {
      return 300.0;
    }
    if (itemCount <= 4) {
      return 300.0;
    }
    if (itemCount <= 8) {
      return 360.0;
    }
    return 480.0;
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

          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryRow(overview: data.overview),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: LcrChartCard(
                            title: 'FACTORY DISTRIBUTION',
                            height: 300,
                            child: _FactoryDistributionList(
                              data.factorySlices,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 6,
                          child: LcrChartCard(
                            title: 'MACHINE PERFORMANCE',
                            height: _machinePerformanceHeight(
                              data.machineGauges.length,
                            ),
                            child: _MachinesGrid(data.machineGauges),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: LcrChartCard(
                            title: 'EMPLOYEE STATISTICS',
                            height: 300,
                            child: _EmployeeStatisticsChart(
                              data.employeeSeries,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: LcrChartCard(
                            title: 'DEPARTMENT ANALYSIS',
                            height: 280,
                            child: _StackedBarChart(data.departmentSeries),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: LcrChartCard(
                            title: 'YIELD RATE & OUTPUT',
                            height: 360,
                            child: _OutputChart(data.outputTrend),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: LcrChartCard(
                            title: 'TYPE ANALYSIS',
                            height: 280,
                            child: _StackedBarChart(data.typeSeries),
                          ),
                        ),
                      ],
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
  const _SummaryRow({required this.overview});

  final LcrOverview overview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LcrSummaryTile(
            title: 'INPUT',
            value: overview.total.toString(),
            suffix: 'PCS',
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LcrSummaryTile(
            title: 'PASS',
            value: overview.pass.toString(),
            suffix: 'PCS',
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LcrSummaryTile(
            title: 'FAIL',
            value: overview.fail.toString(),
            suffix: 'PCS',
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LcrSummaryTile(
            title: 'Y.R',
            value: overview.yieldRate.toStringAsFixed(2),
            suffix: '%',
            color: Colors.amberAccent,
          ),
        ),
      ],
    );
  }
}

class _FactoryDistributionList extends StatelessWidget {
  const _FactoryDistributionList(this.slices);

  final List<LcrPieSlice> slices;

  static const _palette = <Color>[
    Color(0xFF4DD0E1),
    Color(0xFFFFF59D),
    Color(0xFFF48FB1),
    Color(0xFF82B1FF),
    Color(0xFFB39DDB),
    Color(0xFF80CBC4),
  ];

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOTAL',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          total.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: sorted.length,
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final slice = sorted[index];
              final percent = total == 0 ? 0.0 : slice.value / total;
              final color = _palette[index % _palette.length];
              return _FactoryDistributionTile(
                label: slice.label,
                value: slice.value,
                percent: percent,
                color: color,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FactoryDistributionTile extends StatelessWidget {
  const _FactoryDistributionTile({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final int value;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(percent * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white12,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value pcs',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class _StackedBarChart extends StatelessWidget {
  const _StackedBarChart(this.series, {this.rotateLabels = false});

  final LcrStackedSeries series;
  final bool rotateLabels;

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
          );
        },
      ),
      primaryXAxis: CategoryAxis(
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        majorGridLines: const MajorGridLines(width: 0),
        labelRotation: rotateLabels ? -45 : 0,
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
          color: Colors.cyanAccent,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            builder: (dynamic item, dynamic point, dynamic series,
                int pointIndex, int seriesIndex) {
              final bar = item as _StackedBarItem;
              final total = bar.pass + bar.fail;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('$total'),
              );
            },
          ),
        ),
        StackedColumnSeries<dynamic, dynamic>(
          name: 'FAIL',
          dataSource: data,
          xValueMapper: (item, _) => (item as _StackedBarItem).category,
          yValueMapper: (item, _) => (item as _StackedBarItem).fail,
          color: Colors.pinkAccent,
          dataLabelSettings: const DataLabelSettings(isVisible: false),
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
    final widthFactor =
        widget.data.total == 0 ? 0.0 : widget.data.total / widget.maxTotal;
    final totalLabel = widget.data.total.toString();
    final double clampedFactor = widthFactor.clamp(0.0, 1.0).toDouble();

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleTooltip,
        child: Row(
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
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: clampedFactor,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: _EmployeeStatisticsChart._barGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          totalLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
  });

  final String title;
  final num pass;
  final num fail;

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
            _TooltipEntry(label: 'PASS', value: pass, color: Colors.cyanAccent),
            const SizedBox(height: 4),
            _TooltipEntry(label: 'FAIL', value: fail, color: Colors.pinkAccent),
          ],
        ),
      ),
    );
  }
}

class _TooltipEntry extends StatelessWidget {
  const _TooltipEntry({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final num value;
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
        Text(value.toString()),
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

    final annotations = <CartesianChartAnnotation>[];
    if (data.isNotEmpty) {
      annotations.add(
        CartesianChartAnnotation(
          widget: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Target (98%)',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          coordinateUnit: CoordinateUnit.point,
          x: data.last.category,
          y: 98,
          yAxisName: 'yrAxis',
        ),
      );
    }

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      plotAreaBackgroundColor: const Color(0x1A2B3A5A),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipPosition: TooltipPosition.pointer,
        header: '',
        builder: (dynamic item, dynamic point, dynamic series, int pointIndex,
            int seriesIndex) {
          if (item is! _OutputItem ||
              series is! ColumnSeries<dynamic, dynamic>) {
            return const SizedBox.shrink();
          }
          return _BarTooltip(
            title: item.category,
            pass: item.pass,
            fail: item.fail,
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
        labelStyle: const TextStyle(color: Colors.white70),
        majorGridLines: const MajorGridLines(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        axisLine: AxisLine(color: Colors.white24.withOpacity(0.35)),
        labelAlignment: LabelAlignment.center,
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: yMax,
        interval: interval,
        labelStyle: const TextStyle(color: Colors.white70),
        majorGridLines: MajorGridLines(color: Colors.white10.withOpacity(0.2)),
        majorTickLines: const MajorTickLines(size: 0),
        axisLine: const AxisLine(width: 0),
      ),
      axes: <ChartAxis>[
        NumericAxis(
          name: 'yrAxis',
          minimum: 0,
          maximum: 100,
          labelStyle: const TextStyle(color: Colors.amberAccent),
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelFormat: '{value}%',
          plotBands: <PlotBand>[
            PlotBand(
              start: 98,
              end: 98,
              borderWidth: 1,
              borderColor: Colors.greenAccent.withOpacity(0.7),
              dashArray: const <double>[4, 6],
              shouldRenderAboveSeries: true,
            ),
          ],
        ),
      ],
      annotations: annotations,
      series: <CartesianSeries<dynamic, dynamic>>[
        ColumnSeries<dynamic, dynamic>(
          name: 'OUTPUT',
          dataSource: data,
          xValueMapper: (item, _) => (item as _OutputItem).category,
          yValueMapper: (item, _) => (item as _OutputItem).total,
          width: 0.6,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
          gradient: const LinearGradient(
            colors: [Color(0xFF21D4FD), Color(0xFF2152FF)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.outer,
            textStyle: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.w700,
            ),
            builder: (dynamic item, dynamic point, dynamic series, int pointIndex,
                int seriesIndex) {
              final entry = item as _OutputItem;
              return Text(
                '${entry.total}',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        SplineSeries<dynamic, dynamic>(
          name: 'YIELD RATE',
          dataSource: data,
          xValueMapper: (item, _) => (item as _OutputItem).category,
          yValueMapper: (item, _) => (item as _OutputItem).yr,
          yAxisName: 'yrAxis',
          color: Colors.amberAccent,
          width: 2,
          enableTooltip: false,
          markerSettings: const MarkerSettings(
            isVisible: false,
            shape: DataMarkerType.circle,
            borderColor: Colors.black,
            borderWidth: 1.5,
            height: 10,
            width: 10,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: const TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
            builder: (dynamic item, dynamic point, dynamic series,
                int pointIndex, int seriesIndex) {
              final entry = item as _OutputItem;
              final value = entry.yr;
              final formatted = value == value.roundToDouble()
                  ? value.toInt().toString()
                  : value.toStringAsFixed(1);
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xAA041026),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  child: Text(
                    '$formatted%',
                    style: const TextStyle(
                      color: Colors.amberAccent,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final Widget value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.cyanAccent,
            side: const BorderSide(color: Colors.cyanAccent),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onPressed,
          icon: const Icon(Icons.calendar_month),
          label: value,
        ),
      ],
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  const _DropdownFilter({
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
            color: Colors.white60,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF03132D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF03132D),
            underline: const SizedBox.shrink(),
            iconEnabledColor: Colors.cyanAccent,
            items: items
                .map((item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
