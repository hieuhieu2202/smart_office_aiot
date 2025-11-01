
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../data/datasources/te_management_remote_data_source.dart';
import '../../data/repositories/te_management_repository_impl.dart';
import '../../domain/entities/te_top_error.dart';
import '../../domain/usecases/get_top_error_codes.dart';
import '../../domain/usecases/get_top_error_trends.dart';
import '../controllers/te_top_error_code_controller.dart';
import '../widgets/refresh_label.dart';

const LinearGradient _kBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF03102A), Color(0xFF0C3360)],
);
const Color _kPanelColor = Color(0xFF10294A);
const Color _kPanelBorderColor = Color(0xFF1F558A);
const Color _kAccentColor = Color(0xFF45E3FF);
const Color _kTextPrimary = Color(0xFFF3F8FF);
const Color _kTextSecondary = Color(0xFFC3DBF8);
const Color _kErrorColor = Color(0xFFFF7F8C);
const Color _kRepairColor = Color(0xFFB79CFF);
const Color _kSurfaceMuted = Color(0xFF17345C);
const Color _kTableGridColor = Color(0xFF21598F);

const TextStyle _kTableHeaderStyle = TextStyle(
  color: _kTextPrimary,
  fontSize: 13,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.2,
);

const TextStyle _kTableValueStyle = TextStyle(
  color: _kTextPrimary,
  fontSize: 14,
  fontWeight: FontWeight.w600,
);

const TextStyle _kTableMutedStyle = TextStyle(
  color: _kTextSecondary,
  fontSize: 13,
  fontWeight: FontWeight.w500,
);

const List<_TableColumnSpec> _kTopErrorColumns = [
  _TableColumnSpec(label: 'Top', flex: 9),
  _TableColumnSpec(label: 'ERROR CODE', flex: 20),
  _TableColumnSpec(label: 'F_FAIL', flex: 13),
  _TableColumnSpec(label: 'R_FAIL', flex: 13),
  _TableColumnSpec(label: 'MODEL NAME (Top 3)', flex: 22),
  _TableColumnSpec(label: 'GROUP_NAME', flex: 22),
  _TableColumnSpec(label: 'FIRST FAIL', flex: 14),
  _TableColumnSpec(label: 'REPAIR FAIL', flex: 14),
];

class TETop10ErrorCodeScreen extends StatefulWidget {
  const TETop10ErrorCodeScreen({
    super.key,
    this.initialModelSerial = 'ADAPTER',
    this.initialCategory = TETopErrorCategory.system,
    this.refreshInterval = const Duration(minutes: 1),
    this.controllerTag,
    this.title,
  });

  final String initialModelSerial;
  final TETopErrorCategory initialCategory;
  final Duration refreshInterval;
  final String? controllerTag;
  final String? title;

  @override
  State<TETop10ErrorCodeScreen> createState() => _TETop10ErrorCodeScreenState();
}

class _TETop10ErrorCodeScreenState extends State<TETop10ErrorCodeScreen> {
  static const List<Color> _barPalette = [
    Color(0xFF4FF7D2),
    Color(0xFF5FB3FF),
    Color(0xFFBF8BFF),
    Color(0xFFFF79C6),
    Color(0xFFFFC857),
    Color(0xFF6CF9A8),
    Color(0xFF54E0FF),
    Color(0xFFFF8C5C),
    Color(0xFF48EBFF),
    Color(0xFFE7D85C),
  ];

  late final String _controllerTag;
  late final TETopErrorCodeController _controller;
  final DateFormat _rangeDisplayFormatter = DateFormat('yyyy/MM/dd HH:mm');
  final TooltipBehavior _trendTooltip = TooltipBehavior(
    enable: true,
    color: const Color(0xFF123760),
    header: '',
    textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    borderWidth: 0,
  );
  bool _isFilterPanelOpen = false;
  static const Duration _kFilterAnimationDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.controllerTag ??
        'TE_TOP10_${widget.initialModelSerial}_${DateTime.now().millisecondsSinceEpoch}';
    final dataSource = TEManagementRemoteDataSource();
    final repository = TEManagementRepositoryImpl(dataSource);
    _controller = Get.put(
      TETopErrorCodeController(
        getTopErrorCodesUseCase: GetTopErrorCodesUseCase(repository),
        getTopErrorTrendByErrorCodeUseCase:
            GetTopErrorTrendByErrorCodeUseCase(repository),
        getTopErrorTrendByModelStationUseCase:
            GetTopErrorTrendByModelStationUseCase(repository),
        initialModelSerial: widget.initialModelSerial,
        initialCategory: widget.initialCategory,
        refreshInterval: widget.refreshInterval,
      ),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<TETopErrorCodeController>(tag: _controllerTag)) {
      Get.delete<TETopErrorCodeController>(tag: _controllerTag);
    }
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart
        ? _controller.startDateTime.value
        : _controller.endDateTime.value;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _kAccentColor,
              surface: _kPanelColor,
              background: _kPanelColor,
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _kAccentColor,
              surface: _kPanelColor,
              background: _kPanelColor,
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
            timePickerTheme: baseTheme.timePickerTheme.copyWith(
              backgroundColor: _kPanelColor,
              dialHandColor: _kAccentColor,
              dialBackgroundColor: _kSurfaceMuted,
              hourMinuteColor: _kSurfaceMuted,
              hourMinuteTextColor: Colors.white,
              helpTextStyle: const TextStyle(color: Colors.white70),
              dayPeriodColor: _kSurfaceMuted,
              dayPeriodTextColor: Colors.white,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );
    if (pickedTime == null) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    if (isStart) {
      await _controller.setStartDateTime(result);
    } else {
      await _controller.setEndDateTime(result);
    }
  }

  void _toggleFilterPanel() {
    setState(() {
      _isFilterPanelOpen = !_isFilterPanelOpen;
    });
  }

  void _closeFilterPanel() {
    if (!_isFilterPanelOpen) return;
    setState(() {
      _isFilterPanelOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Container(
        decoration: const BoxDecoration(gradient: _kBackgroundGradient),
        child: ResponsiveBuilder(
          builder: (context, sizing) {
            final isWide = sizing.screenSize.width >= 1100;
            final horizontalPadding = isWide ? 28.0 : 16.0;
            final verticalPadding = isWide ? 20.0 : 12.0;

            return Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                titleSpacing: 0,
                centerTitle: false,
                systemOverlayStyle: overlay,
                title: Obx(() {
                  final modelSerial = _controller.modelSerial.value;
                  final titleText = widget.title ?? '$modelSerial · Top 10 Error Codes';
                  return Text(
                    titleText,
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.filter_alt_outlined),
                    tooltip: _isFilterPanelOpen ? 'Hide filters' : 'Show filters',
                    color: _kAccentColor,
                    onPressed: _toggleFilterPanel,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              body: Stack(
                children: [
                  Positioned.fill(
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: _buildContent(sizing),
                      ),
                    ),
                  ),
                  _buildFilterScrim(),
                  _buildFilterPanel(sizing),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterScrim() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isFilterPanelOpen,
        child: AnimatedOpacity(
          duration: _kFilterAnimationDuration,
          opacity: _isFilterPanelOpen ? 0.6 : 0,
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            onTap: _closeFilterPanel,
            child: Container(color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel(SizingInformation sizing) {
    final width = sizing.screenSize.width;
    final double panelWidth;
    if (width >= 1480) {
      panelWidth = 400;
    } else if (width >= 1100) {
      panelWidth = 360;
    } else {
      panelWidth = width * 0.88;
    }

    return AnimatedPositioned(
      duration: _kFilterAnimationDuration,
      curve: Curves.easeOutCubic,
      top: 0,
      bottom: 0,
      right: _isFilterPanelOpen ? 0 : -panelWidth - 48,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
          child: Obx(() {
            final start = _controller.startDateTime.value;
            final end = _controller.endDateTime.value;
            final modelSerial = _controller.modelSerial.value;
            return Container(
              width: panelWidth,
              decoration: BoxDecoration(
                color: _kPanelColor.withOpacity(0.98),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _kPanelBorderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 20,
                    offset: Offset(6, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _kSurfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.tune, color: _kAccentColor),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Filters',
                          style: TextStyle(
                            color: _kTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _closeFilterPanel,
                        icon: const Icon(Icons.close, color: _kTextSecondary),
                        tooltip: 'Close filters',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Current selection',
                    style: TextStyle(
                      color: _kTextSecondary,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoBadge(
                    icon: Icons.memory_outlined,
                    label: 'Model Serial',
                    value: modelSerial,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Date range',
                    style: TextStyle(
                      color: _kTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RangeButton(
                    label: 'Start · ${_rangeDisplayFormatter.format(start)}',
                    onTap: () => _pickDateTime(isStart: true),
                  ),
                  const SizedBox(height: 10),
                  _RangeButton(
                    label: 'End · ${_rangeDisplayFormatter.format(end)}',
                    onTap: () => _pickDateTime(isStart: false),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _controller.shiftToTodayRange();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kAccentColor,
                      side: const BorderSide(color: _kAccentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: const Text(
                      'Today 07:30 - 19:30',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tip: use the cards or table rows to drill into weekly trends.',
                    style: TextStyle(
                      color: _kTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _closeFilterPanel,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kAccentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContent(SizingInformation sizing) {
    return Obx(() {
      final loading = _controller.isLoading.value;
      final hasError = _controller.hasError;
      final errorMessage = _controller.errorMessage.value;
      final data = _controller.errors;

      if (loading && data.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_kAccentColor),
          ),
        );
      }

      if (hasError && data.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _kErrorColor, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Failed to load data',
                style: TextStyle(color: _kTextPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: const TextStyle(color: _kTextSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _controller.refresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      if (data.isEmpty) {
        return const Center(
          child: Text(
            'No data available for the selected filters.',
            style: TextStyle(color: _kTextSecondary),
          ),
        );
      }

      final isWide = sizing.screenSize.width >= 1100;
      if (isWide) {
        return LayoutBuilder(
          builder: (context, _) {
            const gap = 20.0;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTopErrorTablePanel(
                    isWide: true,
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildTrendPanel()),
                      const SizedBox(height: gap),
                      Expanded(child: _buildDistributionPanel()),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 300,
            child: _buildDistributionPanel(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 360,
            child: _buildTrendPanel(),
          ),
          const SizedBox(height: 18),
          _buildTopErrorTablePanel(isWide: false),
        ],
      );
    });
  }


  Widget _buildTopErrorTablePanel({required bool isWide}) {
    final panel = Obx(() {
      final errors = List<TETopErrorEntity>.from(_controller.errors);
      final selectedError = _controller.selectedError.value;
      final selectedDetail = _controller.selectedDetail.value;
      final lastUpdated = _controller.lastUpdated.value;
      final rangeLabel = _controller.rangeLabel;
      final isRefreshing = _controller.isLoading.value;

      Widget buildBody() {
        if (errors.isEmpty) {
          return const Center(
            child: Text(
              'No data available for the selected filters.',
              style: TextStyle(color: _kTextSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          primary: false,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (context, index) {
            final error = errors[index];
            final accent = _barPalette[index % _barPalette.length];
            return _TopErrorTableRow(
              rank: index + 1,
              error: error,
              accentColor: accent,
              selectedError: selectedError,
              selectedDetail: selectedDetail,
              onErrorTap: () => _controller.selectError(error),
              onDetailTap: (detail) => _controller.selectDetail(detail),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: errors.length,
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: _kPanelColor.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kPanelBorderColor.withOpacity(0.85)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55121E3B),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kSurfaceMuted.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kPanelBorderColor),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.table_chart_outlined, size: 18, color: _kAccentColor),
                      SizedBox(width: 8),
                      Text(
                        'Top 10 Error Breakdown',
                        style: TextStyle(
                          color: _kTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TERefreshLabel(
                      lastUpdated: lastUpdated,
                      isRefreshing: isRefreshing,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      rangeLabel,
                      style: const TextStyle(color: _kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1C4F88), Color(0xFF0A1C34)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kTableGridColor.withOpacity(0.85)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x441C3C62),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _kTopErrorColumns.length; i++)
                    Expanded(
                      flex: _kTopErrorColumns[i].flex,
                      child: Container(
                        padding: _kTopErrorColumns[i].padding,
                        alignment: _kTopErrorColumns[i].alignment,
                        decoration: BoxDecoration(
                          border: Border(
                            right: i == _kTopErrorColumns.length - 1
                                ? BorderSide.none
                                : const BorderSide(color: _kTableGridColor, width: 1),
                          ),
                        ),
                        child: Text(
                          _kTopErrorColumns[i].label,
                          textAlign: _kTopErrorColumns[i].textAlign,
                          style: _kTableHeaderStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: buildBody()),
          ],
        ),
      );
    });

    if (isWide) {
      return panel;
    }

    return SizedBox(height: 520, child: panel);
  }

  Widget _buildDistributionPanel() {
    return Obx(() {
      final errors = _controller.errors;
      final totalFailures = errors.fold<int>(0, (sum, item) => sum + item.totalFail);

      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF153E6F), Color(0xFF07142B)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _kPanelBorderColor.withOpacity(0.9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66204A7A),
              blurRadius: 28,
              offset: Offset(0, 18),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1FE4FF), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.donut_small_outlined, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Failure Distribution',
                    style: TextStyle(
                      color: _kTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kPanelBorderColor.withOpacity(0.65)),
                  ),
                  child: Text(
                    'TOTAL: $totalFailures',
                    style: const TextStyle(
                      color: _kAccentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: errors.isEmpty
                  ? const Center(
                      child: Text(
                        'No data',
                        style: TextStyle(color: _kTextSecondary),
                      ),
                    )
                  : SfCircularChart(
                      backgroundColor: Colors.transparent,
                      margin: EdgeInsets.zero,
                      legend: Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        overflowMode: LegendItemOverflowMode.wrap,
                        textStyle: const TextStyle(
                          color: _kTextPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        color: const Color(0xFF123760),
                        header: '',
                        textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      series: <CircularSeries<_DistributionDatum, String>>[
                        DoughnutSeries<_DistributionDatum, String>(
                          dataSource: List.generate(errors.length, (index) {
                            final item = errors[index];
                            return _DistributionDatum(
                              label: item.errorCode,
                              value: item.totalFail.toDouble(),
                              color: _barPalette[index % _barPalette.length],
                            );
                          }),
                          xValueMapper: (datum, _) => datum.label,
                          yValueMapper: (datum, _) => datum.value,
                          pointColorMapper: (datum, _) => datum.color,
                          radius: '78%',
                          innerRadius: '55%',
                          explode: true,
                          explodeOffset: '4%',
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            labelPosition: ChartDataLabelPosition.outside,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTrendPanel() {
    return Obx(() {
      final selectedError = _controller.selectedError.value;
      final selectedDetail = _controller.selectedDetail.value;
      final trendLoading = _controller.isTrendLoading.value;
      final hasTrendError = _controller.hasTrendError;
      final trendError = _controller.trendErrorMessage.value;
      final trendData = _controller.trendPoints;
      final isFocused = _controller.isTrendFocused.value;
      final previewMap = Map<String, List<TETopErrorTrendPointEntity>>.from(
        _controller.previewTrendPoints,
      );
      final previewLoading = Set<String>.from(_controller.previewTrendLoading);
      final previewErrors =
          Map<String, String>.from(_controller.previewTrendErrors);
      final errors = List<TETopErrorEntity>.from(_controller.errors);
      final showFocusedChart = isFocused || selectedDetail != null;
      final isPreviewBusy = previewLoading.isNotEmpty;

      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF184678), Color(0xFF0A1A34)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _kPanelBorderColor.withOpacity(0.9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55204A7A),
              blurRadius: 28,
              offset: Offset(0, 18),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6EE7FF), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timeline_outlined, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showFocusedChart
                            ? (selectedDetail == null
                                ? '${selectedError?.errorCode ?? '--'} · Weekly Trend'
                                : '${selectedDetail.modelName} · ${selectedDetail.groupName}')
                            : 'Top 10 · Weekly Overview',
                        style: const TextStyle(
                          color: _kTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _controller.rangeLabel,
                        style: const TextStyle(color: _kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (showFocusedChart)
                  TextButton.icon(
                    onPressed: _controller.clearDetailSelection,
                    style: TextButton.styleFrom(
                      foregroundColor: _kAccentColor,
                    ),
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: const Text('Back'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(showFocusedChart),
                  child: showFocusedChart
                      ? _buildFocusedTrendChart(
                          trendLoading: trendLoading,
                          hasTrendError: hasTrendError,
                          trendError: trendError,
                          trendData: trendData,
                        )
                      : _buildOverviewTrendChart(
                          errors: errors,
                          previews: previewMap,
                          previewErrors: previewErrors,
                          isLoading: isPreviewBusy,
                          highlightedCode: selectedError?.errorCode,
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOverviewTrendChart({
    required List<TETopErrorEntity> errors,
    required Map<String, List<TETopErrorTrendPointEntity>> previews,
    required Map<String, String> previewErrors,
    required bool isLoading,
    required String? highlightedCode,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_kAccentColor),
        ),
      );
    }

    if (errors.isEmpty || previews.isEmpty) {
      final message = errors.isEmpty
          ? 'No data available for selected range.'
          : (previewErrors.isNotEmpty
              ? previewErrors.values.first
              : 'No trend data available for the selected period.');
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final seriesConfigs = <_TrendSeriesConfig>[];
    for (var i = 0; i < errors.length; i++) {
      final error = errors[i];
      final points = previews[error.errorCode];
      if (points == null || points.isEmpty) {
        continue;
      }
      seriesConfigs.add(
        _TrendSeriesConfig(
          error: error,
          points: points,
          color: _barPalette[i % _barPalette.length],
        ),
      );
    }

    if (seriesConfigs.isEmpty) {
      final message = previewErrors.isNotEmpty
          ? previewErrors.values.first
          : 'Trend preview unavailable for the selected period.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final tooltip = TooltipBehavior(
      enable: true,
      color: const Color(0xFF123760),
      header: '',
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
    );

    return IgnorePointer(
      ignoring: isLoading,
      child: _Neon3DChartWrapper(
        tiltX: 0,
        tiltY: 0,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: CustomPaint(painter: _WeeklyGridPainter())),
            SfCartesianChart(
              key: const ValueKey('overview_trend_chart'),
              backgroundColor: Colors.transparent,
              margin: const EdgeInsets.only(top: 8, right: 16, left: 10, bottom: 12),
              plotAreaBorderWidth: 0,
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
                toggleSeriesVisibility: false,
                textStyle: const TextStyle(
                  color: _kTextPrimary,
                  fontSize: 11,
                ),
              ),
              tooltipBehavior: tooltip,
              selectionType: SelectionType.series,
              selectionGesture: ActivationMode.singleTap,
              onSelectionChanged: (args) {
                final index = args.seriesIndex;
                if (index == null || index < 0 || index >= seriesConfigs.length) {
                  return;
                }
                _controller.focusErrorTrend(seriesConfigs[index].error);
              },
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 11),
                axisLine: const AxisLine(color: Color(0x66FFFFFF)),
                majorTickLines: const MajorTickLines(size: 0),
                majorGridLines: const MajorGridLines(color: Colors.transparent),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 11),
                axisLine: const AxisLine(color: Colors.transparent),
                majorGridLines: const MajorGridLines(color: Color(0x33FFFFFF)),
              ),
              onLegendTapped: (args) {
                final index = args.seriesIndex;
                if (index == null || index < 0 || index >= seriesConfigs.length) {
                  return;
                }
                _controller.focusErrorTrend(seriesConfigs[index].error);
              },
              series: <CartesianSeries<dynamic, dynamic>>[
                for (var i = 0; i < seriesConfigs.length; i++)
                  LineSeries<TETopErrorTrendPointEntity, String>(
                    name: seriesConfigs[i].error.errorCode,
                    dataSource: seriesConfigs[i].points,
                    xValueMapper: (item, _) => item.label,
                    yValueMapper: (item, _) => item.total,
                    width: 3.0,
                    color: seriesConfigs[i].color,
                    enableTooltip: true,
                    opacity: highlightedCode == null ||
                            highlightedCode == seriesConfigs[i].error.errorCode
                        ? 1.0
                        : 0.28,
                    onCreateShader: (details) {
                      return LinearGradient(
                        colors: [
                          seriesConfigs[i].color.withOpacity(0.55),
                          seriesConfigs[i].color,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(details.rect);
                    },
                    markerSettings: MarkerSettings(
                      isVisible: true,
                      height: 10,
                      width: 10,
                      shape: DataMarkerType.circle,
                      borderWidth: 2.2,
                      borderColor: Colors.white,
                      color: seriesConfigs[i].color,
                    ),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      useSeriesColor: true,
                      textStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      labelAlignment: ChartDataLabelAlignment.auto,
                      labelIntersectAction: LabelIntersectAction.shift,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFocusedTrendChart({
    required bool trendLoading,
    required bool hasTrendError,
    required String trendError,
    required List<TETopErrorTrendPointEntity> trendData,
  }) {
    if (trendLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_kAccentColor),
        ),
      );
    }
    if (hasTrendError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            trendError,
            style: const TextStyle(
              color: _kTextSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (trendData.isEmpty) {
      return const Center(
        child: Text(
          'No weekly trend data available.',
          style: TextStyle(
            color: _kTextSecondary,
          ),
        ),
      );
    }

    return _Neon3DChartWrapper(
      key: const ValueKey('focused_trend_chart'),
      tiltX: 0,
      tiltY: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SfCartesianChart(
        backgroundColor: Colors.transparent,
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: const TextStyle(
            color: _kTextPrimary,
            fontSize: 12,
          ),
        ),
        tooltipBehavior: _trendTooltip,
        primaryXAxis: CategoryAxis(
          axisLine: const AxisLine(color: Color(0x66FFFFFF)),
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: const TextStyle(
            color: _kTextSecondary,
            fontSize: 12,
          ),
        ),
        primaryYAxis: NumericAxis(
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(
            dashArray: [4, 4],
            color: Color(0x33FFFFFF),
          ),
          labelStyle: const TextStyle(
            color: _kTextSecondary,
            fontSize: 12,
          ),
        ),
        series: <CartesianSeries<dynamic, dynamic>>[
          LineSeries<TETopErrorTrendPointEntity, String>(
            name: 'First Fail',
            dataSource: trendData,
            xValueMapper: (item, _) => item.label,
            yValueMapper: (item, _) => item.firstFail,
            width: 3.2,
            color: _kErrorColor,
            onCreateShader: (details) {
              return LinearGradient(
                colors: [
                  _kErrorColor.withOpacity(0.55),
                  _kErrorColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(details.rect);
            },
            markerSettings: MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              width: 11,
              height: 11,
              borderColor: Colors.white,
              borderWidth: 2.2,
              color: _kErrorColor,
            ),
            enableTooltip: true,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              labelIntersectAction: LabelIntersectAction.shift,
            ),
          ),
          LineSeries<TETopErrorTrendPointEntity, String>(
            name: 'Repair Fail',
            dataSource: trendData,
            xValueMapper: (item, _) => item.label,
            yValueMapper: (item, _) => item.repairFail,
            width: 3.2,
            color: _kRepairColor,
            onCreateShader: (details) {
              return LinearGradient(
                colors: [
                  _kRepairColor.withOpacity(0.55),
                  _kRepairColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(details.rect);
            },
            markerSettings: MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              width: 11,
              height: 11,
              borderColor: Colors.white,
              borderWidth: 2.2,
              color: _kRepairColor,
            ),
            enableTooltip: true,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              labelIntersectAction: LabelIntersectAction.shift,
            ),
          ),
          LineSeries<TETopErrorTrendPointEntity, String>(
            name: 'Total',
            dataSource: trendData,
            xValueMapper: (item, _) => item.label,
            yValueMapper: (item, _) => item.total,
            width: 3.4,
            color: _kAccentColor,
            dashArray: const <double>[4, 2],
            onCreateShader: (details) {
              return LinearGradient(
                colors: [
                  _kAccentColor.withOpacity(0.55),
                  _kAccentColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(details.rect);
            },
            markerSettings: MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.diamond,
              width: 12,
              height: 12,
              borderColor: Colors.white,
              borderWidth: 2.2,
              color: _kAccentColor,
            ),
            enableTooltip: true,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              labelIntersectAction: LabelIntersectAction.shift,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopErrorTableRow extends StatelessWidget {
  const _TopErrorTableRow({
    required this.rank,
    required this.error,
    required this.accentColor,
    required this.selectedError,
    required this.selectedDetail,
    required this.onErrorTap,
    required this.onDetailTap,
  });

  final int rank;
  final TETopErrorEntity error;
  final Color accentColor;
  final TETopErrorEntity? selectedError;
  final TETopErrorDetailEntity? selectedDetail;
  final VoidCallback onErrorTap;
  final ValueChanged<TETopErrorDetailEntity> onDetailTap;

  @override
  Widget build(BuildContext context) {
    final details = error.details.take(3).toList();
    final isErrorSelected = selectedError?.errorCode == error.errorCode;
    final hasSelectedDetail =
        selectedDetail != null && details.contains(selectedDetail);

    Widget buildDetailColumn(String Function(TETopErrorDetailEntity detail) mapper) {
      if (details.isEmpty) {
        return const Text(
          '—',
          style: _kTableMutedStyle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final detail in details)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _DetailValueTile(
                label: mapper(detail),
                accentColor: accentColor,
                isSelected: selectedDetail == detail,
                onTap: () {
                  onErrorTap();
                  onDetailTap(detail);
                },
              ),
            ),
        ],
      );
    }

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _kTableGridColor.withOpacity(0.85)),
      color: Color.lerp(_kPanelColor, Colors.white, 0.12)!
          .withOpacity(hasSelectedDetail ? 0.98 : (isErrorSelected ? 0.94 : 0.84)),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(
            hasSelectedDetail ? 0.38 : (isErrorSelected ? 0.28 : 0.16),
          ),
          blurRadius: hasSelectedDetail ? 26 : (isErrorSelected ? 22 : 16),
          offset: const Offset(0, 10),
        ),
      ],
    );

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TableCell(
              spec: _kTopErrorColumns[0],
              showContent: true,
              addRightBorder: true,
              addBottomBorder: false,
              onTap: onErrorTap,
              child: _RankBadge(rank: rank, accentColor: accentColor),
            ),
            _TableCell(
              spec: _kTopErrorColumns[1],
              showContent: true,
              addRightBorder: true,
              addBottomBorder: false,
              onTap: onErrorTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    error.errorCode,
                    style: _kTableValueStyle.copyWith(fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 4,
                    width: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [accentColor.withOpacity(0.95), accentColor.withOpacity(0.5)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _TableCell(
              spec: _kTopErrorColumns[2],
              showContent: true,
              addRightBorder: true,
              addBottomBorder: false,
              onTap: onErrorTap,
              child: _SummaryStat(
                label: 'F_FAIL',
                value: error.firstFail,
                accentColor: _kErrorColor,
              ),
            ),
            _TableCell(
              spec: _kTopErrorColumns[3],
              showContent: true,
              addRightBorder: true,
              addBottomBorder: false,
              onTap: onErrorTap,
              child: _SummaryStat(
                label: 'R_FAIL',
                value: error.repairFail,
                accentColor: _kRepairColor,
              ),
            ),
            _TableCell(
              spec: _kTopErrorColumns[4],
              showContent: true,
              addRightBorder: true,
              addBottomBorder: false,
              onTap: details.isEmpty ? onErrorTap : null,
              child: buildDetailColumn((detail) => detail.modelName),
            ),
            _TableCell(
              spec: _kTopErrorColumns[5],
              showContent: true,
              addRightBorder: true,
              addBottomBorder: false,
              onTap: details.isEmpty ? onErrorTap : null,
              child: buildDetailColumn((detail) => detail.groupName),
            ),
            _TableCell(
              spec: _kTopErrorColumns[6],
              showContent: true,
              addRightBorder: true,
              addBottomBorder: false,
              child: buildDetailColumn((detail) => '${detail.firstFail}'),
            ),
            _TableCell(
              spec: _kTopErrorColumns[7],
              showContent: true,
              addRightBorder: false,
              addBottomBorder: false,
              child: buildDetailColumn((detail) => '${detail.repairFail}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.accentColor});

  final int rank;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withOpacity(0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        '#${rank.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final int value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value.toString(),
          style: _kTableValueStyle.copyWith(fontSize: 16, color: _kTextPrimary),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: _kTableMutedStyle.copyWith(
            color: accentColor.withOpacity(0.9),
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ],
    );
  }
}

class _DetailValueTile extends StatelessWidget {
  const _DetailValueTile({
    required this.label,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = isSelected
        ? _kTableValueStyle.copyWith(color: accentColor)
        : _kTableValueStyle.copyWith(
            fontSize: 12,
            color: _kTextPrimary.withOpacity(0.9),
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? accentColor.withOpacity(0.18) : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? accentColor.withOpacity(0.7)
                : _kTableGridColor.withOpacity(0.55),
            width: isSelected ? 1.3 : 0.75,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          label,
          style: textStyle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.spec,
    required this.child,
    required this.showContent,
    required this.addRightBorder,
    required this.addBottomBorder,
    this.onTap,
  });

  final _TableColumnSpec spec;
  final Widget child;
  final bool showContent;
  final bool addRightBorder;
  final bool addBottomBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = showContent ? child : const SizedBox.shrink();
    return Expanded(
      flex: spec.flex,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          alignment: spec.alignment,
          padding: spec.padding,
          decoration: BoxDecoration(
            border: Border(
              right: addRightBorder
                  ? const BorderSide(color: _kTableGridColor, width: 1)
                  : BorderSide.none,
              bottom: addBottomBorder
                  ? const BorderSide(color: _kTableGridColor, width: 1)
                  : BorderSide.none,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _TableColumnSpec {
  const _TableColumnSpec({
    required this.label,
    required this.flex,
    this.alignment = Alignment.center,
    this.textAlign = TextAlign.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  });

  final String label;
  final int flex;
  final Alignment alignment;
  final TextAlign textAlign;
  final EdgeInsets padding;
}

class _DistributionDatum {
  _DistributionDatum({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _TrendSeriesConfig {
  _TrendSeriesConfig({
    required this.error,
    required this.points,
    required this.color,
  });

  final TETopErrorEntity error;
  final List<TETopErrorTrendPointEntity> points;
  final Color color;
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurfaceMuted.withOpacity(0.68),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPanelBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: _kAccentColor, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _kTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kTextPrimary,
        side: const BorderSide(color: _kAccentColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}





class _Neon3DChartWrapper extends StatelessWidget {
  const _Neon3DChartWrapper({
    super.key,
    required this.child,
    this.tiltX = 0.18,
    this.tiltY = -0.18,
    this.padding = const EdgeInsets.all(8),
  });

  final Widget child;
  final double tiltX;
  final double tiltY;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      child: _Neon3DChartSurface(child: child, padding: padding),
      builder: (context, value, child) {
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateX(tiltX * value)
          ..rotateY(tiltY * value);
        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: child,
        );
      },
    );
  }
}

class _Neon3DChartSurface extends StatelessWidget {
  const _Neon3DChartSurface({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF12335C), Color(0xFF06132A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4437D4FF),
            blurRadius: 36,
            offset: Offset(0, 20),
            spreadRadius: 6,
          ),
          BoxShadow(
            color: Color(0x33112940),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            right: -60,
            bottom: -80,
            child: Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x4422D3EE), Colors.transparent],
                  radius: 0.95,
                  center: Alignment.topCenter,
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyGridPainter extends CustomPainter {
  const _WeeklyGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF2F70C9).withOpacity(0.45), Colors.transparent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1;

    final spacing = size.height / 10;
    for (var i = 1; i < 10; i++) {
      final y = spacing * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
