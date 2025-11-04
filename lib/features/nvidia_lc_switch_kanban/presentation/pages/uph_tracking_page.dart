import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../controllers/uph_tracking_controller.dart';
import '../viewmodels/uph_tracking_view_state.dart';
import '../widgets/filter_panel.dart';

class UphTrackingPage extends StatefulWidget {
  const UphTrackingPage({
    super.key,
    this.initialModelSerial = 'SWITCH',
  });

  final String initialModelSerial;

  @override
  State<UphTrackingPage> createState() => _UphTrackingPageState();
}

class _UphTrackingPageState extends State<UphTrackingPage> {
  late final UphTrackingController _controller;
  late DateTime _selectedDate;
  late String _selectedShift;
  late List<String> _selectedModels;
  late String _selectedSerial;
  Worker? _groupsWorker;

  static const _serialOptions = <String>['SWITCH', 'ADAPTER'];
  static const _shiftOptions = <String>['ALL', 'DAY', 'NIGHT'];
  static const _pageBackground = Color(0xFF0B1422);

  @override
  void initState() {
    super.initState();

    final desiredSerial = widget.initialModelSerial.trim().isEmpty
        ? 'SWITCH'
        : widget.initialModelSerial.trim().toUpperCase();

    _controller = Get.isRegistered<UphTrackingController>()
        ? Get.find<UphTrackingController>()
        : Get.put(UphTrackingController(initialModelSerial: desiredSerial));

    _selectedSerial = _controller.modelSerial.value;
    _selectedDate = _controller.date.value;
    _selectedShift = _controller.shift.value;
    _selectedModels = _controller.selectedGroups.toList();

    _groupsWorker = ever<List<String>>(_controller.selectedGroups, (list) {
      if (!mounted) return;
      setState(() {
        _selectedModels = List<String>.from(list);
      });
    });

    if (_controller.modelSerial.value != desiredSerial) {
      Future.microtask(() {
        _controller.updateFilters(
          newModelSerial: desiredSerial,
          reload: false,
        );
      });
    }

    if (_controller.allGroups.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.ensureModels(force: true, selectAll: true);
      });
    }
  }

  @override
  void dispose() {
    _groupsWorker?.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openModelPicker() async {
    await _controller.ensureModels(force: true);
    final allModels = _controller.allGroups.toList();
    if (allModels.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có model để lựa chọn.')),
      );
      return;
    }

    final result = await showOtModelPicker(
      context: context,
      allModels: allModels,
      initialSelection: _selectedModels.toSet(),
    );

    if (result != null) {
      setState(() {
        _selectedModels = result.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    }
  }

  Future<void> _onQuery() async {
    try {
      await _controller.updateFilters(
        newModelSerial: _selectedSerial,
        newDate: _selectedDate,
        newShift: _selectedShift,
        newGroups: _selectedModels,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải dữ liệu: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  double _calcLineBalance(UphTrackingViewState view) {
    if (view.rows.isEmpty) return 0;
    final passes = view.rows.map((row) => row.totalPass).toList();
    if (passes.isEmpty) return 0;
    final max = passes.reduce((a, b) => a > b ? a : b);
    if (max == 0) return 0;
    final threshold = max > 1000 ? (max * 30) / 100 : (max * 20) / 100;
    final filtered = passes.where((value) => value > threshold).toList();
    if (filtered.isEmpty) return 0;
    final total = filtered.fold<int>(0, (sum, value) => sum + value);
    return ((total / max) * 100) / filtered.length;
  }

  Widget _buildTable(UphTrackingViewState view, bool isMobile) {
    final numberFormat = NumberFormat('#,##0');
    final prFormat = NumberFormat('##0.0');
    final lineBalance = _calcLineBalance(view);
    final lineBalanceText =
        lineBalance <= 0 ? '-' : '${lineBalance.toStringAsFixed(2)}%';

    final columns = <DataColumn>[
      const DataColumn(label: Text('MODEL')),
      const DataColumn(label: Text('STATION')),
      const DataColumn(label: Text('WIP')),
      const DataColumn(label: Text('PASS')),
      const DataColumn(label: Text('UPH')),
      const DataColumn(label: Text('LINE BALANCE')),
    ];

    for (final section in view.sections) {
      columns.add(DataColumn(label: Text('$section PASS')));
      columns.add(DataColumn(label: Text('$section PRODUCTIVITY')));
    }

    final modelText = view.models.isEmpty
        ? '-'
        : view.models.map((m) => m.trim()).where((m) => m.isNotEmpty).join('\n');

    final rows = view.rows.map((row) {
      final cells = <DataCell>[
        DataCell(Text(modelText, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(row.station, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(numberFormat.format(row.wip),
            style: const TextStyle(color: Colors.lightBlueAccent))),
        DataCell(Text(numberFormat.format(row.totalPass),
            style: const TextStyle(color: Colors.greenAccent))),
        DataCell(Text(prFormat.format(row.uph),
            style: const TextStyle(color: Colors.amberAccent))),
        DataCell(Text(lineBalanceText,
            style: const TextStyle(fontWeight: FontWeight.w600))),
      ];

      for (int i = 0; i < view.sections.length; i++) {
        final passValue = i < row.passSeries.length ? row.passSeries[i] : 0;
        final prValue = i < row.productivitySeries.length ? row.productivitySeries[i] : 0;

        cells.add(DataCell(Text(
          passValue <= 0 ? '-' : numberFormat.format(passValue.round()),
          style: TextStyle(
            color: passValue > 0 ? Colors.greenAccent : Colors.white,
          ),
        )));

        final prString = prValue <= 0 ? '-' : '${prFormat.format(prValue)}%';
        Color textColor;
        if (prValue >= 95) {
          textColor = Colors.lightGreenAccent;
        } else if (prValue >= 80) {
          textColor = Colors.amberAccent;
        } else if (prValue > 0) {
          textColor = Colors.redAccent;
        } else {
          textColor = Colors.white;
        }
        cells.add(DataCell(Text(prString, style: TextStyle(color: textColor))));
      }

      return DataRow(cells: cells);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: isMobile ? 960 : 1280),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF152238)),
          dataRowColor: WidgetStateProperty.all(const Color(0x66122334)),
          columnSpacing: 28,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isMobile, bool isTablet) {
    final labelStyle = TextStyle(
      color: Colors.white.withOpacity(0.85),
      fontWeight: FontWeight.w600,
    );

    Widget buildField({required String label, required Widget child}) {
      return Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
    }

    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white38),
    );

    return Wrap(
      alignment: WrapAlignment.start,
      runSpacing: 12,
      children: [
        buildField(
          label: 'Model Serial',
          child: DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF152238),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white30),
              ),
              child: DropdownButton<String>(
                value: _selectedSerial,
                dropdownColor: const Color(0xFF152238),
                items: _serialOptions
                    .map((serial) => DropdownMenuItem(
                          value: serial,
                          child: Text(serial),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedSerial = value);
                },
              ),
            ),
          ),
        ),
        buildField(
          label: 'Date',
          child: OutlinedButton.icon(
            style: buttonStyle,
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(_formatDate(_selectedDate)),
          ),
        ),
        buildField(
          label: 'Shift',
          child: DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF152238),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white30),
              ),
              child: DropdownButton<String>(
                value: _selectedShift,
                dropdownColor: const Color(0xFF152238),
                items: _shiftOptions
                    .map((shift) => DropdownMenuItem(
                          value: shift,
                          child: Text(shift),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedShift = value);
                },
              ),
            ),
          ),
        ),
        buildField(
          label: 'Models',
          child: OutlinedButton.icon(
            style: buttonStyle,
            onPressed: _openModelPicker,
            icon: const Icon(Icons.list_alt),
            label: Text(
              _selectedModels.isEmpty
                  ? 'Select Models'
                  : 'Selected: ${_selectedModels.length}',
            ),
          ),
        ),
        buildField(
          label: 'Actions',
          child: FilledButton.icon(
            onPressed: _onQuery,
            icon: const Icon(Icons.search),
            label: const Text('QUERY'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizing) {
        final bool isMobile = sizing.deviceScreenType == DeviceScreenType.mobile;
        final bool isTablet = sizing.deviceScreenType == DeviceScreenType.tablet;

        return Scaffold(
          backgroundColor: _pageBackground,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                final isLoading = _controller.isLoading.value;
                final errorText = _controller.error.value;
                final view = _controller.viewState.value;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NVIDIA ${_selectedSerial.toUpperCase()} UPH Tracking',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Theo dõi năng suất theo trạm',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                          const SizedBox(height: 24),
                          _buildFilterBar(isMobile, isTablet),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    if (isLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (errorText != null && view == null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            errorText,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      )
                    else if (view == null)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'Chọn bộ lọc và nhấn QUERY để hiển thị dữ liệu.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Chip(
                                  backgroundColor: Colors.white12,
                                  label: Text(
                                    'Tổng WIP: ${view.totalWip}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Chip(
                                  backgroundColor: Colors.white12,
                                  label: Text(
                                    'Tổng Pass: ${view.totalPass}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Chip(
                                  backgroundColor: Colors.white12,
                                  label: Text(
                                    'PR trung bình: ${view.avgProductivity.toStringAsFixed(1)}%',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: _buildTable(view, isMobile),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
