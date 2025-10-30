
import 'dart:math' as math;

import 'package:flutter/material.dart';
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
  colors: [Color(0xFF010511), Color(0xFF051B3A)],
);
const Color _kPanelColor = Color(0xFF061B35);
const Color _kPanelBorderColor = Color(0xFF133257);
const Color _kAccentColor = Color(0xFF22D3EE);
const Color _kTextPrimary = Color(0xFFE6F1FF);
const Color _kTextSecondary = Color(0xFF9FB9D9);
const Color _kErrorColor = Color(0xFFFF7A7A);
const Color _kRepairColor = Color(0xFFA78BFA);
const Color _kSurfaceMuted = Color(0xFF0C2A4A);

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
    Color(0xFF5EEAD4),
    Color(0xFF60A5FA),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFFFF9E80),
    Color(0xFF4ADE80),
    Color(0xFF34D399),
    Color(0xFFF97316),
    Color(0xFF22D3EE),
    Color(0xFFEAB308),
  ];

  late final String _controllerTag;
  late final TETopErrorCodeController _controller;
  final DateFormat _rangeDisplayFormatter = DateFormat('yyyy/MM/dd HH:mm');
  final TooltipBehavior _trendTooltip = TooltipBehavior(
    enable: true,
    color: const Color(0xFF0B1F39),
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
          builder: (context, constraints) {
            const gap = 20.0;
            final chartHeight = math.max(
              300.0,
              math.min(constraints.maxHeight * 0.48, 420.0),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: chartHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildDistributionPanel()),
                      const SizedBox(width: gap),
                      Expanded(child: _buildTrendPanel()),
                    ],
                  ),
                ),
                const SizedBox(height: gap),
                Expanded(
                  child: _buildTopErrorTablePanel(
                    isWide: true,
                    expand: true,
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

  Widget _buildTopErrorTablePanel({required bool isWide, bool expand = false}) {
    final table = Obx(() {
      final errors = _controller.errors;
      final selectedError = _controller.selectedError.value;
      final selectedDetail = _controller.selectedDetail.value;
      final totalFailures = errors.fold<int>(0, (sum, item) => sum + item.totalFail);

      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1F44), Color(0xFF061228)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _kPanelBorderColor.withOpacity(0.9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80131F3D),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kSurfaceMuted.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kPanelBorderColor.withOpacity(0.8)),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TERefreshLabel(
                      lastUpdated: _controller.lastUpdated.value,
                      isRefreshing: _controller.isLoading.value,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _controller.rangeLabel,
                      style: const TextStyle(color: _kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Select an error or detail chip to focus the neon charts.',
              style: TextStyle(color: _kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: errors.isEmpty
                  ? const Center(
                      child: Text(
                        'No data available.',
                        style: TextStyle(color: _kTextSecondary),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kSurfaceMuted.withOpacity(0.45),
                          border: Border.all(color: _kPanelBorderColor.withOpacity(0.6)),
                        ),
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 860),
                                child: DataTableTheme(
                                  data: DataTableThemeData(
                                    headingRowColor: const MaterialStatePropertyAll(Color(0xFF0F2C55)),
                                    headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      fontSize: 13,
                                    ),
                                    dataRowColor: const MaterialStatePropertyAll(Colors.transparent),
                                    dataTextStyle: const TextStyle(
                                      color: _kTextPrimary,
                                      fontSize: 12,
                                    ),
                                    dividerThickness: 0.7,
                                  ),
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    headingRowHeight: 46,
                                    dataRowMinHeight: 60,
                                    dataRowMaxHeight: 88,
                                    horizontalMargin: 16,
                                    columnSpacing: 20,
                                    border: TableBorder(
                                      horizontalInside: BorderSide(
                                        color: _kPanelBorderColor.withOpacity(0.4),
                                        width: 0.7,
                                      ),
                                      verticalInside: BorderSide(
                                        color: _kPanelBorderColor.withOpacity(0.4),
                                        width: 0.7,
                                      ),
                                      top: BorderSide(
                                        color: _kPanelBorderColor.withOpacity(0.6),
                                        width: 0.8,
                                      ),
                                      bottom: BorderSide(
                                        color: _kPanelBorderColor.withOpacity(0.6),
                                        width: 0.8,
                                      ),
                                      left: BorderSide(
                                        color: _kPanelBorderColor.withOpacity(0.6),
                                        width: 0.8,
                                      ),
                                      right: BorderSide(
                                        color: _kPanelBorderColor.withOpacity(0.6),
                                        width: 0.8,
                                      ),
                                    ),
                                    columns: const [
                                      DataColumn(label: _NeonTableHeader('TOP')),
                                      DataColumn(label: _NeonTableHeader('ERROR CODE')),
                                      DataColumn(label: _NeonTableHeader('F_FAIL'), numeric: true),
                                      DataColumn(label: _NeonTableHeader('R_FAIL'), numeric: true),
                                      DataColumn(label: _NeonTableHeader('Σ / SHARE')),
                                      DataColumn(label: _NeonTableHeader('TOP DETAIL')),
                                    ],
                                    rows: _buildErrorTableRows(
                                      errors: errors,
                                      selectedError: selectedError,
                                      selectedDetail: selectedDetail,
                                      totalFailures: totalFailures,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
    });

    if (expand) {
      return table;
    }

    final height = isWide ? 360.0 : 460.0;
    return SizedBox(height: height, child: table);
  }

  List<DataRow> _buildErrorTableRows({
    required List<TETopErrorEntity> errors,
    required TETopErrorEntity? selectedError,
    required TETopErrorDetailEntity? selectedDetail,
    required int totalFailures,
  }) {
    return List.generate(errors.length, (index) {
      final item = errors[index];
      final barColor = _barPalette[index % _barPalette.length];
      final chips = item.details.take(3).toList();
      final rowSelected = selectedError == item;
      final highlightColor = rowSelected ? barColor.withOpacity(0.22) : Colors.transparent;

      return DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
          (states) => highlightColor == Colors.transparent ? null : highlightColor,
        ),
        onSelectChanged: (_) async {
          await _controller.selectError(item);
          if (selectedDetail != null && !chips.contains(selectedDetail)) {
            _controller.clearDetailSelection();
          }
        },
        cells: [
          DataCell(Text('#${index + 1}', style: TextStyle(color: barColor, fontWeight: FontWeight.w700))),
          DataCell(Text(
            item.errorCode,
            style: const TextStyle(
              color: _kTextPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          )),
          DataCell(Text('${item.firstFail}')),
          DataCell(Text('${item.repairFail}')),
          DataCell(_buildShareCell(
            color: barColor,
            first: item.firstFail,
            repair: item.repairFail,
            total: item.totalFail,
            totalFailures: totalFailures,
          )),
          DataCell(_buildDetailChipWrap(
            item: item,
            barColor: barColor,
            selectedDetail: selectedDetail,
            chips: chips,
          )),
        ],
      );
    });
  }

  Widget _buildShareCell({
    required Color color,
    required int first,
    required int repair,
    required int total,
    required int totalFailures,
  }) {
    final safeTotal = total == 0 ? 1.0 : total.toDouble();
    final firstRatio = first / safeTotal;
    final repairRatio = repair / safeTotal;
    final share = totalFailures == 0 ? 0.0 : total / totalFailures;

    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: _kSurfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final firstWidth = width * firstRatio;
                final repairWidth = width * repairRatio;
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      width: math.max(firstWidth, 0),
                      top: 0,
                      bottom: 0,
                      child: Container(color: _kErrorColor.withOpacity(0.9)),
                    ),
                    Positioned(
                      left: firstWidth,
                      width: math.max(repairWidth, 0),
                      top: 0,
                      bottom: 0,
                      child: Container(color: _kRepairColor.withOpacity(0.9)),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Σ $total',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                '${(share * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: _kTextSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChipWrap({
    required TETopErrorEntity item,
    required Color barColor,
    required TETopErrorDetailEntity? selectedDetail,
    required List<TETopErrorDetailEntity> chips,
  }) {
    if (chips.isEmpty) {
      return const Text(
        'No breakdown',
        style: TextStyle(color: _kTextSecondary, fontSize: 11),
      );
    }

    return SizedBox(
      width: 220,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips.map((detail) {
          final isSelected = selectedDetail == detail;
          final label = '${detail.modelName} · ${detail.groupName}';
          final total = detail.firstFail + detail.repairFail;
          return GestureDetector(
            onTap: () async {
              await _controller.selectError(item);
              await _controller.selectDetail(detail);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          barColor.withOpacity(0.28),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? _kPanelColor.withOpacity(0.9)
                    : _kSurfaceMuted.withOpacity(0.82),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? barColor
                      : _kPanelBorderColor.withOpacity(0.6),
                  width: isSelected ? 1.2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: barColor.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? barColor : _kTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'F ${detail.firstFail} · R ${detail.repairFail} · Σ $total',
                    style: const TextStyle(
                      color: _kTextSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

class _NeonTableHeader extends StatelessWidget {
  const _NeonTableHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: _kAccentColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
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
            colors: [Color(0xFF102A54), Color(0xFF050C1F)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _kPanelBorderColor.withOpacity(0.85)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66131F3C),
              blurRadius: 26,
              offset: Offset(0, 16),
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
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kPanelBorderColor.withOpacity(0.6)),
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
                          color: _kTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        color: const Color(0xFF0B1F39),
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

      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D2144), Color(0xFF040A1C)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _kPanelBorderColor.withOpacity(0.85)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55121E3B),
              blurRadius: 26,
              offset: Offset(0, 16),
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
                        selectedDetail == null
                            ? '${selectedError?.errorCode ?? '--'} · Weekly Trend'
                            : '${selectedDetail.modelName} · ${selectedDetail.groupName}',
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
                if (selectedDetail != null)
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
                child: trendLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_kAccentColor),
                        ),
                      )
                    : hasTrendError
                        ? Center(
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
                          )
                        : trendData.isEmpty
                            ? const Center(
                                child: Text(
                                  'No weekly trend data available.',
                                  style: TextStyle(
                                    color: _kTextSecondary,
                                  ),
                                ),
                              )
                            : SfCartesianChart(
                                backgroundColor: Colors.transparent,
                                margin: const EdgeInsets.only(top: 6, right: 6, bottom: 6),
                                plotAreaBorderWidth: 0,
                                legend: Legend(
                                  isVisible: true,
                                  textStyle: const TextStyle(
                                    color: _kTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                tooltipBehavior: _trendTooltip,
                                primaryXAxis: CategoryAxis(
                                  axisLine: const AxisLine(color: _kPanelBorderColor),
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
                                    color: Color(0xFF123357),
                                  ),
                                  labelStyle: const TextStyle(
                                    color: _kTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                series: <CartesianSeries<dynamic, dynamic>>[
                                  ColumnSeries<dynamic, dynamic>(
                                    name: 'First Fail',
                                    dataSource: trendData,
                                    xValueMapper: (item, _) =>
                                        (item as TETopErrorTrendPointEntity).label,
                                    yValueMapper: (item, _) =>
                                        (item as TETopErrorTrendPointEntity).firstFail,
                                    color: _kErrorColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10),
                                    ),
                                    dataLabelSettings: const DataLabelSettings(
                                      isVisible: true,
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  ColumnSeries<dynamic, dynamic>(
                                    name: 'Repair Fail',
                                    dataSource: trendData,
                                    xValueMapper: (item, _) =>
                                        (item as TETopErrorTrendPointEntity).label,
                                    yValueMapper: (item, _) =>
                                        (item as TETopErrorTrendPointEntity).repairFail,
                                    color: _kRepairColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10),
                                    ),
                                    dataLabelSettings: const DataLabelSettings(
                                      isVisible: true,
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  LineSeries<dynamic, dynamic>(
                                    name: 'Total',
                                    dataSource: trendData,
                                    xValueMapper: (item, _) =>
                                        (item as TETopErrorTrendPointEntity).label,
                                    yValueMapper: (item, _) =>
                                        (item as TETopErrorTrendPointEntity).total,
                                    color: _kAccentColor,
                                    markerSettings: const MarkerSettings(
                                      isVisible: true,
                                      shape: DataMarkerType.circle,
                                      width: 8,
                                      height: 8,
                                      borderColor: Colors.black,
                                      borderWidth: 1,
                                    ),
                                    dataLabelSettings: const DataLabelSettings(
                                      isVisible: true,
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
              ),
            ),
          ],
        ),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _kBackgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: _kTextSecondary),
          leading: const BackButton(color: _kTextSecondary),
          title: Obx(() {
            final modelSerial = _controller.modelSerial.value;
            return Text(
              widget.title ?? 'TE TOP 10 ERROR CODE ($modelSerial)',
              style: const TextStyle(
                color: _kTextPrimary,
                fontFamily: 'Arial',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            );
          }),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _toggleFilterPanel,
              icon: Icon(
                _isFilterPanelOpen
                    ? Icons.close_fullscreen
                    : Icons.filter_alt_outlined,
                color: _isFilterPanelOpen ? _kAccentColor : _kTextSecondary,
              ),
              tooltip: _isFilterPanelOpen ? 'Hide filters' : 'Show filters',
            ),
            Obx(() {
              final busy = _controller.isLoading.value;
              return IconButton(
                onPressed: busy ? null : () => _controller.refresh(),
                icon: const Icon(Icons.refresh, color: _kAccentColor),
                tooltip: 'Refresh',
              );
            }),
            const SizedBox(width: 8),
          ],
        ),
        body: ResponsiveBuilder(
          builder: (context, sizing) {
            final horizontalPadding = sizing.screenSize.width > 1200 ? 32.0 : 18.0;
            final verticalPadding = sizing.isDesktop ? 24.0 : 14.0;
            return SafeArea(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: _buildContent(sizing),
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
