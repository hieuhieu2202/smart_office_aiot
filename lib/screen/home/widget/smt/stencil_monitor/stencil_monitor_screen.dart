import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:smart_factory/screen/home/controller/stencil_monitor_controller.dart';

import '../../../../../model/smt/stencil_detail.dart';
import '../../../../../widget/animation/loading/eva_loading_view.dart';

part 'widgets/stencil_monitor_filter_sheet.dart';
part 'widgets/stencil_monitor_common.dart';
part 'widgets/stencil_monitor_insights.dart';
part 'widgets/stencil_monitor_running_line.dart';
part 'widgets/stencil_monitor_detail_dialogs.dart';

class StencilMonitorScreen extends StatefulWidget {
  const StencilMonitorScreen({
    super.key,
    this.title,
    this.controllerTag,
  });

  final String? title;
  final String? controllerTag;

  @override
  State<StencilMonitorScreen> createState() => _StencilMonitorScreenState();
}

class _StencilMonitorScreenState extends State<StencilMonitorScreen> {
  late final String _controllerTag;
  late final StencilMonitorController controller;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  final List<Color> _neonPalette = const [
    Color(0xFF4DE1FF),
    Color(0xFF8F5BFF),
    Color(0xFF2CF6B3),
    Color(0xFFFFA726),
    Color(0xFFFF667D),
    Color(0xFF7CF0FF),
    Color(0xFFB388FF),
    Color(0xFF64FFDA),
  ];

  late _StencilColorScheme _palette;

  Color get _textPrimary => _palette.onSurface;
  Color get _textSecondary => _palette.onSurfaceMuted;
  Color get _axisLineColor => _palette.onSurface
      .withOpacity(_palette.brightness == Brightness.dark ? 0.25 : 0.2);
  Color get _gridLineColor => _palette.onSurface
      .withOpacity(_palette.brightness == Brightness.dark ? 0.12 : 0.1);
  Color get _tooltipBackground => _palette.brightness == Brightness.dark
      ? const Color(0xFF061F3C)
      : Colors.white;
  Color get _tooltipTextColor =>
      _palette.brightness == Brightness.dark ? Colors.white : Colors.black87;

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.controllerTag ?? 'stencil_monitor_default';
    controller = Get.put(StencilMonitorController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    if (Get.isRegistered<StencilMonitorController>(tag: _controllerTag)) {
      Get.delete<StencilMonitorController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _palette = _StencilColorScheme.of(context);
      final loading = controller.isLoading.value;
      final hasData = controller.stencilData.isNotEmpty;
      final filtered = controller.filteredData;
      final error = controller.error.value;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(
          context,
          loading: loading,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _palette.backgroundGradient,
            ),
          ),
          child: SafeArea(
            child: loading && !hasData
                ? const Center(child: EvaLoadingView(size: 140))
                : _buildContent(
                    context,
                    loading: loading,
                    error: error,
                    filtered: filtered,
                    hasData: hasData,
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildContent(
    BuildContext context, {
    required bool loading,
    required String error,
    required List<StencilDetail> filtered,
    required bool hasData,
  }) {
    if (error.isNotEmpty && !hasData) {
      return _buildFullError(error);
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: Theme.of(context).colorScheme.secondary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error.isNotEmpty) ...[
                      _buildErrorChip(error),
                      const SizedBox(height: 20),
                    ],
                    if (filtered.isEmpty)
                      _buildEmptyState()
                    else
                      _buildDashboard(context, filtered),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool loading,
  }) {
    final lastUpdated = controller.lastUpdated.value;
    final updateText = lastUpdated != null
        ? _dateFormat.format(lastUpdated)
        : 'Waiting for data…';
    final floorLabel = controller.selectedFloor.value == 'ALL'
        ? 'F06'
        : controller.selectedFloor.value;

    return AppBar(
      elevation: 2,
      automaticallyImplyLeading: true,
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SMT $floorLabel STENCIL MONITOR',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _palette.onSurface,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last update: $updateText',
            style: GoogleFonts.robotoMono(
              color: _palette.onSurfaceMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
      actions: [
        _FilterActionButton(controller: controller),
        IconButton(
          tooltip: 'Refresh',
          icon: Icon(loading ? Icons.sync : Icons.refresh),
          onPressed: () => controller.fetchData(force: true),
        ),
      ],
    );
  }

  Widget _buildErrorChip(String message) {
    final palette = _palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.errorBorder),
        color: palette.errorFill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(Icons.error_outline, color: palette.errorText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.robotoMono(
                color: palette.errorText,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => controller.fetchData(force: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<StencilDetail> filtered) {
    final customerSlices = _groupToPie(
      filtered,
      (item) => item.customerLabel,
      labelTransformer: _mapCustomerLabel,
    );
    final statusSlices = controller.statusBreakdown(filtered)
        .entries
        .map((e) => _PieSlice(e.key, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final vendorSlices = controller.vendorBreakdown(filtered)
        .entries
        .map((e) => _PieSlice(e.key, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final processSlices = _groupToPie(
      filtered,
      (item) {
        final raw = item.process?.trim().toUpperCase() ?? '';
        if (raw == 'T' || raw == 'TOP') return 'TOP';
        if (raw == 'B' || raw == 'BOTTOM') return 'BOTTOM';
        if (raw == 'D' || raw == 'DOUBLE') return 'DOUBLE';
        if (raw.isEmpty) return 'DOUBLE';
        return raw;
      },
    );

    final lineTracking = _buildLineTracking(filtered);
    final usingTimeSlices = _buildStandardBuckets(filtered);
    final checkSlices = _buildCheckTimeBuckets(filtered);

    final activeLines = filtered
        .where((item) => item.isActive)
        .toList()
      ..sort((a, b) =>
          (a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0)));

    final insights = _buildInsightMetrics(activeLines);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOverviewGrid(
          customerSlices: customerSlices,
          statusSlices: statusSlices,
          vendorSlices: vendorSlices,
          processSlices: processSlices,
        ),
        if (insights.isNotEmpty) ...[
          const SizedBox(height: 20),
          _InsightsStrip(items: insights),
        ],
        const SizedBox(height: 20),
        _buildLineTrackingCard(lineTracking),
        const SizedBox(height: 20),
        _buildUsageRow(usingTimeSlices, checkSlices),
        const SizedBox(height: 20),
        _buildRunningLine(context, activeLines),
      ],
    );
  }

  List<_InsightMetric> _buildInsightMetrics(List<StencilDetail> activeLines) {
    if (activeLines.isEmpty) return const [];

    final total = activeLines.length;
    int good = 0;
    int warning = 0;
    int danger = 0;

    final now = DateTime.now();
    for (final item in activeLines) {
      final start = item.startTime;
      if (start == null) continue;
      final diff = now.difference(start).inMinutes / 60;
      if (diff <= 3.5) {
        good++;
      } else if (diff <= 4) {
        warning++;
      } else {
        danger++;
      }
    }

    final checkNow = DateTime.now();
    final recentCutoff = checkNow.subtract(const Duration(days: 180));
    final onCheck = activeLines
        .where((e) => (e.checkTime ?? checkNow).isAfter(recentCutoff))
        .length;

    return [
      _InsightMetric(
        label: 'ACTIVE LINES',
        value: total.toString(),
        accent: Colors.cyanAccent,
        description: 'Monitoring right now',
      ),
      _InsightMetric(
        label: 'STABLE',
        value: good.toString(),
        accent: const Color(0xFF2CF6B3),
        description: '< 3.5 hours runtime',
      ),
      _InsightMetric(
        label: 'WATCH',
        value: warning.toString(),
        accent: Colors.amberAccent,
        description: '3.5 – 4 hours runtime',
      ),
      _InsightMetric(
        label: 'ALERT',
        value: danger.toString(),
        accent: Colors.redAccent,
        description: '> 4 hours runtime',
      ),
      _InsightMetric(
        label: 'RECENT CHECK',
        value: onCheck.toString(),
        accent: const Color(0xFF8F5BFF),
        description: 'Checked in last 6 months',
      ),
    ];
  }

  Widget _buildOverviewGrid({
    required List<_PieSlice> customerSlices,
    required List<_PieSlice> statusSlices,
    required List<_PieSlice> vendorSlices,
    required List<_PieSlice> processSlices,
  }) {
    final cards = [
      _OverviewCardData(
        title: 'CUSTOMER',
        slices: customerSlices,
        accent: const Color(0xFF4DE1FF),
      ),
      _OverviewCardData(
        title: 'STATUS',
        slices: statusSlices,
        accent: const Color(0xFFFFC740),
      ),
      _OverviewCardData(
        title: 'VENDOR',
        slices: vendorSlices,
        accent: const Color(0xFF8F5BFF),
      ),
      _OverviewCardData(
        title: 'STENCIL SIDE',
        slices: processSlices,
        accent: const Color(0xFF2CF6B3),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.86,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: cards
          .map(
            (card) => _buildOverviewCard(card),
          )
          .toList(),
    );
  }

  Widget _buildOverviewCard(_OverviewCardData data) {
    final palette = _palette;
    final total = data.slices.fold<int>(0, (sum, slice) => sum + slice.value);
    final displaySlices = data.slices.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: data.accent.withOpacity(0.5), width: 1.2),
        color: palette.cardBackground,
        gradient: LinearGradient(
          colors: [
            data.accent.withOpacity(0.12),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: GoogleFonts.orbitron(
              color: data.accent,
              fontSize: 15,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 148,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SfCircularChart(
                  margin: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  series: <CircularSeries<_PieSlice, String>>[
                    DoughnutSeries<_PieSlice, String>(
                      dataSource: displaySlices,
                      xValueMapper: (datum, _) => datum.label,
                      yValueMapper: (datum, _) => datum.value,
                      pointColorMapper: (datum, index) =>
                          _neonPalette[index % _neonPalette.length],
                      innerRadius: '58%',
                      radius: '118%',
                      explode: displaySlices.length == 1,
                      dataLabelSettings: DataLabelSettings(
                        isVisible: displaySlices.length <= 4,
                        textStyle: GoogleFonts.robotoMono(
                          color: palette.onSurface,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: GoogleFonts.orbitron(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: palette.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: displaySlices
                .map(
                  (slice) => _buildLegendPill(
                    slice.label,
                    slice.value,
                    data.accent,
                    textColor: palette.onSurface,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill(
    String label,
    int value,
    Color accent, {
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.5)),
        color: accent.withOpacity(0.12),
      ),
      child: Text(
        '$label • $value',
        style: GoogleFonts.robotoMono(
          fontSize: 11,
          color: textColor.withOpacity(0.85),
        ),
      ),
    );
  }

  Widget _buildLineTrackingCard(List<_LineTrackingDatum> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.45)),
        gradient: LinearGradient(
          colors: [
            Colors.purpleAccent.withOpacity(0.12),
            Colors.transparent,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LINE TRACKING',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _palette.brightness == Brightness.dark
                  ? Colors.purpleAccent
                  : const Color(0xFF5C3AFF),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildColorLegend(' < 3.5h', Colors.cyanAccent),
              const SizedBox(width: 12),
              _buildColorLegend('3.5 – 4h', Colors.amberAccent),
              const SizedBox(width: 12),
              _buildColorLegend('> 4h', Colors.redAccent),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              primaryXAxis: CategoryAxis(
                axisLine: AxisLine(color: _axisLineColor),
                majorGridLines: const MajorGridLines(color: Colors.transparent),
                labelStyle: GoogleFonts.robotoMono(
                  color: _textSecondary,
                  fontSize: 10,
                ),
              ),
              primaryYAxis: NumericAxis(
                axisLine: AxisLine(color: _axisLineColor),
                majorGridLines: MajorGridLines(
                  width: 0.4,
                  color: _gridLineColor,
                ),
                labelStyle: GoogleFonts.robotoMono(
                  color: _textSecondary,
                  fontSize: 10,
                ),
                minimum: 0,
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: _tooltipBackground,
                textStyle: GoogleFonts.robotoMono(
                  color: _tooltipTextColor,
                  fontSize: 11,
                ),
                header: '',
              ),
              series: <CartesianSeries<dynamic, dynamic>>[
                ColumnSeries<_LineTrackingDatum, String>(
                  dataSource: data,
                  xValueMapper: (datum, _) => datum.category,
                  yValueMapper: (datum, _) => datum.hours,
                  pointColorMapper: (datum, _) => _lineHoursColor(datum.hours),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: data.length <= 6,
                    textStyle: GoogleFonts.robotoMono(
                      color: _textPrimary,
                      fontSize: 9,
                    ),
                  ),
                  enableTooltip: true,
                  name: 'Hours',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.robotoMono(
            color: _textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageRow(
    List<_PieSlice> usingTime,
    List<_PieSlice> checkTime,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniDonutCard(
            title: 'USING TIME',
            accent: const Color(0xFF4DE1FF),
            slices: usingTime,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMiniDonutCard(
            title: 'CHECKING TIME',
            accent: const Color(0xFFFF6FB7),
            slices: checkTime,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniDonutCard({
    required String title,
    required Color accent,
    required List<_PieSlice> slices,
  }) {
    final palette = _palette;
    final total = slices.fold<int>(0, (sum, item) => sum + item.value);
    final display = slices.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.5), width: 1.1),
        color: palette.cardBackground,
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.12), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: accent,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SfCircularChart(
                  margin: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  series: <CircularSeries<_PieSlice, String>>[
                    DoughnutSeries<_PieSlice, String>(
                      dataSource: display,
                      xValueMapper: (datum, _) => datum.label,
                      yValueMapper: (datum, _) => datum.value,
                      pointColorMapper: (datum, index) =>
                          _neonPalette[index % _neonPalette.length],
                      innerRadius: '55%',
                      radius: '122%',
                      dataLabelSettings: DataLabelSettings(
                        isVisible: display.length <= 3,
                        textStyle: GoogleFonts.robotoMono(
                          color: palette.onSurface,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: GoogleFonts.orbitron(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: palette.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total',
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: display
                .map(
                  (slice) => _buildLegendPill(
                    slice.label,
                    slice.value,
                    accent,
                    textColor: palette.onSurface,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRunningLine(BuildContext context, List<StencilDetail> activeLines) {
    if (activeLines.isEmpty) {
      return _GlassCard(
        accent: Colors.cyanAccent,
        title: 'RUNNING LINE',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              'No active stencil on line',
              style: GoogleFonts.robotoMono(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final limited = activeLines.take(8).toList();

    return _GlassCard(
      accent: Colors.cyanAccent,
      title: 'RUNNING LINE',
      action: TextButton.icon(
        onPressed: () => _showRunningLineDetail(context, activeLines),
        icon: const Icon(Icons.list_alt_rounded, color: Colors.cyanAccent, size: 18),
        label: Text('View all',
            style: GoogleFonts.robotoMono(color: Colors.cyanAccent, fontSize: 12)),
      ),
      child: Column(
        children: [
          ...limited.map((item) {
            final diffHours = item.startTime == null
                ? 0.0
                : now.difference(item.startTime!).inMinutes / 60.0;
            final color = diffHours <= 3.5
                ? Colors.cyanAccent
                : diffHours <= 4
                    ? Colors.amberAccent
                    : Colors.redAccent;

            return _RunningLineTile(
              detail: item,
              hourDiff: diffHours,
              accent: color,
              onTap: () => _showSingleDetail(context, item, diffHours),
            );
          }),
          if (activeLines.length > limited.length) ...[
            const SizedBox(height: 12),
            Text(
              '+${activeLines.length - limited.length} more lines running',
              style: GoogleFonts.robotoMono(
                color: _textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _axisLineColor),
        color: _palette.surfaceOverlay,
      ),
      child: Column(
        children: [
          Icon(Icons.sensors_off, size: 48, color: _textSecondary.withOpacity(0.7)),
          const SizedBox(height: 12),
          Text(
            'No stencil records match the selected filters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoMono(
              color: _textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 52, color: _palette.errorText.withOpacity(0.9)),
            const SizedBox(height: 12),
            Text(
              'Unable to load stencil monitor data.',
              style: GoogleFonts.orbitron(
                color: _textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono(
                color: _textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => controller.fetchData(force: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  List<_PieSlice> _groupToPie(
    List<StencilDetail> source,
    String Function(StencilDetail item) selector, {
    String Function(String value)? labelTransformer,
  }) {
    final map = <String, int>{};
    for (final item in source) {
      var key = selector(item).trim();
      if (labelTransformer != null) {
        key = labelTransformer(key);
      }
      final normalized = key.isEmpty ? 'UNK' : key.trim();
      map[normalized] = (map[normalized] ?? 0) + 1;
    }

    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.length <= 8) {
      return entries.map((e) => _PieSlice(e.key, e.value)).toList();
    }

    final top = entries.take(7).map((e) => _PieSlice(e.key, e.value)).toList();
    final otherTotal = entries.skip(7).fold<int>(0, (sum, e) => sum + e.value);
    top.add(_PieSlice('Other', otherTotal));
    return top;
  }

  String _mapCustomerLabel(String value) {
    final upper = value.trim().toUpperCase();
    if (upper == 'CPEI') {
      return 'CPEII';
    }
    return value.trim().isEmpty ? 'UNK' : value.trim();
  }

  List<_LineTrackingDatum> _buildLineTracking(List<StencilDetail> data) {
    final now = DateTime.now();
    final list = <_LineTrackingDatum>[];

    for (final item in data) {
      final start = item.startTime;
      if (start == null) continue;
      final diff = now.difference(start).inMinutes / 60.0;
      final category = item.lineName?.isNotEmpty == true
          ? item.lineName!
          : item.location?.isNotEmpty == true
              ? item.location!
              : item.stencilSn;
      list.add(
        _LineTrackingDatum(
          category: category,
          hours: diff < 0 ? 0.0 : diff,
          stencilSn: item.stencilSn,
          startTime: start,
          location: item.location ?? '-',
          totalUse: item.totalUseTimes,
        ),
      );
    }

    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  List<_PieSlice> _buildStandardBuckets(List<StencilDetail> data) {
    final buckets = <String, int>{
      '0 – 1K': 0,
      '1K – 3K': 0,
      '3K – 5K': 0,
      '5K – 8K': 0,
      '8K – 10K': 0,
      '> 10K': 0,
      'Unknown': 0,
    };

    for (final item in data) {
      final value = item.standardTimes;
      if (value == null) {
        buckets['Unknown'] = buckets['Unknown']! + 1;
        continue;
      }
      if (value <= 1000) {
        buckets['0 – 1K'] = buckets['0 – 1K']! + 1;
      } else if (value <= 3000) {
        buckets['1K – 3K'] = buckets['1K – 3K']! + 1;
      } else if (value <= 5000) {
        buckets['3K – 5K'] = buckets['3K – 5K']! + 1;
      } else if (value <= 8000) {
        buckets['5K – 8K'] = buckets['5K – 8K']! + 1;
      } else if (value <= 10000) {
        buckets['8K – 10K'] = buckets['8K – 10K']! + 1;
      } else {
        buckets['> 10K'] = buckets['> 10K']! + 1;
      }
    }

    return buckets.entries
        .where((entry) => entry.value > 0)
        .map((entry) => _PieSlice(entry.key, entry.value))
        .toList();
  }

  List<_PieSlice> _buildCheckTimeBuckets(List<StencilDetail> data) {
    final map = <String, int>{
      '0 – 6 Months': 0,
      '6 Months – 1 Year': 0,
      '1 – 2 Years': 0,
      'Over 2 Years': 0,
      'Unknown': 0,
    };

    final now = DateTime.now();
    for (final item in data) {
      final check = item.checkTime;
      if (check == null) {
        map['Unknown'] = map['Unknown']! + 1;
        continue;
      }

      final months = now.difference(check).inDays / 30.0;
      if (months <= 6) {
        map['0 – 6 Months'] = map['0 – 6 Months']! + 1;
      } else if (months <= 12) {
        map['6 Months – 1 Year'] = map['6 Months – 1 Year']! + 1;
      } else if (months <= 24) {
        map['1 – 2 Years'] = map['1 – 2 Years']! + 1;
      } else {
        map['Over 2 Years'] = map['Over 2 Years']! + 1;
      }
    }

    final order = {
      '0 – 6 Months': 0,
      '6 Months – 1 Year': 1,
      '1 – 2 Years': 2,
      'Over 2 Years': 3,
      'Unknown': 4,
    };

    final list = map.entries
        .where((entry) => entry.value > 0)
        .map((entry) => _PieSlice(entry.key, entry.value))
        .toList()
      ..sort((a, b) => (order[a.label] ?? 99).compareTo(order[b.label] ?? 99));

    return list;
  }

  Color _lineHoursColor(double hours) {
    if (hours >= 4) {
      return Colors.redAccent.shade200;
    }
    if (hours >= 3.5) {
      return Colors.amberAccent.shade200;
    }
    return Colors.cyanAccent.shade200;
  }
}

class _PieSlice {
  _PieSlice(this.label, this.value);

  final String label;
  final int value;
}

class _LineTrackingDatum {
  _LineTrackingDatum({
    required this.category,
    required this.hours,
    required this.stencilSn,
    required this.startTime,
    required this.location,
    required this.totalUse,
  });

  final String category;
  final double hours;
  final String stencilSn;
  final DateTime startTime;
  final String location;
  final int? totalUse;
}

class _OverviewCardData {
  const _OverviewCardData({
    required this.title,
    required this.slices,
    required this.accent,
  });

  final String title;
  final List<_PieSlice> slices;
  final Color accent;
}

