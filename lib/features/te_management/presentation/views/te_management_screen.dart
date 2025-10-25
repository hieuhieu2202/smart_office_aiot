import 'dart:collection';
import 'dart:math' as math;

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

const Color kTeBackgroundColor = Color(0xFF04142A);
const Color kTeSurfaceColor = Color(0xFF08213F);
const Color kTeAccentColor = Color(0xFF22D3EE);

const LinearGradient _errorGradient = LinearGradient(
  colors: [Color(0xFFE57373), Color(0xFFEF4444)],
  stops: [0.0, 1.0],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const LinearGradient _tealGradient = LinearGradient(
  colors: [Color(0xFF22D3EE), Color(0xFF60A5FA)],
  stops: [0.0, 1.0],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

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
              primary: kTeAccentColor,
              surface: kTeSurfaceColor,
              background: kTeSurfaceColor,
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
    final media = MediaQuery.of(context);
    final isWide = media.size.width > 640;
    final panelWidth = isWide ? math.min(420.0, media.size.width * 0.38) : media.size.width;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filters',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        final selected = LinkedHashSet<String>.from(initialSelection);
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: SizedBox(
                width: panelWidth,
                height: media.size.height,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    final allChecked = available.isNotEmpty && selected.length == available.length;
                    return Container(
                      decoration: BoxDecoration(
                        color: kTeSurfaceColor,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                        border: Border.all(color: const Color(0xFF1F3A5F)),
                      ),
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + media.viewInsets.bottom),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Models',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              if (available.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      if (selected.length == available.length) {
                                        selected.clear();
                                      } else {
                                        selected
                                          ..clear()
                                          ..addAll(available);
                                      }
                                    });
                                  },
                                  child: Text(
                                    allChecked ? 'Clear all' : 'Select all',
                                    style: const TextStyle(color: kTeAccentColor, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
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
                                        activeColor: kTeAccentColor,
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
                                    setState(selected.clear);
                                    _controller.applyFilters(clearModels: true);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Clear'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: kTeAccentColor),
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
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).chain(
          CurveTween(curve: Curves.easeOutCubic),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
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

  List<Widget> _buildAppBarActions(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 900;

    if (isCompact) {
      return [
        IconButton(
          tooltip: 'Filter',
          onPressed: _openFilterSheet,
          icon: const Icon(Icons.tune, color: Colors.white),
        ),
        Obx(
          () {
            final loading = _controller.isLoading.value;
            return IconButton(
              tooltip: 'Query',
              onPressed: loading
                  ? null
                  : () => _controller.fetchData(showLoading: true, fromPolling: false),
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
            );
          },
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: _openFilterSheet,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3A5B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),
            Obx(
              () {
                final loading = _controller.isLoading.value;
                return ElevatedButton.icon(
                  onPressed: loading
                      ? null
                      : () => _controller.fetchData(showLoading: true, fromPolling: false),
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('Query'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF253C63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kTeBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(widget.title ?? 'TE Management', style: const TextStyle(color: Colors.white)),
        actions: _buildAppBarActions(context),
      ),
      body: ResponsiveBuilder(
        builder: (context, sizing) {
          final horizontalPadding = sizing.isDesktop ? 24.0 : 16.0;
          return Padding(
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
          );
        },
      ),
    );
  }

  Widget _buildControls(SizingInformation sizing) {
    final isNarrow = sizing.isMobile || sizing.screenSize.width < 900;
    final searchWidth = isNarrow
        ? double.infinity
        : ((sizing.screenSize.width * 0.3).clamp(240.0, 420.0) as double);

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
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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
    final media = MediaQuery.of(context);
    final desiredWidth = media.size.width * 0.7;
    final maxAllowedWidth = math.min(media.size.width * 0.92, 1400.0);
    final lowerBoundWidth = math.min(360.0, maxAllowedWidth);
    final dialogWidth = desiredWidth.clamp(lowerBoundWidth, maxAllowedWidth).toDouble();
    final dialogMaxHeight = media.size.height * 0.9;
    return Dialog(
      backgroundColor: const Color(0xFF0B1C32),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxAllowedWidth,
          maxHeight: dialogMaxHeight,
        ),
        child: SizedBox(
          width: dialogWidth,
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
                        '${widget.row.modelName} ${widget.row.groupName}',
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(kTeAccentColor),
                      ),
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
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: kTeAccentColor, size: 40),
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
        final media = MediaQuery.of(context);
        final wideHeight = math.min(media.size.height * 0.65, 460.0);
        final stackedHeight = math.min(media.size.height * 0.35, 320.0);
        final chartCards = <Widget>[
          _ChartCard(
            title: 'Order by Error Code',
            clusters: detail.byErrorCode,
            breakdownTitleBuilder: (cluster) =>
                'Error ${cluster.label.isEmpty ? 'N/A' : cluster.label}',
            breakdownSubtitle: 'by Machine',
            primaryGradient: _errorGradient,
            breakdownGradient: _tealGradient,
          ),
          if (detail.byMachine.isNotEmpty)
            _ChartCard(
              title: 'Order by Tester Name',
              clusters: detail.byMachine,
              breakdownTitleBuilder: (cluster) =>
                  'Machine ${cluster.label.isEmpty ? 'N/A' : cluster.label}',
              breakdownSubtitle: 'by Error Code',
              primaryGradient: _tealGradient,
              breakdownGradient: _errorGradient,
            ),
        ];
        if (chartCards.isEmpty) {
          return const _ChartEmptyState();
        }
        if (isWide) {
          final children = <Widget>[];
          for (var i = 0; i < chartCards.length; i++) {
            children.add(Expanded(child: chartCards[i]));
            if (i != chartCards.length - 1) {
              children.add(const SizedBox(width: 16));
            }
          }
          return SizedBox(
            height: wideHeight,
            child: Row(children: children),
          );
        }
        final columnChildren = <Widget>[];
        for (var i = 0; i < chartCards.length; i++) {
          columnChildren.add(SizedBox(height: stackedHeight, child: chartCards[i]));
          if (i != chartCards.length - 1) {
            columnChildren.add(const SizedBox(height: 16));
          }
        }
        return Column(children: columnChildren);
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

class _ChartCard extends StatefulWidget {
  const _ChartCard({
    required this.title,
    required this.clusters,
    required this.breakdownTitleBuilder,
    this.breakdownSubtitle = '',
    this.primaryGradient,
    this.breakdownGradient,
  });

  final String title;
  final List<TEErrorDetailClusterEntity> clusters;
  final String Function(TEErrorDetailClusterEntity) breakdownTitleBuilder;
  final String breakdownSubtitle;
  final LinearGradient? primaryGradient;
  final LinearGradient? breakdownGradient;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  TEErrorDetailClusterEntity? _activeCluster;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A2242),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F3A5F)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _activeCluster == null
                ? _buildPrimaryHeader()
                : _buildBreakdownHeader(_activeCluster!),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _activeCluster == null
                  ? _buildPrimaryChart()
                  : _buildBreakdownChart(_activeCluster!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryHeader() {
    final total = widget.clusters.fold<int>(0, (sum, item) => sum + item.totalFail);
    return Row(
      key: const ValueKey('primary_header'),
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _TotalBadge(value: total),
      ],
    );
  }

  Widget _buildBreakdownHeader(TEErrorDetailClusterEntity cluster) {
    final subtitle = widget.breakdownSubtitle;
    return Column(
      key: ValueKey('breakdown_header_${cluster.label}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _activeCluster = null),
              icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
              label: const Text('Back', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kTeAccentColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.breakdownTitleBuilder(cluster),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _TotalBadge(value: cluster.totalFail),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF9AB3CF), fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryChart() {
    if (widget.clusters.isEmpty) {
      return _ChartEmptyState(key: const ValueKey('chart_empty'));
    }
    final data = widget.clusters
        .map(
          (cluster) => _ChartPoint(
            label: cluster.label.isEmpty ? 'N/A' : cluster.label,
            value: cluster.totalFail,
            cluster: cluster,
          ),
        )
        .toList();
    return _ChartCanvas(
      key: const ValueKey('chart_primary'),
      points: data,
      onPointTap: (cluster) {
        if (!cluster.hasBreakdown) return;
        setState(() => _activeCluster = cluster);
      },
      gradient: widget.primaryGradient ?? _errorGradient,
    );
  }

  Widget _buildBreakdownChart(TEErrorDetailClusterEntity cluster) {
    final points = cluster.breakdowns
        .map(
          (item) => _BreakdownPoint(
            label: item.label.isEmpty ? 'N/A' : item.label,
            value: item.failQty,
          ),
        )
        .toList();
    if (points.isEmpty) {
      return _ChartEmptyState(key: ValueKey('breakdown_empty_${cluster.label}'));
    }

    return _BreakdownChart(
      key: ValueKey('breakdown_body_${cluster.label}'),
      points: points,
      gradient: widget.breakdownGradient ?? _tealGradient,
    );
  }
}

class _ChartCanvas extends StatelessWidget {
  const _ChartCanvas({
    super.key,
    required this.points,
    required this.onPointTap,
    required this.gradient,
  });

  final List<_ChartPoint> points;
  final ValueChanged<TEErrorDetailClusterEntity> onPointTap;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    final columnSeries = ColumnSeries<_ChartPoint, String>(
      dataSource: points,
      xValueMapper: (point, _) => point.label,
      yValueMapper: (point, _) => point.value,
      color: gradient.colors.last,
      dataLabelSettings: const DataLabelSettings(
        isVisible: true,
        textStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      width: 0.58,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      gradient: gradient,
      onPointTap: (details) {
        if (details.pointIndex != null) {
          onPointTap(points[details.pointIndex!].cluster);
        }
      },
    );

    final lineColor = gradient.colors.last;
    final splineSeries = SplineSeries<_ChartPoint, String>(
      dataSource: points,
      xValueMapper: (point, _) => point.label,
      yValueMapper: (point, _) => point.value,
      color: lineColor.withOpacity(0.75),
      width: 2.5,
      markerSettings: MarkerSettings(
        isVisible: true,
        shape: DataMarkerType.circle,
        width: 9,
        height: 9,
        borderWidth: 2,
        borderColor: Colors.white.withOpacity(0.9),
        color: lineColor,
      ),
    );

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        axisLine: const AxisLine(color: Color(0xFF1F3A5F)),
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        labelIntersectAction: AxisLabelIntersectAction.trim,
        axisLabelFormatter: (details) {
          final raw = details.text;
          const int maxChars = 14;
          final truncated = raw.length > maxChars ? '${raw.substring(0, maxChars)}…' : raw;
          return ChartAxisLabel(
            truncated,
            const TextStyle(color: Colors.white, fontSize: 12),
          );
        },
        labelRotation: -35,
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        majorGridLines: const MajorGridLines(color: Color(0x221F3A5F)),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
      legend: const Legend(isVisible: false),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: '{point.x}: {point.y}',
      ),
      series: <CartesianSeries<dynamic, dynamic>>[
        columnSeries as CartesianSeries<dynamic, dynamic>,
        splineSeries as CartesianSeries<dynamic, dynamic>,
      ],
    );
  }
}

class _BreakdownChart extends StatelessWidget {
  const _BreakdownChart({
    super.key,
    required this.points,
    required this.gradient,
  });

  final List<_BreakdownPoint> points;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    final columnSeries = ColumnSeries<_BreakdownPoint, String>(
      dataSource: points,
      xValueMapper: (point, _) => point.label,
      yValueMapper: (point, _) => point.value,
      color: gradient.colors.last,
      dataLabelSettings: const DataLabelSettings(
        isVisible: true,
        textStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      width: 0.58,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      gradient: gradient,
    );

    final lineColor = gradient.colors.last;
    final splineSeries = SplineSeries<_BreakdownPoint, String>(
      dataSource: points,
      xValueMapper: (point, _) => point.label,
      yValueMapper: (point, _) => point.value,
      color: lineColor.withOpacity(0.75),
      width: 2.5,
      markerSettings: MarkerSettings(
        isVisible: true,
        shape: DataMarkerType.circle,
        width: 9,
        height: 9,
        borderWidth: 2,
        borderColor: Colors.white.withOpacity(0.9),
        color: lineColor,
      ),
    );

    return SfCartesianChart(
      key: ValueKey('breakdown_chart_${points.length}'),
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        axisLine: const AxisLine(color: Color(0xFF1F3A5F)),
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        labelIntersectAction: AxisLabelIntersectAction.trim,
        axisLabelFormatter: (details) {
          final raw = details.text;
          const maxChars = 16;
          final truncated = raw.length > maxChars ? '${raw.substring(0, maxChars)}…' : raw;
          return ChartAxisLabel(
            truncated,
            const TextStyle(color: Colors.white, fontSize: 12),
          );
        },
        labelRotation: -35,
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        majorGridLines: const MajorGridLines(color: Color(0x221F3A5F)),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
      legend: const Legend(isVisible: false),
      tooltipBehavior: TooltipBehavior(enable: true, format: '{point.x}: {point.y}'),
      series: <CartesianSeries<dynamic, dynamic>>[
        columnSeries as CartesianSeries<dynamic, dynamic>,
        splineSeries as CartesianSeries<dynamic, dynamic>,
      ],
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No data available',
        style: TextStyle(color: Colors.white.withOpacity(.7)),
      ),
    );
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({
    required this.value,
  });

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x3322D3EE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kTeAccentColor.withOpacity(.7)),
      ),
      child: Text(
        'Total $value',
        style: const TextStyle(
          color: kTeAccentColor,
          fontWeight: FontWeight.w700,
        ),
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

class _BreakdownPoint {
  const _BreakdownPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;
}
