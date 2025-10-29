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
  static const List<String> _modelSerials = ['ADAPTER', 'SWITCH'];
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
  final DateFormat _timeFormatter = DateFormat('HH:mm');
  final TooltipBehavior _trendTooltip = TooltipBehavior(
    enable: true,
    color: const Color(0xFF0B1F39),
    header: '',
    textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    borderWidth: 0,
  );

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

  Widget _buildControlBar(SizingInformation sizing) {
    return Obx(() {
      final start = _controller.startDateTime.value;
      final end = _controller.endDateTime.value;
      final isDesktop = sizing.isDesktop;
      final chipSpacing = isDesktop ? 12.0 : 8.0;
      return Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kPanelColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kPanelBorderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _controller.modelSerial.value,
                dropdownColor: _kPanelColor,
                iconEnabledColor: _kAccentColor,
                style: const TextStyle(
                  color: _kTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
                items: _modelSerials
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text('Model Serial: $item'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _controller.updateModelSerial(value);
                  }
                },
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _kPanelColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kPanelBorderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: chipSpacing,
              children: TETopErrorCategory.values.map((category) {
                final selected = category == _controller.category.value;
                return ChoiceChip(
                  label: Text(category.label),
                  selected: selected,
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : _kTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: _kAccentColor,
                  backgroundColor: _kSurfaceMuted,
                  onSelected: (_) => _controller.updateCategory(category),
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kPanelColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kPanelBorderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date Range',
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _RangeButton(
                      label: 'Start ${_timeFormatter.format(start)}',
                      onTap: () => _pickDateTime(isStart: true),
                    ),
                    _RangeButton(
                      label: 'End ${_timeFormatter.format(end)}',
                      onTap: () => _pickDateTime(isStart: false),
                    ),
                    ElevatedButton.icon(
                      onPressed: _controller.shiftToTodayRange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: _kAccentColor,
                        side: const BorderSide(color: _kAccentColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.today_outlined, size: 18),
                      label: const Text('Today'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TERefreshLabel(
            lastUpdated: _controller.lastUpdated.value,
            isRefreshing: _controller.isLoading.value,
          ),
        ],
      );
    });
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
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 11,
              child: _buildErrorListPanel(isWide: true),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 9,
              child: _buildAnalyticsPanel(),
            ),
          ],
        );
      }

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildErrorListPanel(isWide: false),
          const SizedBox(height: 20),
          _buildAnalyticsPanel(),
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
                Text(
                  _controller.rangeLabel,
                  style: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 12,
                  ),
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
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          const double spacing = 14.0;
          final crossAxisCount = maxWidth >= 1480 ? 3 : 2;
          final cardWidth =
              (maxWidth - ((crossAxisCount - 1) * spacing)) / crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(data.length, (index) {
              final item = data[index];
              final isSelected = selected == item;
              final barColor = _barPalette[index % _barPalette.length];
              return SizedBox(
                width: cardWidth,
                child: _buildErrorCard(
                  item: item,
                  barColor: barColor,
                  index: index,
                  isSelected: isSelected,
                  compact: true,
                ),
              );
            }),
          );
        },
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

    final contentPadding = EdgeInsets.symmetric(
      horizontal: compact ? 14 : 18,
      vertical: compact ? 14 : 18,
    );

    return GestureDetector(
      onTap: () => _controller.selectError(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: contentPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: barColor,
                      fontSize: compact ? 13 : 14,
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
                          fontSize: compact ? 17 : 18,
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
            SizedBox(height: compact ? 12 : 14),
            Container(
              height: compact ? 10 : 12,
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
            SizedBox(height: compact ? 10 : 12),
            Row(
              children: [
                _StatTile(
                  color: _kErrorColor,
                  title: 'First Fail',
                  value: item.firstFail.toString(),
                  fraction: firstRatio,
                  compact: compact,
                ),
                const SizedBox(width: 10),
                _StatTile(
                  color: _kRepairColor,
                  title: 'Repair Fail',
                  value: item.repairFail.toString(),
                  fraction: repairRatio,
                  compact: compact,
                ),
                const SizedBox(width: 10),
                _StatTile(
                  color: barColor,
                  title: 'Total',
                  value: item.totalFail.toString(),
                  fraction: 1,
                  compact: compact,
                ),
              ],
            ),
            if (item.details.isNotEmpty) ...[
              SizedBox(height: compact ? 10 : 12),
              Wrap(
                spacing: compact ? 6 : 8,
                runSpacing: compact ? 6 : 8,
                children: item.details.take(3).map((detail) {
                  final detailSelected =
                      _controller.selectedDetail.value == detail;
                  return GestureDetector(
                    onTap: () => _controller.selectDetail(detail),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 12,
                        vertical: compact ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: detailSelected
                            ? barColor.withOpacity(0.22)
                            : _kSurfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: detailSelected ? barColor : _kSurfaceMuted,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            detail.modelName,
                            style: TextStyle(
                              color: _kTextPrimary,
                              fontSize: compact ? 12 : 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            detail.groupName,
                            style: TextStyle(
                              color: _kTextSecondary,
                              fontSize: compact ? 11 : 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'F:${detail.firstFail}',
                                style: TextStyle(
                                  color: _kErrorColor,
                                  fontSize: compact ? 11 : 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'R:${detail.repairFail}',
                                style: TextStyle(
                                  color: _kRepairColor,
                                  fontSize: compact ? 11 : 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              SizedBox(height: compact ? 10 : 12),
              const Text(
                'No model breakdown available.',
                style: TextStyle(color: _kTextSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildAnalyticsPanel() {
    return Obx(() {
      final selectedError = _controller.selectedError.value;
      final selectedDetail = _controller.selectedDetail.value;
      final trendLoading = _controller.isTrendLoading.value;
      final hasTrendError = _controller.hasTrendError;
      final trendError = _controller.trendErrorMessage.value;
      final trendData = _controller.trendPoints;
      final totalFailures = _controller.errors.fold<int>(
        0,
        (sum, item) => sum + item.totalFail,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDistributionCard(totalFailures),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
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
                      const Icon(Icons.timeline_outlined,
                          color: _kAccentColor),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
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
                                              (item as TETopErrorTrendPointEntity)
                                                  .label,
                                          yValueMapper: (item, _) =>
                                              (item as TETopErrorTrendPointEntity)
                                                  .firstFail,
                                          color: _kErrorColor,
                                          borderRadius:
                                              const BorderRadius.vertical(
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
                                              (item as TETopErrorTrendPointEntity)
                                                  .label,
                                          yValueMapper: (item, _) =>
                                              (item as TETopErrorTrendPointEntity)
                                                  .repairFail,
                                          color: _kRepairColor,
                                          borderRadius:
                                              const BorderRadius.vertical(
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
                                              (item as TETopErrorTrendPointEntity)
                                                  .label,
                                          yValueMapper: (item, _) =>
                                              (item as TETopErrorTrendPointEntity)
                                                  .total,
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
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDistributionCard(int totalFailures) {
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
          SizedBox(
            height: 220,
            child: Obx(() {
              final data = _controller.errors;
              if (data.isEmpty) {
                return const Center(
                  child: Text(
                    'No data',
                    style: TextStyle(color: _kTextSecondary),
                  ),
                );
              }
              final chartData = <_DistributionDatum>[];
              for (var i = 0; i < data.length; i++) {
                final item = data[i];
                chartData.add(
                  _DistributionDatum(
                    label: item.errorCode,
                    value: item.totalFail.toDouble(),
                    color: _barPalette[i % _barPalette.length],
                  ),
                );
              }
              return SfCircularChart(
                backgroundColor: Colors.transparent,
                legend: Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                  textStyle: const TextStyle(color: _kTextSecondary, fontSize: 12),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  color: const Color(0xFF0B1F39),
                  header: '',
                  textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                series: <CircularSeries<_DistributionDatum, String>>[
                  DoughnutSeries<_DistributionDatum, String>(
                    dataSource: chartData,
                    xValueMapper: (datum, _) => datum.label,
                    yValueMapper: (datum, _) => datum.value,
                    pointColorMapper: (datum, _) => datum.color,
                    radius: '85%',
                    innerRadius: '58%',
                    explode: true,
                    explodeOffset: '4%',
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(color: Colors.white, fontSize: 11),
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
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
            final category = _controller.categoryLabel;
            return Text(
              widget.title ?? '$modelSerial · $category · Top 10 Error Codes',
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildControlBar(sizing),
                    const SizedBox(height: 20),
                    Expanded(child: _buildContent(sizing)),
                  ],
                ),
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
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 15 : 16,
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: fraction.clamp(0, 1),
                minHeight: compact ? 5 : 6,
                backgroundColor: Colors.black26,
                valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.7)),
              ),
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
