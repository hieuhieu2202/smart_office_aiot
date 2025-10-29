import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../data/datasources/te_management_remote_data_source.dart';
import '../../data/repositories/te_management_repository_impl.dart';
import '../../domain/entities/te_report.dart';
import '../../domain/usecases/get_model_names.dart';
import '../../domain/usecases/get_retest_rate_error_detail.dart';
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
        getRetestRateErrorDetailUseCase:
            GetRetestRateErrorDetailUseCase(repository),
        initialModelSerial: widget.initialModelSerial,
        initialModels: widget.initialModels,
      ),
      tag: _controllerTag,
    );
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

    TERetestCellDetail? _findCell(String label, bool isDay) {
      for (final cell in detail.cells) {
        if (cell.dateLabel == label && cell.isDayShift == isDay) {
          return cell;
        }
      }
      return null;
    }

    for (final label in labels) {
      final dayCell = _findCell(label, true);
      final nightCell = _findCell(label, false);

      daySeries.add(_ChartPoint(
        label: label,
        shiftLabel: 'Day',
        value: dayCell?.retestRate,
        detail: dayCell,
      ));

      nightSeries.add(_ChartPoint(
        label: label,
        shiftLabel: 'Night',
        value: nightCell?.retestRate,
        detail: nightCell,
      ));
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
              tooltipBehavior: TooltipBehavior(
                enable: true,
                header: '',
                activationMode: ActivationMode.singleTap,
                color: Colors.transparent,
                builder: (
                  dynamic data,
                  dynamic point,
                  dynamic series,
                  int pointIndex,
                  int seriesIndex,
                ) {
                  final chartPoint = data is _ChartPoint ? data : null;
                  final cell = chartPoint?.detail;
                  final dateLabel = cell?.dateLabel ?? chartPoint?.label ?? '';
                  final shift = cell?.shiftLabel ?? chartPoint?.shiftLabel ?? '';
                  final retestRate = cell?.retestRate ?? chartPoint?.value;

                  String formatRate(double? value) =>
                      value != null ? '${value.toStringAsFixed(2)}%' : 'N/A';
                  String formatQty(int? value) =>
                      NumberFormat.decimalPattern().format(value ?? 0);

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xF0152645), Color(0xF0020B1D)],
                      ),
                      border: Border.all(
                        color: const Color(0xFF3DD6FF),
                        width: 1.1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x553DD6FF),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dateLabel (${shift.isEmpty ? 'N/A' : shift})',
                          style: const TextStyle(
                            color: Color(0xFFA3F4FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _TooltipStatRow(
                          label: 'Retest Rate',
                          value: formatRate(retestRate),
                        ),
                        _TooltipStatRow(
                          label: 'WIP Qty',
                          value: formatQty(cell?.input),
                        ),
                        _TooltipStatRow(
                          label: 'First Fail',
                          value: formatQty(cell?.firstFail),
                        ),
                        _TooltipStatRow(
                          label: 'Retest Fail',
                          value: formatQty(cell?.retestFail),
                        ),
                        _TooltipStatRow(
                          label: 'Pass Qty',
                          value: formatQty(cell?.pass),
                        ),
                      ],
                    ),
                  );
                },
              ),
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

  List<Widget> _buildMetricChips(TERetestCellDetail detail) {
    String _formatRate(double? value) {
      if (value == null) {
        return 'N/A';
      }
      return '${value.toStringAsFixed(value >= 100 ? 0 : 2)}%';
    }

    String _formatInt(int? value) {
      if (value == null) {
        return '—';
      }
      return NumberFormat.decimalPattern().format(value);
    }

    return [
      _DetailMetricChip(
        label: 'Retest Rate',
        value: _formatRate(detail.retestRate),
      ),
      _DetailMetricChip(
        label: 'WIP Qty',
        value: _formatInt(detail.input),
      ),
      _DetailMetricChip(
        label: 'First Fail',
        value: _formatInt(detail.firstFail),
      ),
      _DetailMetricChip(
        label: 'Retest Fail',
        value: _formatInt(detail.retestFail),
      ),
      _DetailMetricChip(
        label: 'Pass Qty',
        value: _formatInt(detail.pass),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kSurfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1220, maxHeight: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 26,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF082345), Color(0xFF114B8A)],
                            ),
                            border: Border.all(color: const Color(0x6639D2FF)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4D15A0FF),
                                blurRadius: 38,
                                spreadRadius: 3,
                                offset: Offset(0, 24),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _GradientTitle(
                                text:
                                    '${widget.cellDetail.modelName} — ${widget.cellDetail.groupName}',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 18,
                          runSpacing: 12,
                          children: [
                            _DetailInfoChip(
                              icon: Icons.event_note_rounded,
                              label:
                                  '${widget.cellDetail.dateLabel} · ${widget.cellDetail.shiftLabel}',
                            ),
                            _DetailInfoChip(
                              icon: Icons.schedule_rounded,
                              label: _rangeLabel,
                            ),
                            ..._buildMetricChips(widget.cellDetail),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6CFFF4), Color(0xFF1C9DFF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x883BE4FF),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(10),
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          overlayColor: Colors.white.withOpacity(0.22),
                        ),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        splashRadius: 24,
                      ),
                    ),
                  ),
                ],
              ),
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
    const axisLabelMaxChars = 22;
    final points = clusters
        .map((cluster) {
          final raw = cluster.label.isEmpty ? 'N/A' : cluster.label;
          final display = _truncateLabel(raw, axisLabelMaxChars);
          return _BarPoint(display, cluster.totalFail, fullLabel: raw);
        })
        .toList();

    final hasSelection =
        selectedIndex >= 0 && selectedIndex < clusters.length && points.isNotEmpty;
    const tooltipValueLabelStyle = TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
    final axisLabelTextStyle = const TextStyle(
      color: Color(0xFF9EE5FF),
      fontSize: 11,
      fontFamily: 'Inter',
      letterSpacing: 0.3,
      fontStyle: FontStyle.italic,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1200.0;
        final targetWidth = math.min(
          availableWidth,
          availableWidth.isFinite
              ? math.max(availableWidth * 0.95, 1080.0)
              : 1080.0,
        );

        final resolvedHeight = constraints.maxHeight.isFinite
            ? math.max(constraints.maxHeight * 0.7, 420.0)
            : 520.0;

        final tooltipBehavior = TooltipBehavior(
          enable: true,
          header: '',
          animationDuration: 250,
          activationMode: ActivationMode.singleTap,
          color: Colors.transparent,
          builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
              int seriesIndex) {
            final barPoint = data is _BarPoint ? data : null;
            final value = point?.y?.toString() ?? barPoint?.value.toString() ?? '0';
            final label = barPoint?.fullLabel ?? point?.x?.toString() ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xF0152645), Color(0xF0020B1D)],
                ),
                border: Border.all(
                  color: const Color(0xFF3DD6FF),
                  width: 1.1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x553DD6FF),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFA3F4FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tooltipValueLabelStyle,
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            );
          },
        );

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: targetWidth,
            child: Container(
              decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.45, -0.95),
              radius: 1.45,
              colors: [Color(0xFF021433), Color(0xFF010511)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Color(0x3300E1FF),
                blurRadius: 38,
                spreadRadius: 4,
                offset: Offset(0, 26),
              ),
            ],
          ),
            constraints: BoxConstraints(minHeight: resolvedHeight),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x3D39D2FF)),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x66223C66), Color(0x33254B7E)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2600D9FF),
                          blurRadius: 26,
                          spreadRadius: 2,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      child: SfCartesianChart(
                        backgroundColor: Colors.transparent,
                        plotAreaBorderWidth: 0,
                        plotAreaBackgroundColor: const Color(0x110B8CFF),
                        margin: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                        enableAxisAnimation: true,
                        tooltipBehavior: tooltipBehavior,
                        primaryXAxis: CategoryAxis(
                          axisLine: const AxisLine(width: 0),
                          labelRotation: -18,
                          labelStyle: axisLabelTextStyle,
                          labelIntersectAction: AxisLabelIntersectAction.rotate45,
                          majorGridLines: MajorGridLines(
                            color: Colors.white.withOpacity(0.04),
                            width: 0.35,
                          ),
                          majorTickLines: const MajorTickLines(size: 0),
                          axisLabelFormatter: (AxisLabelRenderDetails details) {
                            final display =
                                _truncateLabel(details.text, axisLabelMaxChars);
                            return ChartAxisLabel(display, axisLabelTextStyle);
                          },
                        ),
                        primaryYAxis: NumericAxis(
                          minimum: 0,
                          labelStyle: const TextStyle(
                            color: Color(0xFF8BCFF8),
                            fontSize: 11,
                            fontFamily: 'Inter',
                          ),
                          axisLine: const AxisLine(width: 0),
                          majorGridLines: MajorGridLines(
                            color: Colors.white.withOpacity(0.04),
                            width: 0.32,
                          ),
                          majorTickLines: const MajorTickLines(size: 0),
                        ),
                        series: <CartesianSeries<_BarPoint, String>>[
                          ColumnSeries<_BarPoint, String>(
                            onCreateRenderer: (ChartSeries<_BarPoint, String> series) =>
                                _GlowingColumnSeriesRenderer(),
                            dataSource: points,
                            width: 0.64,
                            spacing: 0.16,
                            animationDuration: 1100,
                            xValueMapper: (point, _) => point.label,
                            yValueMapper: (point, _) => point.value,
                          pointColorMapper: (point, index) {
                            const base = Color(0xFF1DAEFF);
                            if (index == null) return base;
                            final isSelected =
                                hasSelection && index == selectedIndex;
                            return isSelected
                                ? const Color(0xFF33E8FF)
                                : base.withOpacity(hasSelection ? 0.45 : 0.9);
                          },
                          dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              labelAlignment: ChartDataLabelAlignment.auto,
                              textStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(18)),
                          onPointTap: (details) {
                            final index = details.pointIndex;
                            if (index != null) {
                              onSelect(index);
                              final seriesIndex = details.seriesIndex ?? 0;
                              tooltipBehavior.showByIndex(seriesIndex, index);
                            }
                          },
                          onPointLongPress: (details) {
                            final index = details.pointIndex;
                            if (index != null) {
                              final seriesIndex = details.seriesIndex ?? 0;
                              tooltipBehavior.showByIndex(seriesIndex, index);
                            }
                          },
                        ),
                        SplineSeries<_BarPoint, String>(
                          dataSource: points,
                          xValueMapper: (point, _) => point.label,
                            yValueMapper: (point, _) => point.value,
                            color: const Color(0xFF7DFAFF),
                            width: 2.6,
                            markerSettings: const MarkerSettings(
                              isVisible: true,
                              color: Color(0xFF33E8FF),
                              height: 9,
                              width: 9,
                              borderWidth: 2,
                              borderColor: Colors.white,
                            ),
                            opacity: 0.95,
                            enableTooltip: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (hasSelection)
                  const SizedBox(height: 16),
              ],
            ),
          ),
        ));
      },
    );
  }
}

class _MachineBreakdownView extends StatelessWidget {
  const _MachineBreakdownView({
    required this.cluster,
    required this.onBack,
  });

  final TEErrorDetailClusterEntity cluster;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const axisLabelMaxChars = 22;
    final machines = cluster.breakdowns
        .where((breakdown) => breakdown.failQty > 0 || breakdown.label.isNotEmpty)
        .map((breakdown) {
          final raw = breakdown.label.isEmpty ? 'N/A' : breakdown.label;
          final display = _truncateLabel(raw, axisLabelMaxChars);
          return _BarPoint(display, breakdown.failQty, fullLabel: raw);
        })
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1200.0;
        final targetWidth = math.min(
          availableWidth,
          availableWidth.isFinite
              ? math.max(availableWidth * 0.95, 1080.0)
              : 1080.0,
        );

        final resolvedHeight = constraints.maxHeight.isFinite
            ? math.max(constraints.maxHeight * 0.72, 420.0)
            : 520.0;

        const axisLabelTextStyle = TextStyle(
          color: Color(0xFF9EE5FF),
          fontSize: 11,
          fontFamily: 'Inter',
          letterSpacing: 0.3,
          fontStyle: FontStyle.italic,
        );

        final tooltipBehavior = TooltipBehavior(
          enable: true,
          header: '',
          animationDuration: 250,
          activationMode: ActivationMode.singleTap,
          color: Colors.transparent,
          builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
              int seriesIndex) {
            final barPoint = data is _BarPoint ? data : null;
            final value = point?.y?.toString() ?? barPoint?.value.toString() ?? '0';
            final label = barPoint?.fullLabel ?? point?.x?.toString() ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xF0152645), Color(0xF0020B1D)],
                ),
                border: Border.all(
                  color: const Color(0xFF3DD6FF),
                  width: 1.1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x553DD6FF),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFA3F4FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            );
          },
        );

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: targetWidth,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.42, -0.95),
                  radius: 1.5,
                  colors: [Color(0xFF02122C), Color(0xFF01040C)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3300E1FF),
                    blurRadius: 36,
                    spreadRadius: 4,
                    offset: Offset(0, 24),
                  ),
                ],
              ),
              constraints: BoxConstraints(minHeight: resolvedHeight),
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed: onBack,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF33E8FF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text(
                          'Back',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: targetWidth * 0.8),
                            child: Text(
                              _truncateErrorLabel(
                                cluster.label.isEmpty
                                    ? 'Selected Error Signature'
                                    : cluster.label,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: machines.isEmpty
                        ? const Center(
                            child: Text(
                              'No machine failures recorded for this error code.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: const Color(0x3D39D2FF)),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0x66223C66), Color(0x33254B7E)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2600D9FF),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                  offset: Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                              child: SfCartesianChart(
                                backgroundColor: Colors.transparent,
                                plotAreaBorderWidth: 0,
                                plotAreaBackgroundColor: const Color(0x110B8CFF),
                                margin: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                                enableAxisAnimation: true,
                                tooltipBehavior: tooltipBehavior,
                                primaryXAxis: CategoryAxis(
                                  axisLine: const AxisLine(width: 0),
                                  labelStyle: axisLabelTextStyle,
                                  labelRotation: -18,
                                  labelIntersectAction: AxisLabelIntersectAction.rotate45,
                                  majorGridLines: MajorGridLines(
                                    color: Colors.white.withOpacity(0.04),
                                    width: 0.32,
                                  ),
                                  majorTickLines: const MajorTickLines(size: 0),
                                  axisLabelFormatter: (AxisLabelRenderDetails details) {
                                    final display =
                                        _truncateLabel(details.text, axisLabelMaxChars);
                                    return ChartAxisLabel(display, axisLabelTextStyle);
                                  },
                                ),
                                primaryYAxis: NumericAxis(
                                  minimum: 0,
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF8BCFF8),
                                    fontSize: 11,
                                    fontFamily: 'Inter',
                                  ),
                                  axisLine: const AxisLine(width: 0),
                                  majorGridLines: MajorGridLines(
                                    color: Colors.white.withOpacity(0.04),
                                    width: 0.3,
                                  ),
                                  majorTickLines: const MajorTickLines(size: 0),
                                ),
                                series: <CartesianSeries<_BarPoint, String>>[
                                  ColumnSeries<_BarPoint, String>(
                                    onCreateRenderer:
                                        (ChartSeries<_BarPoint, String> series) =>
                                            _GlowingColumnSeriesRenderer(),
                                    dataSource: machines,
                                    width: 0.64,
                                    spacing: 0.16,
                                    animationDuration: 1000,
                                    xValueMapper: (point, _) => point.label,
                                    yValueMapper: (point, _) => point.value,
                                    pointColorMapper: (point, index) =>
                                        const Color(0xFF33E8FF),
                                    dataLabelSettings: const DataLabelSettings(
                                      isVisible: true,
                                      labelAlignment: ChartDataLabelAlignment.auto,
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                  onPointTap: (details) {
                                    final index = details.pointIndex;
                                    if (index != null) {
                                      final seriesIndex = details.seriesIndex ?? 0;
                                      tooltipBehavior.showByIndex(seriesIndex, index);
                                    }
                                  },
                                  onPointLongPress: (details) {
                                    final index = details.pointIndex;
                                    if (index != null) {
                                      final seriesIndex = details.seriesIndex ?? 0;
                                      tooltipBehavior.showByIndex(seriesIndex, index);
                                    }
                                  },
                                ),
                                  SplineSeries<_BarPoint, String>(
                                    dataSource: machines,
                                    xValueMapper: (point, _) => point.label,
                                    yValueMapper: (point, _) => point.value,
                                    color: const Color(0xFF7DFAFF),
                                    width: 2.4,
                                    markerSettings: const MarkerSettings(
                                      isVisible: true,
                                      color: Color(0xFF33E8FF),
                                      height: 9,
                                      width: 9,
                                      borderWidth: 2,
                                      borderColor: Colors.white,
                                    ),
                                    opacity: 0.9,
                                    enableTooltip: false,
                                  ),
                                ],
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
    );
  }
}
class _GradientTitle extends StatelessWidget {
  const _GradientTitle({
    required this.text,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w600,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFF8EEBFF),
        fontSize: fontSize,
        fontFamily: 'Inter',
        fontWeight: fontWeight,
        letterSpacing: 0.6,
        shadows: const [
          Shadow(
            color: Color(0x6639D2FF),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoChip extends StatelessWidget {
  const _DetailInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x3324A6FF), Color(0x6616C2FF)],
        ),
        border: Border.all(color: const Color(0x5539D2FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2622B8FF),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF77E3FF)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFEBF6FF),
                fontSize: 12.5,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailMetricChip extends StatelessWidget {
  const _DetailMetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x2629D5FF), Color(0x6624A8FF)],
        ),
        border: Border.all(color: const Color(0x5539D2FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3322B8FF),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFA8E7FF),
                fontSize: 10.5,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TooltipStatRow extends StatelessWidget {
  const _TooltipStatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF7DD6FF),
              fontSize: 11.5,
              letterSpacing: 0.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowingColumnSeriesRenderer extends ColumnSeriesRenderer<_BarPoint, String> {
  @override
  ColumnSegment<_BarPoint, String> createSegment() => _GlowingColumnSegment();
}

class _GlowingColumnSegment extends ColumnSegment<_BarPoint, String> {
  @override
  void onPaint(Canvas canvas) {
    if (segmentRect == null) {
      return;
    }

    final RRect rect = segmentRect!;
    final Rect outerRect = rect.outerRect;
    final RRect roundedRect = RRect.fromRectAndCorners(
      outerRect,
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
    );

    final Paint basePaint = getFillPaint();
    final Color accent = basePaint.color;

    final Paint shadowPaint = Paint()
      ..color = accent.withOpacity(0.35)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12);
    canvas.drawRRect(roundedRect.shift(const Offset(0, 6)), shadowPaint);

    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        const Color(0xFF082C55),
        accent,
      ],
    );

    final Paint fillPaint = Paint()
      ..shader = gradient.createShader(outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(roundedRect, fillPaint);

    final Paint glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.white.withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(outerRect.left, outerRect.top, outerRect.width, outerRect.height / 1.6));
    canvas.drawRRect(roundedRect, glossPaint);
  }
}

class _BarPoint {
  const _BarPoint(this.label, this.value, {String? fullLabel})
      : fullLabel = fullLabel ?? label;

  final String label;
  final String fullLabel;
  final int value;
}

String _truncateLabel(String input, int maxChars) {
  final trimmed = input.trim();
  if (trimmed.length <= maxChars || maxChars < 2) {
    return trimmed;
  }
  return '${trimmed.substring(0, maxChars - 1)}…';
}

String _truncateErrorLabel(String input) {
  final normalized = input.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) {
    return 'Selected Error Signature';
  }
  return _truncateLabel(normalized, 200);
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
  const _ChartPoint({
    required this.label,
    required this.shiftLabel,
    required this.value,
    this.detail,
  });

  final String label;
  final String shiftLabel;
  final double? value;
  final TERetestCellDetail? detail;
}
