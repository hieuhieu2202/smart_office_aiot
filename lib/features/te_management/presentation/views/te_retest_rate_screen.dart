import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../data/datasources/te_management_remote_data_source.dart';
import '../../data/repositories/te_management_repository_impl.dart';
import '../../domain/usecases/get_model_names.dart';
import '../../domain/usecases/get_retest_rate_report.dart';
import '../controllers/te_retest_rate_controller.dart';
import '../widgets/te_retest_rate_table.dart';

const Color _kBackgroundColor = Color(0xFF04142A);
const Color _kSurfaceColor = Color(0xFF08213F);
const Color _kAccentColor = Color(0xFF22D3EE);

class TERetestRateScreen extends StatefulWidget {
  const TERetestRateScreen({
    super.key,
    this.initialModelSerial = 'SWITCH',
    this.initialModels = const [],
    this.controllerTag,
    this.title,
  });

  final String initialModelSerial;
  final List<String> initialModels;
  final String? controllerTag;
  final String? title;

  @override
  State<TERetestRateScreen> createState() => _TERetestRateScreenState();
}

class _TERetestRateScreenState extends State<TERetestRateScreen> {
  late final String _controllerTag;
  late final TERetestRateController _controller;
  final TextEditingController _modelSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.controllerTag ??
        'TE_RETEST_${widget.initialModelSerial}_${DateTime.now().millisecondsSinceEpoch}';
    final dataSource = TEManagementRemoteDataSource();
    final repository = TEManagementRepositoryImpl(dataSource);
    _controller = Get.put(
      TERetestRateController(
        getRetestRateReportUseCase: GetRetestRateReportUseCase(repository),
        getModelNamesUseCase: GetModelNamesUseCase(repository),
        initialModelSerial: widget.initialModelSerial,
        initialModels: widget.initialModels,
      ),
      tag: _controllerTag,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initialize();
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<TERetestRateController>(tag: _controllerTag)) {
      Get.delete<TERetestRateController>(tag: _controllerTag);
    }
    _modelSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          widget.title ?? 'TE Retest Rate Report',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              tooltip: 'Refresh',
              onPressed: _controller.isLoading.value
                  ? null
                  : () => _controller.fetchReport(showLoading: true),
            ),
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, sizing) {
          final horizontalPadding = sizing.isDesktop ? 24.0 : 16.0;
          final verticalPadding = sizing.isDesktop ? 20.0 : 12.0;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilters(sizing),
                  const SizedBox(height: 16),
                  _buildStatusRow(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Obx(() {
                      final detail = _controller.detail.value;
                      final loading = _controller.isLoading.value;
                      final hasError = _controller.hasError;
                      final message = _controller.errorMessage.value;

                      if (hasError && !loading) {
                        return _buildErrorState(message);
                      }

                      if (!loading && !detail.hasData) {
                        return const Center(
                          child: Text(
                            'No data available for the selected filters.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: TERetestRateTable(
                              detail: detail,
                              formattedDates: _controller.formattedDates,
                              onCellTap: _showCellDetailDialog,
                              onGroupTap: _showGroupTrendDialog,
                            ),
                          ),
                          if (loading)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.35),
                                child: const Center(
                                  child: CircularProgressIndicator(color: _kAccentColor),
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(SizingInformation sizing) {
    final isCompact = sizing.screenSize.width < 900;

    final rangeTile = Obx(
      () => _FilterTile(
        icon: Icons.date_range,
        label: 'Date Range',
        value: _controller.rangeLabel,
        onTap: _pickDateRange,
      ),
    );

    final modelTile = Obx(
      () {
        final selection = _controller.selectedModels;
        final text = selection.isEmpty
            ? 'All Models'
            : 'Selected ${selection.length}';
        return _FilterTile(
          icon: Icons.widgets,
          label: 'Models',
          value: text,
          onTap: _openModelSelector,
        );
      },
    );

    final queryButton = Obx(
      () => ElevatedButton.icon(
        onPressed: _controller.isLoading.value
            ? null
            : () => _controller.fetchReport(showLoading: true),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF253C63),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: _controller.isLoading.value
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.search),
        label: const Text('Query'),
      ),
    );

    final exportButton = Obx(
      () => OutlinedButton.icon(
        onPressed: _controller.canExport ? _exportCsv : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF60A5FA)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.download),
        label: const Text('Export CSV'),
      ),
    );

    final children = [
      SizedBox(width: isCompact ? double.infinity : 320, child: rangeTile),
      SizedBox(width: isCompact ? double.infinity : 240, child: modelTile),
      queryButton,
      exportButton,
    ];

    if (isCompact) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
    }

    return Row(
      children: [
        Expanded(child: rangeTile),
        const SizedBox(width: 12),
        SizedBox(width: 260, child: modelTile),
        const SizedBox(width: 12),
        queryButton,
        const SizedBox(width: 12),
        exportButton,
      ],
    );
  }

  Widget _buildStatusRow() {
    return Obx(() {
      final lastUpdated = _controller.lastUpdated.value;
      final formatter = DateFormat('yyyy/MM/dd HH:mm:ss');
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Last updated: ${formatter.format(lastUpdated)}',
            style: const TextStyle(color: Colors.white60),
          ),
          if (_controller.hasError)
            Text(
              'Refresh to retry',
              style: TextStyle(color: Colors.redAccent.shade200, fontWeight: FontWeight.w600),
            ),
        ],
      );
    });
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 12)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
            const SizedBox(height: 16),
            const Text(
              'Failed to load report',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _controller.fetchReport(showLoading: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final currentStart = _controller.startDate.value;
    final currentEnd = _controller.endDate.value;
    final result = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: DateTime(currentStart.year, currentStart.month, currentStart.day),
        end: DateTime(currentEnd.year, currentEnd.month, currentEnd.day),
      ),
      firstDate: DateTime(currentEnd.year - 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _kAccentColor,
              surface: _kSurfaceColor,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: _kSurfaceColor,
          ),
          child: child!,
        );
      },
    );
    if (result != null) {
      _controller.setDateRange(start: result.start, end: result.end);
      await _controller.fetchReport(showLoading: true);
    }
  }

  Future<void> _openModelSelector() async {
    final available = _controller.availableModels.toList();
    if (available.isEmpty) {
      await _controller.refreshModelNames();
    }
    final options = _controller.availableModels.toList();
    if (options.isEmpty) {
      Get.snackbar('Models', 'No models available for this customer.');
      return;
    }
    final currentSelection = _controller.selectedModels.toSet();
    _modelSearchController.clear();
    final result = await showDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final tempSelection = currentSelection.toSet();
        String filter = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = options
                .where(
                  (model) => filter.isEmpty
                      ? true
                      : model.toLowerCase().contains(filter.toLowerCase()),
                )
                .toList();
            return AlertDialog(
              backgroundColor: _kSurfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Select Models',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: math.min(MediaQuery.of(context).size.width * 0.6, 420),
                height: math.min(MediaQuery.of(context).size.height * 0.6, 420),
                child: Column(
                  children: [
                    TextField(
                      controller: _modelSearchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        hintText: 'Search model',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0E2642),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filter = value.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final model = filtered[index];
                            final selected = tempSelection.contains(model);
                            return CheckboxListTile(
                              value: selected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    tempSelection.add(model);
                                  } else {
                                    tempSelection.remove(model);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                model,
                                style: const TextStyle(color: Colors.white),
                              ),
                              activeColor: _kAccentColor,
                              checkboxShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(currentSelection.toList()),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    tempSelection.clear();
                    Navigator.of(context).pop(<String>[]);
                  },
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(tempSelection.toList()),
                  style: ElevatedButton.styleFrom(backgroundColor: _kAccentColor, foregroundColor: Colors.black),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      _controller.setSelectedModels(result);
      await _controller.fetchReport(showLoading: true);
    }
  }

  Future<void> _exportCsv() async {
    final outcome = await _controller.exportToCsv();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _kSurfaceColor,
        content: Text(outcome.message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCellDetailDialog(TERetestCellDetail detail) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _kSurfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            '${detail.modelName} - ${detail.groupName}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Date', detail.dateLabel),
              _detailRow('Shift', detail.shiftLabel),
              _detailRow('Retest Rate', detail.retestRate == null ? 'N/A' : '${detail.retestRate!.toStringAsFixed(2)}%'),
              _detailRow('WIP Qty', (detail.input ?? 0).toString()),
              _detailRow('First Fail', (detail.firstFail ?? 0).toString()),
              _detailRow('Retest Fail', (detail.retestFail ?? 0).toString()),
              _detailRow('Pass Qty', (detail.pass ?? 0).toString()),
            ],
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

  void _showGroupTrendDialog(TERetestGroupDetail detail) {
    final labels = <String>[];
    final daySeries = <_ChartPoint>[];
    final nightSeries = <_ChartPoint>[];

    for (final cell in detail.cells) {
      if (!labels.contains(cell.dateLabel)) {
        labels.add(cell.dateLabel);
      }
    }

    for (final label in labels) {
      final dayValue = detail.cells
          .where((cell) => cell.dateLabel == label && cell.shiftLabel == 'Day')
          .map((cell) => cell.retestRate)
          .firstWhere((value) => value != null, orElse: () => null);
      final nightValue = detail.cells
          .where((cell) => cell.dateLabel == label && cell.shiftLabel == 'Night')
          .map((cell) => cell.retestRate)
          .firstWhere((value) => value != null, orElse: () => null);
      daySeries.add(_ChartPoint(label, dayValue));
      nightSeries.add(_ChartPoint(label, nightValue));
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _kSurfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            '${detail.groupName} Trend',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: math.min(MediaQuery.of(context).size.width * 0.8, 720),
            height: 420,
            child: SfCartesianChart(
              legend: Legend(
                isVisible: true,
                textStyle: const TextStyle(color: Colors.white70),
              ),
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(color: Colors.white70),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: 100,
                labelFormat: '{value}%',
                labelStyle: const TextStyle(color: Colors.white70),
                majorGridLines: const MajorGridLines(color: Colors.white24, width: 0.5),
              ),
              tooltipBehavior: TooltipBehavior(enable: true, header: ''),
              series: <CartesianSeries<_ChartPoint, String>>[
                ColumnSeries<_ChartPoint, String>(
                  name: 'Day',
                  dataSource: daySeries,
                  xValueMapper: (point, _) => point.label,
                  yValueMapper: (point, _) => point.value,
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFF34D399),
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(color: Colors.white),
                  ),
                ),
                ColumnSeries<_ChartPoint, String>(
                  name: 'Night',
                  dataSource: nightSeries,
                  xValueMapper: (point, _) => point.label,
                  yValueMapper: (point, _) => point.value,
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFF6366F1),
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(color: Colors.white),
                  ),
                ),
              ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: _kAccentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

class _ChartPoint {
  const _ChartPoint(this.label, this.value);

  final String label;
  final double? value;
}
