import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../controllers/upd_tracking_controller.dart';
import '../viewmodels/upd_tracking_view_state.dart';
import '../widgets/filter_panel.dart';

class UpdTrackingPage extends StatefulWidget {
  const UpdTrackingPage({
    super.key,
    this.initialModelSerial = 'SWITCH',
  });

  final String initialModelSerial;

  @override
  State<UpdTrackingPage> createState() => _UpdTrackingPageState();
}

class _UpdTrackingPageState extends State<UpdTrackingPage> {
  late final UpdTrackingController _controller;
  late DateTimeRange _selectedRange;
  late List<String> _selectedModels;
  late String _selectedSerial;
  Worker? _groupsWorker;

  static const _serialOptions = <String>['SWITCH', 'ADAPTER'];
  static const _pageBackground = Color(0xFF0B1422);

  @override
  void initState() {
    super.initState();

    final desiredSerial = widget.initialModelSerial.trim().isEmpty
        ? 'SWITCH'
        : widget.initialModelSerial.trim().toUpperCase();

    _controller = Get.isRegistered<UpdTrackingController>()
        ? Get.find<UpdTrackingController>()
        : Get.put(UpdTrackingController(initialModelSerial: desiredSerial));

    _selectedSerial = _controller.modelSerial.value;
    _selectedRange = _controller.dateRange.value;
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

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedRange,
      saveText: 'Chọn',
    );
    if (picked != null) {
      setState(() => _selectedRange = picked);
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
        newDateRange: _selectedRange,
        newGroups: _selectedModels,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải dữ liệu: $e')),
      );
    }
  }

  String _formatRange(DateTimeRange range) {
    final formatter = DateFormat('yyyy-MM-dd');
    return '${formatter.format(range.start)} → ${formatter.format(range.end)}';
  }

  Widget _buildTable(UpdTrackingViewState view, bool isMobile) {
    final numberFormat = NumberFormat('#,##0');
    final prFormat = NumberFormat('##0.0');

    final columns = <DataColumn>[
      const DataColumn(label: Text('MODEL')),
      const DataColumn(label: Text('STATION')),
      const DataColumn(label: Text('WIP')),
      const DataColumn(label: Text('PASS')),
      const DataColumn(label: Text('UPD')),
    ];

    for (final date in view.dates) {
      columns.add(DataColumn(label: Text('$date PASS')));
      columns.add(DataColumn(label: Text('$date PRODUCTIVITY')));
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
        DataCell(Text(prFormat.format(row.upd),
            style: const TextStyle(color: Colors.amberAccent))),
      ];

      for (int i = 0; i < view.dates.length; i++) {
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

  Widget _buildFilterBar() {
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
          label: 'Date Range',
          child: OutlinedButton.icon(
            style: buttonStyle,
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range),
            label: Text(_formatRange(_selectedRange)),
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
                            'NVIDIA ${_selectedSerial.toUpperCase()} UPD Tracking',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Theo dõi sản lượng theo ngày',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                          const SizedBox(height: 24),
                          _buildFilterBar(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    if (isLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
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
