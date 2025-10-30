
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
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_kAccentColor)),
        );
      }

      if (hasError && data.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _kErrorColor, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to load data',
                style: const TextStyle(color: _kTextPrimary, fontSize: 16),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            const gap = 16.0;
            return SizedBox(
              height: constraints.maxHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildErrorListPanel(isWide: true),
                        ),
                        const SizedBox(height: gap),
                        Expanded(
                          flex: 3,
                          child: _buildDetailTable(isWide: true, expand: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildDistributionPanel(),
                        ),
                        const SizedBox(height: gap),
                        Expanded(
                          flex: 2,
                          child: _buildTrendPanel(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildErrorListPanel(isWide: false),
          const SizedBox(height: 18),
          SizedBox(
            height: 280,
            child: _buildDistributionPanel(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 420,
            child: _buildTrendPanel(),
          ),
          const SizedBox(height: 18),
          _buildDetailTable(isWide: false),
        ],
      );
    });
  }

  Widget _buildErrorListPanel({required bool isWide}) {
    return Obx(() {
      final data = _controller.errors;
      final selectedError = _controller.selectedError.value;
      return Container(
        decoration: BoxDecoration(
          color: _kPanelColor.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kPanelBorderColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kSurfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 18, color: _kAccentColor),
                      SizedBox(width: 8),
                      Text(
                        'Top 10 Error Codes',
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
                    const SizedBox(height: 8),
                    Text(
                      _controller.rangeLabel,
                      style: const TextStyle(
                        color: _kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (isWide)
              Expanded(
                child: _buildErrorListView(
                  data: data,
                  selected: selectedError,
                  isWide: true,
                ),
              )
            else
              _buildErrorListView(
                data: data,
                selected: selectedError,
                isWide: false,
              ),
          ],
        ),
      );
    });
  }

  Widget _buildErrorListView({
    required List<TETopErrorEntity> data,
    required TETopErrorEntity? selected,
    required bool isWide,
  }) {
    if (isWide) {
      return _buildWideErrorTable(
        data: data,
        selected: selected,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 6),
      itemBuilder: (context, index) {
        final item = data[index];
        final isSelected = selected == item;
        final barColor = _barPalette[index % _barPalette.length];

        return _buildErrorCard(
          item: item,
          barColor: barColor,
          index: index,
          isSelected: isSelected,
          compact: false,
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: data.length,
    );
  }

  Widget _buildWideErrorTable({
    required List<TETopErrorEntity> data,
    required TETopErrorEntity? selected,
  }) {
    final selectedDetail = _controller.selectedDetail.value;

    if (data.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWideErrorHeader(),
          const Expanded(
            child: Center(
              child: Text(
                'No data available',
                style: TextStyle(color: _kTextSecondary, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasHeight = constraints.maxHeight.isFinite;
        final double availableHeight = hasHeight ? constraints.maxHeight : 0;
        const double preferredRowExtent = 68;
        final bool enableScroll = hasHeight
            ? availableHeight < (preferredRowExtent * data.length)
            : false;
        final ScrollPhysics physics = enableScroll
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWideErrorHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                physics: physics,
                shrinkWrap: !hasHeight,
                padding: const EdgeInsets.only(bottom: 8, right: 4),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  final isSelected = selected == item;
                  final barColor = _barPalette[index % _barPalette.length];
                  return _buildWideErrorRow(
                    item: item,
                    index: index,
                    barColor: barColor,
                    isSelected: isSelected,
                    selectedDetail: selectedDetail,
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWideErrorHeader() {
    Widget buildLabel(String text, {TextAlign align = TextAlign.left}) {
      return Text(
        text,
        textAlign: align,
        style: const TextStyle(
          color: _kTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPanelBorderColor.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 36, child: Text('Top', style: TextStyle(color: _kTextSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(flex: 4, child: buildLabel('Error Code')),
          SizedBox(width: 68, child: buildLabel('First', align: TextAlign.right)),
          const SizedBox(width: 12),
          SizedBox(width: 68, child: buildLabel('Repair', align: TextAlign.right)),
          const SizedBox(width: 12),
          SizedBox(width: 72, child: buildLabel('Total', align: TextAlign.right)),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: buildLabel('Top Models / Stations')),
        ],
      ),
    );
  }

  Widget _buildWideErrorRow({
    required TETopErrorEntity item,
    required int index,
    required Color barColor,
    required bool isSelected,
    required TETopErrorDetailEntity? selectedDetail,
  }) {
    final total = item.totalFail == 0 ? 1.0 : item.totalFail.toDouble();
    final firstRatio = item.firstFail / total;
    final repairRatio = item.repairFail / total;
    final chips = item.details.take(2).toList();

    return GestureDetector(
      onTap: () async {
        await _controller.selectError(item);
        if (selectedDetail != null && !chips.contains(selectedDetail)) {
          _controller.clearDetailSelection();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? barColor : _kPanelBorderColor.withOpacity(0.4),
            width: isSelected ? 1.4 : 1,
          ),
          color: isSelected
              ? _kPanelColor.withOpacity(0.96)
              : _kPanelColor.withOpacity(0.78),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: barColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    item.errorCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 68,
                  child: Text(
                    '${item.firstFail}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: _kTextPrimary, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 68,
                  child: Text(
                    '${item.repairFail}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: _kTextPrimary, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 72,
                  child: Text(
                    '${item.totalFail}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: barColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: chips.isEmpty
                        ? const Text(
                            '—',
                            style: TextStyle(
                              color: _kTextSecondary,
                              fontSize: 11,
                            ),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: chips.map((detail) {
                              final isChipSelected = selectedDetail == detail;
                              return GestureDetector(
                                onTap: () async {
                                  await _controller.selectError(item);
                                  await _controller.selectDetail(detail);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isChipSelected
                                        ? barColor.withOpacity(0.24)
                                        : _kSurfaceMuted.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isChipSelected
                                          ? barColor
                                          : _kPanelBorderColor.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    '${detail.modelName} · ${detail.groupName}',
                                    style: TextStyle(
                                      color: isChipSelected
                                          ? barColor
                                          : _kTextSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: _kSurfaceMuted,
                borderRadius: BorderRadius.circular(12),
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
                        child:
                            Container(color: _kErrorColor.withOpacity(0.9)),
                      ),
                      Positioned(
                        left: firstWidth,
                        width: math.max(repairWidth, 0),
                        top: 0,
                        bottom: 0,
                        child:
                            Container(color: _kRepairColor.withOpacity(0.9)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard({
    required TETopErrorEntity item,
    required Color barColor,
    required int index,
    required bool isSelected,
    required bool compact,
  }) {
    final total = item.totalFail == 0 ? 1.0 : item.totalFail.toDouble();
    final firstRatio = item.firstFail / total;
    final repairRatio = item.repairFail / total;

    return GestureDetector(
      onTap: () => _controller.selectError(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 20,
          vertical: compact ? 12 : 18,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 12 : 18),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    barColor.withOpacity(0.18),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: Border.all(
            color: isSelected ? barColor : _kPanelBorderColor,
            width: isSelected ? 1.6 : 1,
          ),
          color: isSelected
              ? _kPanelColor.withOpacity(0.92)
              : _kPanelColor.withOpacity(0.78),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 12,
                    vertical: compact ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: barColor,
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.errorCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _kTextPrimary,
                          fontSize: compact ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'F ${item.firstFail} · R ${item.repairFail} · Σ ${item.totalFail}',
                        style: TextStyle(
                          color: _kTextSecondary,
                          fontSize: compact ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: compact ? 18 : 20,
                  color: isSelected ? barColor : _kTextSecondary,
                ),
              ],
            ),
            SizedBox(height: compact ? 10 : 12),
            Container(
              height: compact ? 6 : 10,
              decoration: BoxDecoration(
                color: _kSurfaceMuted,
                borderRadius: BorderRadius.circular(12),
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
                        width: firstWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(color: _kErrorColor.withOpacity(0.85)),
                      ),
                      Positioned(
                        left: firstWidth,
                        width: repairWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(color: _kRepairColor.withOpacity(0.85)),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            Row(
              children: [
                _StatTile(
                  color: _kErrorColor,
                  title: 'First',
                  value: item.firstFail.toString(),
                  fraction: firstRatio,
                  compact: compact,
                ),
                const SizedBox(width: 8),
                _StatTile(
                  color: _kRepairColor,
                  title: 'Repair',
                  value: item.repairFail.toString(),
                  fraction: repairRatio,
                  compact: compact,
                ),
                const SizedBox(width: 8),
                _StatTile(
                  color: barColor,
                  title: 'Total',
                  value: item.totalFail.toString(),
                  fraction: 1,
                  compact: compact,
                ),
              ],
            ),
            if (item.details.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: compact ? 10 : 12),
                child: _buildDetailChipRow(
                  item: item,
                  barColor: barColor,
                  compact: compact,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChipRow({
    required TETopErrorEntity item,
    required Color barColor,
    required bool compact,
  }) {
    final selectedDetail = _controller.selectedDetail.value;
    final visibleDetails = item.details.take(compact ? 2 : 3).toList();
    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: visibleDetails.map((detail) {
        final isSelected = selectedDetail == detail;
        return GestureDetector(
          onTap: () async {
            await _controller.selectError(item);
            await _controller.selectDetail(detail);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? barColor.withOpacity(0.22)
                  : _kSurfaceMuted.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? barColor : _kSurfaceMuted,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  detail.modelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _kTextPrimary,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        detail.groupName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _kTextSecondary,
                          fontSize: compact ? 10 : 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'F ${detail.firstFail}',
                      style: TextStyle(
                        color: _kErrorColor,
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'R ${detail.repairFail}',
                      style: TextStyle(
                        color: _kRepairColor,
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDistributionPanel() {
    return Obx(() {
      final errors = _controller.errors;
      final totalFailures = errors.fold<int>(
        0,
        (sum, item) => sum + item.totalFail,
      );

      return Container(
        decoration: BoxDecoration(
          color: _kPanelColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kPanelBorderColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.donut_small_outlined, color: _kAccentColor),
                const SizedBox(width: 8),
                const Text(
                  'Failure Distribution',
                  style: TextStyle(
                    color: _kTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total Failures: $totalFailures',
                  style: const TextStyle(color: _kTextSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                      legend: Legend(
                        isVisible: true,
                        position: LegendPosition.right,
                        overflowMode: LegendItemOverflowMode.wrap,
                        textStyle:
                            const TextStyle(color: _kTextSecondary, fontSize: 11),
                        itemPadding: 8,
                      ),
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        color: const Color(0xFF0B1F39),
                        header: '',
                        textStyle:
                            const TextStyle(color: Colors.white, fontSize: 11),
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
          color: _kPanelColor.withOpacity(0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kPanelBorderColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.timeline_outlined, color: _kAccentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedDetail == null
                        ? '${selectedError?.errorCode ?? '--'} · Weekly Trend'
                        : '${selectedDetail.modelName} · ${selectedDetail.groupName}',
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedDetail != null)
                  TextButton.icon(
                    onPressed: _controller.clearDetailSelection,
                    style: TextButton.styleFrom(
                      foregroundColor: _kAccentColor,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Back to error code'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _controller.rangeLabel,
              style: const TextStyle(color: _kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: trendLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_kAccentColor),
                        ),
                      )
                    : hasTrendError
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
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

  Widget _buildDetailTable({required bool isWide, bool expand = false}) {
    final table = Obx(() {
      final errors = _controller.errors;
      final selectedError = _controller.selectedError.value;
      final selectedDetail = _controller.selectedDetail.value;

      return Container(
        decoration: BoxDecoration(
          color: _kPanelColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kPanelBorderColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart_outlined, color: _kAccentColor),
                const SizedBox(width: 8),
                const Text(
                  'Detail Breakdown',
                  style: TextStyle(
                    color: _kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  _controller.rangeLabel,
                  style: const TextStyle(color: _kTextSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap a row to focus the weekly trend by error, model, and station.',
              style: TextStyle(color: _kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: errors.isEmpty
                  ? const Center(
                      child: Text(
                        'No detailed data available.',
                        style: TextStyle(color: _kTextSecondary),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kSurfaceMuted.withOpacity(0.35),
                          border: Border.all(
                            color: _kPanelBorderColor.withOpacity(0.6),
                          ),
                        ),
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            scrollbars: false,
                            physics: const BouncingScrollPhysics(),
                          ),
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 860),
                                child: DataTableTheme(
                                  data: DataTableThemeData(
                                    headingRowColor: MaterialStatePropertyAll(
                                      _kSurfaceMuted.withOpacity(0.75),
                                    ),
                                    dataRowColor:
                                        const MaterialStatePropertyAll(Colors.transparent),
                                    headingTextStyle: const TextStyle(
                                      color: _kTextPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                    dataTextStyle: const TextStyle(
                                      color: _kTextPrimary,
                                      fontSize: 12,
                                    ),
                                    dividerThickness: 0.6,
                                  ),
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    headingRowHeight: 44,
                                    dataRowMinHeight: 44,
                                    dataRowMaxHeight: 52,
                                    columnSpacing: 18,
                                    horizontalMargin: 16,
                                    border: TableBorder(
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
                                      verticalInside: BorderSide(
                                        color: _kPanelBorderColor.withOpacity(0.4),
                                        width: 0.8,
                                      ),
                                      horizontalInside: BorderSide(
                                        color: _kPanelBorderColor.withOpacity(0.4),
                                        width: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('Top')),
                                      DataColumn(label: Text('Error Code')),
                                      DataColumn(label: Text('F_FAIL'), numeric: true),
                                      DataColumn(label: Text('R_FAIL'), numeric: true),
                                      DataColumn(label: Text('Model Name (Top 3)')),
                                      DataColumn(label: Text('Group Name')),
                                      DataColumn(label: Text('First Fail'), numeric: true),
                                      DataColumn(label: Text('Repair Fail'), numeric: true),
                                    ],
                                    rows: _buildDetailRows(
                                      errors: errors,
                                      selectedError: selectedError,
                                      selectedDetail: selectedDetail,
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
    final tableHeight = isWide ? 320.0 : 420.0;
    return SizedBox(height: tableHeight, child: table);
  }


  List<DataRow> _buildDetailRows({
    required List<TETopErrorEntity> errors,
    required TETopErrorEntity? selectedError,
    required TETopErrorDetailEntity? selectedDetail,
  }) {
    final rows = <DataRow>[];
    for (var i = 0; i < errors.length; i++) {
      final error = errors[i];
      final details = error.details.isNotEmpty
          ? error.details.take(3).toList()
          : <TETopErrorDetailEntity?>[null];

      for (var j = 0; j < details.length; j++) {
        final detail = details[j];
        final isFirst = j == 0;
        final highlight = selectedDetail != null
            ? (detail != null && selectedDetail == detail)
            : selectedError == error;
        final color = highlight ? Colors.white.withOpacity(0.07) : Colors.transparent;

        rows.add(
          DataRow(
            color: MaterialStateProperty.resolveWith<Color?>(
              (states) => color == Colors.transparent ? null : color,
            ),
            onSelectChanged: (_) async {
              await _controller.selectError(error);
              if (detail != null) {
                await _controller.selectDetail(detail);
              } else {
                _controller.clearDetailSelection();
              }
            },
            cells: [
              DataCell(Text(isFirst ? '#${i + 1}' : '')),
              DataCell(Text(isFirst ? error.errorCode : '')),
              DataCell(Text(isFirst ? '${error.firstFail}' : '')),
              DataCell(Text(isFirst ? '${error.repairFail}' : '')),
              DataCell(Text(detail?.modelName ?? (error.details.isEmpty ? '—' : ''))),
              DataCell(Text(detail?.groupName ?? (error.details.isEmpty ? '—' : ''))),
              DataCell(Text(detail != null ? '${detail.firstFail}' : '—')),
              DataCell(Text(detail != null ? '${detail.repairFail}' : '—')),
            ],
          ),
        );
      }
    }

    return rows;
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.color,
    required this.title,
    required this.value,
    required this.fraction,
    this.compact = false,
  });

  final Color color;
  final String title;
  final String value;
  final double fraction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final percentage = (fraction * 100).clamp(0, 100).round();
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: compact ? 10.5 : 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: _kTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 15.5 : 18,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 6 : 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: color,
                      fontSize: compact ? 10.5 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
