import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../data/datasources/te_management_remote_data_source.dart';
import '../../data/repositories/te_management_repository_impl.dart';
import '../../domain/entities/te_report.dart';
import '../../domain/usecases/get_error_detail.dart';
import '../../domain/usecases/get_model_names.dart';
import '../../domain/usecases/get_te_report.dart';
import '../controllers/te_management_controller.dart';
import '../widgets/refresh_label.dart';
import '../widgets/search_bar.dart';
import '../widgets/status_table.dart';

class TEManagementScreen extends StatefulWidget {
  const TEManagementScreen({
    super.key,
    this.initialModelSerial = 'SWITCH',
    this.initialModel = '',
    this.controllerTag,
    this.title,
  });

  final String initialModelSerial;
  final String initialModel;
  final String? controllerTag;
  final String? title;

  @override
  State<TEManagementScreen> createState() => _TEManagementScreenState();
}

class _TEManagementScreenState extends State<TEManagementScreen> {
  static const Color _background = Color(0xFF050F1F);
  static const Color _surface = Color(0xFF0B1C32);
  static const Color _accent = Color(0xFF22D3EE);

  late final String _controllerTag;
  late final TEManagementController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.controllerTag ??
        'TE_MANAGEMENT_${widget.initialModelSerial}_${widget.initialModel}_${DateTime.now().millisecondsSinceEpoch}';
    final dataSource = TEManagementRemoteDataSource();
    final repository = TEManagementRepositoryImpl(dataSource);
    _controller = Get.put(
      TEManagementController(
        getReportUseCase: GetTEReportUseCase(repository),
        getModelNamesUseCase: GetModelNamesUseCase(repository),
        getErrorDetailUseCase: GetErrorDetailUseCase(repository),
        initialModelSerial: widget.initialModelSerial,
        initialModel: widget.initialModel,
      ),
      tag: _controllerTag,
    );
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    if (Get.isRegistered<TEManagementController>(tag: _controllerTag)) {
      Get.delete<TEManagementController>(tag: _controllerTag);
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final start = _controller.startDate.value;
    final end = _controller.endDate.value;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: start, end: end),
      firstDate: DateTime(start.year - 1),
      lastDate: DateTime(end.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accent,
              surface: _surface,
              background: _surface,
              onSurface: Colors.white,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
        7,
        30,
      );
      final endDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        19,
        30,
      );
      _controller.applyFilters(start: startDate, end: endDate);
    }
  }

  void _openFilterSheet() {
    final initialSelection = _controller.selectedModels.toList();
    final available = _controller.availableModels.toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final selected = LinkedHashSet<String>.from(initialSelection);
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(color: const Color(0xFF1F3A5F)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filters',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ) ??
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      onTap: _pickDateRange,
                      tileColor: const Color(0xFF10213A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF1F3A5F)),
                      ),
                      title: const Text(
                        'Date range',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Obx(
                        () => Text(
                          _controller.rangeLabel,
                          style: const TextStyle(color: Color(0xFF9AB3CF)),
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Models',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: available.isEmpty
                          ? const Center(
                              child: Text(
                                'No models available',
                                style: TextStyle(color: Color(0xFF9AB3CF)),
                              ),
                            )
                          : ListView.builder(
                              itemCount: available.length,
                              itemBuilder: (context, index) {
                                final model = available[index];
                                final checked = selected.contains(model);
                                return CheckboxListTile(
                                  value: checked,
                                  title: Text(
                                    model,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: _accent,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        selected.add(model);
                                      } else {
                                        selected.remove(model);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                selected.clear();
                              });
                              _controller.applyFilters(clearModels: true);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _accent),
                            onPressed: () {
                              _controller.applyFilters(models: selected.toList());
                              Navigator.of(context).pop();
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openRateDetail(String rowKey, TERateType type) async {
    HapticFeedback.selectionClick();
    final row = _controller.rowByKey(rowKey);
    if (row == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _RateDetailDialog(
          controllerTag: _controllerTag,
          rowKey: rowKey,
          row: row,
          rateType: type,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(widget.title ?? 'TE Management', style: const TextStyle(color: Colors.white)),
      ),
      body: ResponsiveBuilder(
        builder: (context, sizing) {
          final maxWidth = sizing.isDesktop ? 1200.0 : double.infinity;
          final horizontalPadding = sizing.isDesktop ? 24.0 : 16.0;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildControls(sizing),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TEStatusTable(
                        controllerTag: _controllerTag,
                        onRateTap: _openRateDetail,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls(SizingInformation sizing) {
    final isNarrow = sizing.isMobile || sizing.screenSize.width < 900;
    final searchWidth = isNarrow
        ? double.infinity
        : ((sizing.screenSize.width * 0.3).clamp(240.0, 360.0) as double);

    final filterButtons = Row(
      children: [
        ElevatedButton.icon(
          onPressed: _openFilterSheet,
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('Filter'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3A5B)),
        ),
        const SizedBox(width: 12),
        Obx(
          () => ElevatedButton.icon(
            onPressed: _controller.isLoading.value
                ? null
                : () => _controller.fetchData(showLoading: true, fromPolling: false),
            icon: _controller.isLoading.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 18),
            label: const Text('Query'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF253C63)),
          ),
        ),
      ],
    );

    final refreshLabel = Obx(
      () => TERefreshLabel(
        lastUpdated: _controller.lastUpdated.value,
        isRefreshing: _controller.isLoading.value,
      ),
    );

    final searchField = SizedBox(
      width: searchWidth,
      child: TESearchBar(
        controller: _searchController,
        onChanged: _controller.updateSearch,
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filterButtons,
          const SizedBox(height: 12),
          TESearchBar(
            controller: _searchController,
            onChanged: _controller.updateSearch,
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: refreshLabel),
        ],
      );
    }

    return Row(
      children: [
        filterButtons,
        const Spacer(),
        refreshLabel,
        const SizedBox(width: 12),
        searchField,
      ],
    );
  }
}

class _RateDetailDialog extends StatefulWidget {
  const _RateDetailDialog({
    required this.controllerTag,
    required this.rowKey,
    required this.row,
    required this.rateType,
  });

  final String controllerTag;
  final String rowKey;
  final TEReportRowEntity row;
  final TERateType rateType;

  @override
  State<_RateDetailDialog> createState() => _RateDetailDialogState();
}

class _RateDetailDialogState extends State<_RateDetailDialog> {
  late final TEManagementController _controller;
  bool _isLoading = true;
  String? _error;
  TEErrorDetailEntity? _detail;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<TEManagementController>(tag: widget.controllerTag);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await _controller.fetchErrorDetail(rowKey: widget.rowKey);
      setState(() {
        _detail = detail;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0B1C32),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 720,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.row.modelName} · ${widget.row.groupName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _rateTitle(widget.rateType),
                style: const TextStyle(color: Color(0xFF9AB3CF)),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_accent)),
                  ),
                )
              else if (_error != null)
                _buildError()
              else if (_detail == null || !_detail!.hasData)
                _buildEmpty()
              else
                _buildCharts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: _accent, size: 40),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _load,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No detail data available',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildCharts() {
    final detail = _detail!;
    return ResponsiveBuilder(
      builder: (context, sizing) {
        final isWide = sizing.isTablet || sizing.isDesktop;
        final children = <Widget>[
          Expanded(
            child: _ChartCard(
              title: 'Order by Error Code',
              clusters: detail.byErrorCode,
              onClusterTap: _openBreakdown,
            ),
          ),
          if (detail.byMachine.isNotEmpty)
            Expanded(
              child: _ChartCard(
                title: 'Order by Tester Name',
                clusters: detail.byMachine,
                onClusterTap: _openBreakdown,
              ),
            ),
        ];
        if (isWide) {
          return SizedBox(
            height: 420,
            child: Row(
              children: [
                for (final child in children) ...[
                  child,
                  const SizedBox(width: 16),
                ],
              ]..removeLast(),
            ),
          );
        }
        return Column(
          children: [
            for (final child in children) ...[
              SizedBox(height: 320, child: child),
              const SizedBox(height: 16),
            ],
          ]..removeLast(),
        );
      },
    );
  }

  void _openBreakdown(TEErrorDetailClusterEntity cluster) {
    if (!cluster.hasBreakdown) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B1C32),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border.all(color: const Color(0xFF1F3A5F)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                cluster.label.isEmpty ? 'N/A' : cluster.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: ListView.builder(
                  itemCount: cluster.breakdowns.length,
                  itemBuilder: (context, index) {
                    final item = cluster.breakdowns[index];
                    return ListTile(
                      title: Text(
                        item.label.isEmpty ? 'N/A' : item.label,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        item.failQty.toString(),
                        style: const TextStyle(color: _accent, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _rateTitle(TERateType type) {
    switch (type) {
      case TERateType.fpr:
        return 'First Pass Rate';
      case TERateType.spr:
        return 'Second Pass Rate';
      case TERateType.rr:
        return 'Retest Rate';
    }
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.clusters,
    required this.onClusterTap,
  });

  final String title;
  final List<TEErrorDetailClusterEntity> clusters;
  final ValueChanged<TEErrorDetailClusterEntity> onClusterTap;

  @override
  Widget build(BuildContext context) {
    if (clusters.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10213A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F3A5F)),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white.withOpacity(.7)),
        ),
      );
    }
    final data = clusters
        .map((cluster) => _ChartPoint(
              label: cluster.label.isEmpty ? 'N/A' : cluster.label,
              value: cluster.totalFail,
              cluster: cluster,
            ))
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10213A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F3A5F)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                axisLine: const AxisLine(color: Color(0xFF1F3A5F)),
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                labelRotation: -35,
              ),
              primaryYAxis: NumericAxis(
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(color: Color(0x221F3A5F)),
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              legend: const Legend(isVisible: false),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <ChartSeries<_ChartPoint, String>>[
                ColumnSeries<_ChartPoint, String>(
                  dataSource: data,
                  xValueMapper: (point, _) => point.label,
                  yValueMapper: (point, _) => point.value,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  width: 0.6,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22D3EE), Color(0xFF60A5FA)],
                    stops: [0.0, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  onPointTap: (details) {
                    if (details.pointIndex != null) {
                      onClusterTap(data[details.pointIndex!].cluster);
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

class _ChartPoint {
  const _ChartPoint({
    required this.label,
    required this.value,
    required this.cluster,
  });

  final String label;
  final int value;
  final TEErrorDetailClusterEntity cluster;
}
