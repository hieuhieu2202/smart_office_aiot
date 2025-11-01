import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/automation_resistor_dashboard_controller.dart';
import '../viewmodels/resistor_dashboard_view_state.dart';
import '../widgets/resistor_combo_chart.dart';
import '../widgets/resistor_filters_bar.dart';
import '../widgets/resistor_status_table.dart';
import '../widgets/resistor_summary_pie.dart';
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

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      AutomationResistorDashboardController(),
      tag: 'AUTOMATION_RESISTOR_DASHBOARD',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Obx(
            () => Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: controller.isLoading.value
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.cyanAccent,
                          ),
                        )
                      : _DashboardBody(controller: controller),
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
          return Column(
            crossAxisAlignment:
                isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'AUTOMATION RESISTOR MACHINE DASHBOARD',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => controller.loadDashboard(),
                    icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ResistorFiltersBar(
                machineOptions: controller.machineNames,
                selectedMachine: controller.selectedMachine.value,
                onMachineChanged: controller.updateMachine,
                selectedShift: controller.selectedShift.value,
                onShiftChanged: controller.updateShift,
                selectedStatus: controller.selectedStatus.value,
                onStatusChanged: controller.updateStatus,
                dateRange: controller.selectedRange.value,
                onSelectDate: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                    initialDateRange: controller.selectedRange.value,
                    helpText: 'Select tracking range',
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.cyanAccent,
                            surface: Color(0xFF04102A),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    controller.updateRange(picked);
                  }
                },
              ),
            ],
          );
        },
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _SummarySection(view: view),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF04142F).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.blueGrey.shade800),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: ResistorSummaryPie(slices: view.summarySlices),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 7,
            child: Row(
              children: [
                Expanded(
                  child: ResistorComboChart(
                    title: 'OUTPUT BY SECTION',
                    series: view.sectionSeries,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: ResistorComboChart(
                    title: 'MACHINE DISTRIBUTION',
                    series: view.machineSeries,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF021024).withOpacity(0.9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blueGrey.shade900),
              ),
              padding: const EdgeInsets.all(16),
              child: Obx(
                () => ResistorStatusTable(
                  records: controller.statusEntries,
                  isLoading: controller.isLoadingStatus.value,
                  onTap: (item) async {
                    await controller.loadRecordDetail(item.id);
                    await _showRecordDialog(context, controller);
                  },
                ),
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          _SummarySection(view: view),
          const SizedBox(height: 20),
          SizedBox(
            height: 260,
            child: ResistorSummaryPie(slices: view.summarySlices),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: ResistorComboChart(
              title: 'OUTPUT BY SECTION',
              series: view.sectionSeries,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: ResistorComboChart(
              title: 'MACHINE DISTRIBUTION',
              series: view.machineSeries,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF021024).withOpacity(0.9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blueGrey.shade900),
              ),
              padding: const EdgeInsets.all(16),
              child: Obx(
                () => ResistorStatusTable(
                  records: controller.statusEntries,
                  isLoading: controller.isLoadingStatus.value,
                  onTap: (item) async {
                    await controller.loadRecordDetail(item.id);
                    await _showRecordDialog(context, controller);
                  },
                ),
              ),
            ),
          ),
        ],
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
          height: 220,
          child: ResistorSummaryPie(slices: view.summarySlices),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ResistorComboChart(
            title: 'OUTPUT BY SECTION',
            series: view.sectionSeries,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ResistorComboChart(
            title: 'MACHINE DISTRIBUTION',
            series: view.machineSeries,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF021024).withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blueGrey.shade900),
          ),
          padding: const EdgeInsets.all(16),
          child: Obx(
            () => SizedBox(
              height: 400,
              child: ResistorStatusTable(
                records: controller.statusEntries,
                isLoading: controller.isLoadingStatus.value,
                onTap: (item) async {
                  await controller.loadRecordDetail(item.id);
                  await _showRecordDialog(context, controller);
                },
              ),
            ),
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
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: view.summaryTiles
          .map(
            (tile) => SizedBox(
              width: 220,
              height: 120,
              child: ResistorSummaryTile(data: tile),
            ),
          )
          .toList(),
    );
  }
}

Future<void> _showRecordDialog(
  BuildContext context,
  AutomationResistorDashboardController controller,
) async {
  final record = controller.selectedRecord.value;
  if (record == null) return;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF04142F),
        title: Text(
          'Record #${record.id}',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow('Machine', record.machineName),
                _InfoRow('Serial', record.serialNumber ?? '-'),
                _InfoRow('Work Date', record.workDate),
                _InfoRow('Station', '${record.stationSequence}'),
                _InfoRow('Pass Qty', '${record.passQty}'),
                _InfoRow('Fail Qty', '${record.failQty}'),
                _InfoRow('Employee', record.employeeId ?? '-'),
                if (controller.recordTestResults.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Test Results',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final test in controller.recordTestResults)
                    _InfoRow(
                      'Address ${test.address}',
                      test.result ? 'PASS' : 'FAIL',
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
