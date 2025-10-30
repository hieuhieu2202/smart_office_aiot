
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
  final ScrollController _tableScrollController = ScrollController();

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
    _tableScrollController.dispose();
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
    final panel = Obx(() {
      final errors = _controller.errors;
      final selectedError = _controller.selectedError.value;
      final selectedDetail = _controller.selectedDetail.value;

      final rows = <_ErrorTableRowData>[];
      for (var i = 0; i < errors.length; i++) {
        final error = errors[i];
        final details = error.details.take(3).toList();
        if (details.isEmpty) {
          rows.add(
            _ErrorTableRowData(
              error: error,
              detail: null,
              rank: i + 1,
              showMeta: true,
            ),
          );
        } else {
          for (var j = 0; j < details.length; j++) {
            rows.add(
              _ErrorTableRowData(
                error: error,
                detail: details[j],
                rank: i + 1,
                showMeta: j == 0,
              ),
            );
          }
        }
      }

      if (rows.isEmpty && _tableScrollController.hasClients) {
        _tableScrollController.jumpTo(0);
      }

      final tableBody = rows.isEmpty
          ? const Center(
              child: Text(
                'No data available for the selected filters.',
                style: TextStyle(color: _kTextSecondary),
              ),
            )
          : RawScrollbar(
              controller: _tableScrollController,
              thumbVisibility: rows.length > 6,
              radius: const Radius.circular(12),
              thickness: 6,
              interactive: true,
              child: ListView.builder(
                controller: _tableScrollController,
                padding: EdgeInsets.zero,
                itemCount: rows.length,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  final data = rows[index];
                  final barColor = _barPalette[(data.rank - 1) % _barPalette.length];
                  final isSelected = selectedError == data.error &&
                      (selectedDetail == null
                          ? data.showMeta
                          : data.detail == selectedDetail);
                  return _buildTableDataRow(
                    data: data,
                    barColor: barColor,
                    isSelected: isSelected,
                    isStriped: index.isEven,
                  );
                },
              ),
            );

      final headerRow = Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kPanelBorderColor.withOpacity(0.6)),
          color: _kSurfaceMuted.withOpacity(0.4),
        ),
        child: Row(
          children: const [
            _NeonTableHeaderCell(label: 'TOP', flex: 8, alignment: Alignment.center),
            _NeonTableHeaderCell(label: 'ERROR CODE', flex: 18),
            _NeonTableHeaderCell(label: 'F_FAIL', flex: 10, alignment: Alignment.center),
            _NeonTableHeaderCell(label: 'R_FAIL', flex: 10, alignment: Alignment.center),
            _NeonTableHeaderCell(label: 'MODEL NAME (Top 3)', flex: 20),
            _NeonTableHeaderCell(label: 'GROUP_NAME', flex: 16),
            _NeonTableHeaderCell(label: 'FIRST FAIL', flex: 9, alignment: Alignment.center),
            _NeonTableHeaderCell(label: 'REPAIR FAIL', flex: 9, alignment: Alignment.center),
          ],
        ),
      );

      final content = Column(
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
          const SizedBox(height: 16),
          headerRow,
          const SizedBox(height: 12),
          Expanded(child: tableBody),
        ],
      );

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
        child: content,
      );
    });

    if (expand) {
      return panel;
    }

    final height = isWide ? 360.0 : 460.0;
    return SizedBox(height: height, child: panel);
  }

  Widget _buildTableDataRow({
    required _ErrorTableRowData data,
    required Color barColor,
    required bool isSelected,
    required bool isStriped,
  }) {
    final detail = data.detail;
    final hasDetail = detail != null;
    final backgroundColor = isSelected
        ? barColor.withOpacity(0.2)
        : isStriped
            ? _kSurfaceMuted.withOpacity(0.18)
            : Colors.transparent;

    return InkWell(
      onTap: () async {
        await _controller.selectError(data.error);
        if (detail != null) {
          await _controller.selectDetail(detail);
        } else {
          _controller.clearDetailSelection();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? barColor.withOpacity(0.7)
                : _kPanelBorderColor.withOpacity(0.35),
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: barColor.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _buildTableDataCell(
              '#${data.rank}',
              flex: 8,
              alignment: Alignment.center,
              color: barColor,
              fontWeight: FontWeight.w700,
              invisible: !data.showMeta,
            ),
            _buildTableDataCell(
              data.error.errorCode,
              flex: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              invisible: !data.showMeta,
            ),
            _buildTableDataCell(
              data.error.firstFail.toString(),
              flex: 10,
              alignment: Alignment.center,
              fontWeight: FontWeight.w700,
              invisible: !data.showMeta,
            ),
            _buildTableDataCell(
              data.error.repairFail.toString(),
              flex: 10,
              alignment: Alignment.center,
              fontWeight: FontWeight.w700,
              invisible: !data.showMeta,
            ),
            _buildTableDataCell(
              hasDetail ? detail!.modelName : '—',
              flex: 20,
              muted: !hasDetail,
              maxLines: 2,
            ),
            _buildTableDataCell(
              hasDetail ? detail!.groupName : '—',
              flex: 16,
              muted: !hasDetail,
              maxLines: 2,
            ),
            _buildTableDataCell(
              hasDetail ? detail!.firstFail.toString() : '—',
              flex: 9,
              alignment: Alignment.center,
              fontWeight: FontWeight.w600,
              muted: !hasDetail,
            ),
            _buildTableDataCell(
              hasDetail ? detail!.repairFail.toString() : '—',
              flex: 9,
              alignment: Alignment.center,
              fontWeight: FontWeight.w600,
              muted: !hasDetail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableDataCell(
    String text, {
    required int flex,
    Alignment alignment = Alignment.centerLeft,
    Color color = _kTextPrimary,
    FontWeight fontWeight = FontWeight.w500,
    double fontSize = 12,
    double letterSpacing = 0.2,
    bool muted = false,
    bool invisible = false,
    int maxLines = 1,
  }) {
    final style = TextStyle(
      color: muted ? _kTextSecondary.withOpacity(0.75) : color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );

    final label = Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style,
    );

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Align(
          alignment: alignment,
          child: invisible ? Opacity(opacity: 0.0, child: label) : label,
        ),
      ),
    );
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

class _NeonTableHeaderCell extends StatelessWidget {
  const _NeonTableHeaderCell({
    required this.label,
    required this.flex,
    this.alignment = Alignment.centerLeft,
    super.key,
  });

  final String label;
  final int flex;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: Text(
          label,
          style: const TextStyle(
            color: _kAccentColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _ErrorTableRowData {
  const _ErrorTableRowData({
    required this.error,
    required this.rank,
    required this.showMeta,
    this.detail,
  });

  final TETopErrorEntity error;
  final TETopErrorDetailEntity? detail;
  final int rank;
  final bool showMeta;
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
