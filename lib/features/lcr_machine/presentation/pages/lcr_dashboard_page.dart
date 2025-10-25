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
                    Tab(text: 'ANALYSIS'),
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
              const Icon(Icons.memory, color: Colors.cyanAccent, size: 28),
              const SizedBox(width: 12),
              Text(
                'LCR MACHINE DASHBOARD',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => controller.loadTrackingData(),
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
                      '${_fmt(range.start)} → ${_fmt(range.end)}',
                      style: const TextStyle(color: Colors.white),
                    );
                  }),
                  onPressed: () async {
                    final current = controller.selectedDateRange.value;
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: current,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Colors.cyan,
                              surface: Color(0xFF03132D),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      controller.updateDateRange(picked);
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

  String _fmt(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.controller});

  final LcrDashboardController controller;

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
                  flex: 3,
                  child: Column(
                    children: [
                      LcrChartCard(
                        title: 'FACTORY DISTRIBUTION',
                        height: 320,
                        child: _FactoryPieChart(data.factorySlices),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 420,
                        child: Column(
                          children: [
                            Expanded(
                              child: LcrChartCard(
                                title: 'DEPARTMENT ANALYSIS',
                                child: _StackedBarChart(data.departmentSeries),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: LcrChartCard(
                                title: 'TYPE ANALYSIS',
                                child: _StackedBarChart(data.typeSeries),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 160,
                        child: Row(
                          children: [
                            Expanded(
                              child: LcrChartCard(
                                title: 'MACHINE PERFORMANCE',
                                child: _MachinesGrid(data.machineGauges),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      LcrChartCard(
                        title: 'YIELD RATE & OUTPUT',
                        height: 420,
                        child: _OutputChart(data.outputTrend),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      LcrChartCard(
                        title: 'ERROR CODE',
                        height: 320,
                        child: _ErrorPieChart(data.errorSlices),
                      ),
                      const SizedBox(height: 20),
                      LcrChartCard(
                        title: 'EMPLOYEE STATISTICS',
                        height: 320,
                        child: _StackedBarChart(data.employeeSeries, rotateLabels: true),
                      ),
                    ],
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

class _FactoryPieChart extends StatelessWidget {
  const _FactoryPieChart(this.slices);

  final List<LcrPieSlice> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white54)),
      );
    }
    return SfCircularChart(
      legend: Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
        textStyle: const TextStyle(color: Colors.white70),
      ),
      series: <DoughnutSeries<LcrPieSlice, String>>[
        DoughnutSeries<LcrPieSlice, String>(
          dataSource: slices,
          xValueMapper: (slice, _) => slice.label,
          yValueMapper: (slice, _) => slice.value,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: Colors.white),
          ),
          explode: true,
          explodeOffset: '2%',
          innerRadius: '55%',
        ),
      ],
      annotations: <CircularChartAnnotation>[
        CircularChartAnnotation(
          widget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TOTAL', style: TextStyle(color: Colors.white54)),
              Text(
                slices.fold<int>(0, (prev, e) => prev + e.value).toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorPieChart extends StatelessWidget {
  const _ErrorPieChart(this.slices);

  final List<LcrPieSlice> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white54)),
      );
    }
    final topSlices = slices.take(8).toList();
    return SfCircularChart(
      legend: Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
        textStyle: const TextStyle(color: Colors.white70),
      ),
      series: <DoughnutSeries<LcrPieSlice, String>>[
        DoughnutSeries<LcrPieSlice, String>(
          dataSource: topSlices,
          xValueMapper: (slice, _) => slice.label,
          yValueMapper: (slice, _) => slice.value,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: Colors.white),
          ),
          innerRadius: '60%',
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
        ),
        StackedColumnSeries<dynamic, dynamic>(
          name: 'FAIL',
          dataSource: data,
          xValueMapper: (item, _) => (item as _StackedBarItem).category,
          yValueMapper: (item, _) => (item as _StackedBarItem).fail,
          color: Colors.pinkAccent,
        ),
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

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: const TextStyle(color: Colors.white70),
      ),
      primaryXAxis: CategoryAxis(
        labelStyle: const TextStyle(color: Colors.white70),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: const TextStyle(color: Colors.white70),
        majorGridLines: MajorGridLines(color: Colors.white10.withOpacity(0.2)),
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
        ),
      ],
      series: <CartesianSeries<dynamic, dynamic>>[
        StackedColumnSeries<dynamic, dynamic>(
          name: 'PASS',
          dataSource: data,
          xValueMapper: (item, _) => (item as _OutputItem).category,
          yValueMapper: (item, _) => (item as _OutputItem).pass,
          color: Colors.cyanAccent,
        ),
        StackedColumnSeries<dynamic, dynamic>(
          name: 'FAIL',
          dataSource: data,
          xValueMapper: (item, _) => (item as _OutputItem).category,
          yValueMapper: (item, _) => (item as _OutputItem).fail,
          color: Colors.pinkAccent,
        ),
        SplineSeries<dynamic, dynamic>(
          name: 'YIELD RATE',
          dataSource: data,
          xValueMapper: (item, _) => (item as _OutputItem).category,
          yValueMapper: (item, _) => (item as _OutputItem).yr,
          yAxisName: 'yrAxis',
          color: Colors.amberAccent,
          width: 2,
          markerSettings: const MarkerSettings(isVisible: true),
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
    if (list.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white54)),
      );
    }
    return GridView.builder(
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final gauge = list[index];
        return LcrMachineCard(data: gauge);
      },
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
                  ),
                  onChanged: controller.searchSerial,
                ),
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
