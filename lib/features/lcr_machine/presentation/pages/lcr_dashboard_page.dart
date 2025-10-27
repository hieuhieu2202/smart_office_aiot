import 'package:flutter/material.dart';
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
              IconButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final didPop = await navigator.maybePop();
                  final canGetPop = Get.key.currentState?.canPop() ?? false;
                  if (!didPop && canGetPop) {
                    Get.back<void>();
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              const SizedBox(width: 4),
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
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.controller});

  final LcrDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.dashboardView.value == null) {
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

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _SummaryRow(overview: data.overview),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 1400;
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                LcrChartCard(
                                  title: 'FACTORY DISTRIBUTION',
                                  height: 260,
                                  child: _FactoryDistributionSummary(data.factorySlices),
                                ),
                                const SizedBox(height: 20),
                                LcrChartCard(
                                  title: 'ERROR CODE',
                                  height: 260,
                                  child: _ErrorCodeSummary(data.errorSlices),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                LcrChartCard(
                                  title: 'MACHINE PERFORMANCE',
                                  height: 220,
                                  child: _MachinesGrid(data.machineGauges),
                                ),
                                const SizedBox(height: 20),
                                LcrChartCard(
                                  title: 'YIELD RATE & OUTPUT',
                                  height: 360,
                                  child: _OutputChart(data.outputTrend),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      LcrChartCard(
                        title: 'DEPARTMENT ANALYSIS',
                        height: 280,
                        child: _StackedBarChart(data.departmentSeries),
                      ),
                      const SizedBox(height: 20),
                      LcrChartCard(
                        title: 'TYPE ANALYSIS',
                        height: 280,
                        child: _StackedBarChart(data.typeSeries),
                      ),
                      const SizedBox(height: 20),
                      LcrChartCard(
                        title: 'EMPLOYEE STATISTICS',
                        height: 280,
                        child: _StackedBarChart(data.employeeSeries, rotateLabels: true),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          LcrChartCard(
                            title: 'FACTORY DISTRIBUTION',
                            height: 260,
                            child: _FactoryDistributionSummary(data.factorySlices),
                          ),
                          const SizedBox(height: 20),
                          LcrChartCard(
                            title: 'ERROR CODE',
                            height: 260,
                            child: _ErrorCodeSummary(data.errorSlices),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          LcrChartCard(
                            title: 'MACHINE PERFORMANCE',
                            height: 220,
                            child: _MachinesGrid(data.machineGauges),
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
                      flex: 4,
                      child: Column(
                        children: [
                          LcrChartCard(
                            title: 'DEPARTMENT ANALYSIS',
                            height: 280,
                            child: _StackedBarChart(data.departmentSeries),
                          ),
                          const SizedBox(height: 20),
                          LcrChartCard(
                            title: 'TYPE ANALYSIS',
                            height: 280,
                            child: _StackedBarChart(data.typeSeries),
                          ),
                          const SizedBox(height: 20),
                          LcrChartCard(
                            title: 'EMPLOYEE STATISTICS',
                            height: 280,
                            child: _StackedBarChart(
                              data.employeeSeries,
                              rotateLabels: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
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

class _FactoryDistributionSummary extends StatelessWidget {
  const _FactoryDistributionSummary(this.slices);

  final List<LcrPieSlice> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white54)),
      );
    }
    return _CompactCategoryList(
      slices: slices,
      totalLabel: 'TOTAL FACTORIES',
      emptyLabel: 'No data',
    );
  }
}

class _ErrorCodeSummary extends StatelessWidget {
  const _ErrorCodeSummary(this.slices);

  final List<LcrPieSlice> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white54)),
      );
    }

    final List<LcrPieSlice> ordered = [];
    final noErrorIndex =
    slices.indexWhere((slice) => slice.label.toUpperCase() == 'NO ERROR');
    if (noErrorIndex != -1) {
      ordered.add(slices[noErrorIndex]);
    }
    ordered.addAll(slices
        .where((slice) => slice.label.toUpperCase() != 'NO ERROR')
        .toList());

    return _CompactCategoryList(
      slices: ordered,
      totalLabel: 'TOTAL RECORDS',
      emptyLabel: 'No data',
      emphasize: (slice) => slice.label.toUpperCase() == 'NO ERROR',
    );
  }
}

class _CompactCategoryList extends StatelessWidget {
  const _CompactCategoryList({
    required this.slices,
    required this.totalLabel,
    required this.emptyLabel,
    this.emphasize,
  });

  final List<LcrPieSlice> slices;
  final String totalLabel;
  final String emptyLabel;
  final bool Function(LcrPieSlice slice)? emphasize;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: const TextStyle(color: Colors.white54)),
      );
    }

    final total = slices.fold<int>(0, (prev, slice) => prev + slice.value);
    final displayLimit = 4;
    final display = slices.take(displayLimit).toList();
    final displayedTotal =
    display.fold<int>(0, (prev, slice) => prev + slice.value);
    final othersValue = total - displayedTotal;
    if (othersValue > 0) {
      display.add(LcrPieSlice(label: 'OTHERS', value: othersValue));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final estimatedHeight = display.length * 60;
        final enableScroll = estimatedHeight > constraints.maxHeight;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TotalBadge(
              label: totalLabel,
              value: total.toString(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: display.length,
                physics: enableScroll
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final slice = display[index];
                  final double percent =
                  total == 0 ? 0.0 : (slice.value / total) * 100.0;
                  return _CategoryProgressTile(
                    label: slice.label,
                    value: slice.value,
                    percent: percent,
                    color: _tileColor(index),
                    emphasize: emphasize?.call(slice) ?? false,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Color _tileColor(int index) {
    const colors = [
      Color(0xFF1BE7FF),
      Color(0xFF6C5DD3),
      Color(0xFF23D5AB),
      Color(0xFFFFC75F),
      Color(0xFFFF6B6B),
    ];
    return colors[index % colors.length];
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF06274A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryProgressTile extends StatelessWidget {
  const _CategoryProgressTile({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final int value;
  final double percent;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final double normalizedPercent;
    if (percent <= 0) {
      normalizedPercent = 0.0;
    } else if (percent >= 100) {
      normalizedPercent = 1.0;
    } else {
      normalizedPercent = percent / 100.0;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value.toString(),
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: normalizedPercent,
            minHeight: 8,
            backgroundColor: const Color(0xFF0A274F),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
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

    return SfCartesianChart3D(
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
      series: <ChartSeries<dynamic, dynamic>>[
        StackedColumnSeries3D<dynamic, dynamic>(
          name: 'PASS',
          dataSource: data,
          xValueMapper: (item, _) => (item as _StackedBarItem).category,
          yValueMapper: (item, _) => (item as _StackedBarItem).pass,
          color: Colors.cyanAccent,
        ),
        StackedColumnSeries3D<dynamic, dynamic>(
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

    return SfCartesianChart3D(
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
      series: <ChartSeries<dynamic, dynamic>>[
        StackedColumnSeries3D<dynamic, dynamic>(
          name: 'PASS',
          dataSource: data,
          xValueMapper: (item, _) => (item as _OutputItem).category,
          yValueMapper: (item, _) => (item as _OutputItem).pass,
          color: Colors.cyanAccent,
        ),
        StackedColumnSeries3D<dynamic, dynamic>(
          name: 'FAIL',
          dataSource: data,
          xValueMapper: (item, _) => (item as _OutputItem).category,
          yValueMapper: (item, _) => (item as _OutputItem).fail,
          color: Colors.pinkAccent,
        ),
        SplineSeries3D<dynamic, dynamic>(
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
    return Padding(
      padding: const EdgeInsets.all(24),
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
                        child: CircularProgressIndicator(color: Colors.cyanAccent),
                      );
                    }
                    if (results.isEmpty) {
                      return const Center(
                        child: Text('No serial numbers', style: TextStyle(color: Colors.white54)),
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
