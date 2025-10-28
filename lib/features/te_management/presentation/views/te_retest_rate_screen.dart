import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../data/datasources/te_management_remote_data_source.dart';
import '../../data/repositories/te_management_repository_impl.dart';
import '../../domain/entities/te_report.dart';
import '../../domain/usecases/get_model_names.dart';
import '../../domain/usecases/get_retest_rate_report.dart';
import '../../domain/usecases/get_error_detail.dart';
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
        getErrorDetailUseCase: GetErrorDetailUseCase(repository),
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
      barrierDismissible: false,
      builder: (context) {
        return _CellErrorDetailDialog(
          controller: _controller,
          cellDetail: detail,
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

class _CellErrorDetailDialog extends StatefulWidget {
  const _CellErrorDetailDialog({
    required this.controller,
    required this.cellDetail,
  });

  final TERetestRateController controller;
  final TERetestCellDetail cellDetail;

  @override
  State<_CellErrorDetailDialog> createState() => _CellErrorDetailDialogState();
}

class _CellErrorDetailDialogState extends State<_CellErrorDetailDialog> {
  late Future<TEErrorDetailEntity?> _future;
  late final String _rangeLabel;
  int? _selectedClusterIndex;
  bool _showingMachines = false;

  @override
  void initState() {
    super.initState();
    _rangeLabel = widget.controller.buildRangeLabelForCell(
          dateKey: widget.cellDetail.dateKey,
          isDayShift: widget.cellDetail.isDayShift,
        ) ??
        widget.controller.rangeLabel;
    _future = _load();
  }

  Future<TEErrorDetailEntity?> _load() {
    return widget.controller.fetchErrorDetailForCell(
      dateKey: widget.cellDetail.dateKey,
      isDayShift: widget.cellDetail.isDayShift,
      modelName: widget.cellDetail.modelName,
      groupName: widget.cellDetail.groupName,
    );
  }

  void _retry() {
    setState(() {
      _future = _load();
      _selectedClusterIndex = null;
      _showingMachines = false;
    });
  }

  void _selectCluster(List<TEErrorDetailClusterEntity> clusters, int index) {
    if (index < 0 || index >= clusters.length) {
      return;
    }
    setState(() {
      _selectedClusterIndex = index;
      _showingMachines = true;
    });
  }

  void _returnToErrorChart() {
    setState(() {
      _showingMachines = false;
    });
  }

  void _resetSelection() {
    setState(() {
      _showingMachines = false;
      _selectedClusterIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kSurfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.cellDetail.modelName} — ${widget.cellDetail.groupName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.cellDetail.dateLabel} · ${widget.cellDetail.shiftLabel}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _rangeLabel,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<TEErrorDetailEntity?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: _kAccentColor),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Expanded(
                    child: _ErrorDetailMessage(
                      message: 'Failed to load error details.\n${snapshot.error}',
                      onRetry: _retry,
                    ),
                  );
                }

                final data = snapshot.data;
                if (data == null || !data.hasData) {
                  return const Expanded(
                    child: _ErrorDetailMessage(
                      message: 'No error details were reported for this cell.',
                    ),
                  );
                }

                final errorClusters = data.byErrorCode
                    .where((cluster) => cluster.totalFail > 0 || cluster.label.isNotEmpty)
                    .toList();

                if (errorClusters.isEmpty) {
                  return const Expanded(
                    child: _ErrorDetailMessage(
                      message: 'No error code information available for this cell.',
                    ),
                  );
                }

                int? selectedIndex = _selectedClusterIndex;
                if (selectedIndex != null &&
                    (selectedIndex < 0 || selectedIndex >= errorClusters.length)) {
                  selectedIndex = null;
                }

                final selectedCluster =
                    selectedIndex != null ? errorClusters[selectedIndex] : null;
                final showMachines = _showingMachines && selectedCluster != null;

                if (showMachines) {
                  return Expanded(
                    child: _MachineBreakdownView(
                      cluster: selectedCluster!,
                      onBack: _returnToErrorChart,
                      onReset: _resetSelection,
                    ),
                  );
                }

                return Expanded(
                  child: _ErrorCodeChart(
                    clusters: errorClusters,
                    selectedIndex: selectedIndex ?? -1,
                    onSelect: (index) => _selectCluster(errorClusters, index),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorDetailMessage extends StatelessWidget {
  const _ErrorDetailMessage({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: _kAccentColor),
              label: const Text(
                'Retry',
                style: TextStyle(color: _kAccentColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCodeChart extends StatelessWidget {
  const _ErrorCodeChart({
    required this.clusters,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<TEErrorDetailClusterEntity> clusters;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final points = clusters
        .map(
          (cluster) => _BarPoint(
            cluster.label.isEmpty ? 'N/A' : cluster.label,
            cluster.totalFail,
          ),
        )
        .toList();

    final hasSelection =
        selectedIndex >= 0 && selectedIndex < clusters.length && points.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2846),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order By Error Code',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap a bar to view affected machines.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              plotAreaBorderWidth: 0,
              legend: Legend(isVisible: false),
              tooltipBehavior: TooltipBehavior(enable: true, header: ''),
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(color: Colors.white70),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                labelStyle: const TextStyle(color: Colors.white70),
                majorGridLines: const MajorGridLines(color: Colors.white24, width: 0.5),
              ),
              series: <CartesianSeries<_BarPoint, String>>[
                ColumnSeries<_BarPoint, String>(
                  dataSource: points,
                  xValueMapper: (point, _) => point.label,
                  yValueMapper: (point, _) => point.value,
                  borderRadius: BorderRadius.circular(6),
                  pointColorMapper: (point, index) {
                    const base = Color(0xFF1D4ED8);
                    if (index == null) {
                      return base;
                    }
                    final isSelected = hasSelection && index == selectedIndex;
                    return isSelected ? const Color(0xFF22D3EE) : base.withOpacity(hasSelection ? 0.35 : 1);
                  },
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(color: Colors.white),
                  ),
                  onPointTap: (details) {
                    final index = details.pointIndex;
                    if (index != null) {
                      onSelect(index);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MachineBreakdownView extends StatelessWidget {
  const _MachineBreakdownView({
    required this.cluster,
    required this.onBack,
    required this.onReset,
  });

  final TEErrorDetailClusterEntity cluster;
  final VoidCallback onBack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final machines = cluster.breakdowns
        .where((breakdown) => breakdown.failQty > 0 || breakdown.label.isNotEmpty)
        .map((breakdown) => _BarPoint(
              breakdown.label.isEmpty ? 'N/A' : breakdown.label,
              breakdown.failQty,
            ))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2846),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: onBack,
                style: TextButton.styleFrom(foregroundColor: _kAccentColor),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text(
                  'Back',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(foregroundColor: _kAccentColor),
                child: const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Text(
                cluster.label.isEmpty ? 'Total' : cluster.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Fail Qty by Machine',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (machines.isEmpty)
            const Text(
              'No machine failures recorded for this error code.',
              style: TextStyle(color: Colors.white54),
            )
          else
            SizedBox(
              height: 280,
              child: SfCartesianChart(
                backgroundColor: Colors.transparent,
                plotAreaBorderWidth: 0,
                legend: Legend(isVisible: false),
                tooltipBehavior: TooltipBehavior(enable: true, header: ''),
                primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(color: Colors.white70),
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  labelStyle: const TextStyle(color: Colors.white70),
                  majorGridLines:
                      const MajorGridLines(color: Colors.white24, width: 0.5),
                ),
                series: <CartesianSeries<_BarPoint, String>>[
                  ColumnSeries<_BarPoint, String>(
                    dataSource: machines,
                    xValueMapper: (point, _) => point.label,
                    yValueMapper: (point, _) => point.value,
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xFF059669),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(color: Colors.white),
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

class _BarPoint {
  const _BarPoint(this.label, this.value);

  final String label;
  final int value;
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
