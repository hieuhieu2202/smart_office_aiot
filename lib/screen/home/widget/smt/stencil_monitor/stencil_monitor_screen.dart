import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:smart_factory/screen/home/controller/stencil_monitor_controller.dart';

import '../../../../../config/global_color.dart';
import '../../../../../model/smt/stencil_detail.dart';
import '../../../../../widget/animation/loading/eva_loading_view.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final loading = controller.isLoading.value;
      final hasData = controller.stencilData.isNotEmpty;
      final filtered = controller.filteredData;
      final error = controller.error.value;

      return Scaffold(
        backgroundColor:
            isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
        appBar: AppBar(
          title: Text(widget.title ?? 'Stencil Monitor'),
          centerTitle: true,
          backgroundColor:
              isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
          iconTheme: IconThemeData(
            color: isDark
                ? GlobalColors.appBarDarkText
                : GlobalColors.appBarLightText,
          ),
          actions: [
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.fetchData(force: true),
            ),
          ],
        ),
        body: _buildBody(
          context,
          isDark: isDark,
          loading: loading,
          hasData: hasData,
          error: error,
          filtered: filtered,
        ),
      );
    });
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isDark,
    required bool loading,
    required bool hasData,
    required String error,
    required List<StencilDetail> filtered,
  }) {
    if (loading && !hasData) {
      return const Center(child: EvaLoadingView(size: 120));
    }

    if (error.isNotEmpty && !hasData) {
      return _buildFullError(isDark, error);
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchData(force: true),
      color: Theme.of(context).colorScheme.secondary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: _buildDashboard(
              context,
              isDark: isDark,
              error: error,
              filtered: filtered,
              maxWidth: constraints.maxWidth,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context, {
    required bool isDark,
    required String error,
    required List<StencilDetail> filtered,
    required double maxWidth,
  }) {
    if (filtered.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterCard(isDark),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildErrorBanner(isDark, error),
          ],
          const SizedBox(height: 16),
          _buildEmptyState(isDark),
        ],
      );
    }

    final statusMap = controller.statusBreakdown(filtered);
    final vendorMap = controller.vendorBreakdown(filtered);

    final customerSlices = _groupToPie(
      filtered,
      (item) => item.customerLabel,
      labelTransformer: _mapCustomerLabel,
    );
    final statusSlices = statusMap.entries
        .map((entry) => _PieSlice(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final vendorSlices = vendorMap.entries
        .map((entry) => _PieSlice(entry.key, entry.value))
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
    final standardBuckets = _buildStandardBuckets(filtered);
    final checkBuckets = _buildCheckTimeBuckets(filtered);
    final activeLines = filtered
        .where((item) => item.isActive)
        .toList()
      ..sort((a, b) =>
          (a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterCard(isDark),
        if (error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(isDark, error),
        ],
        const SizedBox(height: 16),
        _buildMainLayout(
          isDark: isDark,
          maxWidth: maxWidth,
          customers: customerSlices,
          status: statusSlices,
          vendors: vendorSlices,
          process: processSlices,
          lineTracking: lineTracking,
          standardBuckets: standardBuckets,
          checkBuckets: checkBuckets,
          activeLines: activeLines,
        ),
      ],
    );
  }

  Widget _buildFilterCard(bool isDark) {
    final customers = controller.customers.toList(growable: false);
    final floors = controller.floors.toList(growable: false);
    final customerValue = controller.selectedCustomer.value;
    final floorValue = controller.selectedFloor.value;

    return Card(
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.lightBlue[100]
                        : GlobalColors.appBarLightText,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildDropdown(
                  label: 'Customer',
                  value: customerValue,
                  items: customers,
                  onChanged: controller.selectCustomer,
                  isDark: isDark,
                ),
                _buildDropdown(
                  label: 'Factory',
                  value: floorValue,
                  items: floors,
                  onChanged: controller.selectFloor,
                  isDark: isDark,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Query'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () => controller.fetchData(force: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.blueGrey[200] : Colors.blueGrey[700],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.contains(value) ? value : null,
            isExpanded: true,
            icon: Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.white70 : Colors.blueGrey[700],
            ),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainLayout({
    required bool isDark,
    required double maxWidth,
    required List<_PieSlice> customers,
    required List<_PieSlice> status,
    required List<_PieSlice> vendors,
    required List<_PieSlice> process,
    required List<_LineTrackingDatum> lineTracking,
    required List<_BarDatum> standardBuckets,
    required List<_PieSlice> checkBuckets,
    required List<StencilDetail> activeLines,
  }) {
    const gap = 16.0;

    Widget buildLeft({required bool compact}) => _buildLeftColumn(
          isDark: isDark,
          customers: customers,
          status: status,
          vendors: vendors,
          process: process,
          compact: compact,
        );

    Widget buildCenter({required bool compact}) => _buildCenterColumn(
          isDark: isDark,
          lineTracking: lineTracking,
          standardBuckets: standardBuckets,
          checkBuckets: checkBuckets,
          compact: compact,
        );

    Widget buildRight() => _buildRightColumn(
          isDark: isDark,
          activeLines: activeLines,
        );

    if (maxWidth >= 1200) {
      final leftWidth = (maxWidth * 0.22).clamp(260.0, 340.0);
      final rightWidth = (maxWidth * 0.24).clamp(260.0, 360.0);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: leftWidth, child: buildLeft(compact: false)),
          const SizedBox(width: gap),
          Expanded(child: buildCenter(compact: false)),
          const SizedBox(width: gap),
          SizedBox(width: rightWidth, child: buildRight()),
        ],
      );
    }

    if (maxWidth >= 900) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: buildLeft(compact: true)),
              const SizedBox(width: gap),
              Expanded(flex: 2, child: buildCenter(compact: false)),
            ],
          ),
          const SizedBox(height: gap),
          buildRight(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildLeft(compact: true),
        const SizedBox(height: gap),
        buildCenter(compact: true),
        const SizedBox(height: gap),
        buildRight(),
      ],
    );
  }

  Widget _buildLeftColumn({
    required bool isDark,
    required List<_PieSlice> customers,
    required List<_PieSlice> status,
    required List<_PieSlice> vendors,
    required List<_PieSlice> process,
    required bool compact,
  }) {
    final height = compact ? 200.0 : 220.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pieChartCard(
          title: 'Customer',
          data: customers,
          isDark: isDark,
          height: height,
        ),
        const SizedBox(height: 16),
        _pieChartCard(
          title: 'Status',
          data: status,
          isDark: isDark,
          height: height,
        ),
        const SizedBox(height: 16),
        _pieChartCard(
          title: 'Vendor',
          data: vendors,
          isDark: isDark,
          height: height,
        ),
        const SizedBox(height: 16),
        _pieChartCard(
          title: 'Stencil Side',
          data: process,
          isDark: isDark,
          height: height,
        ),
      ],
    );
  }

  Widget _buildCenterColumn({
    required bool isDark,
    required List<_LineTrackingDatum> lineTracking,
    required List<_BarDatum> standardBuckets,
    required List<_PieSlice> checkBuckets,
    required bool compact,
  }) {
    final lineHeight = compact ? 300.0 : 360.0;
    final detailHeight = compact ? 220.0 : 240.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chartCard(
          isDark: isDark,
          title: 'Line Tracking',
          height: lineHeight,
          child: _buildLineTrackingChart(lineTracking, isDark),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 650 && !compact;
            if (horizontal) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _chartCard(
                      isDark: isDark,
                      title: 'Using Time',
                      height: detailHeight,
                      child: _buildStandardChart(standardBuckets, isDark),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _chartCard(
                      isDark: isDark,
                      title: 'Checking Time',
                      height: detailHeight,
                      child: _buildCheckTimeChart(checkBuckets, isDark),
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _chartCard(
                  isDark: isDark,
                  title: 'Using Time',
                  height: detailHeight,
                  child: _buildStandardChart(standardBuckets, isDark),
                ),
                const SizedBox(height: 16),
                _chartCard(
                  isDark: isDark,
                  title: 'Checking Time',
                  height: detailHeight,
                  child: _buildCheckTimeChart(checkBuckets, isDark),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRightColumn({
    required bool isDark,
    required List<StencilDetail> activeLines,
  }) {
    return Card(
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Running Line',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.lightBlue[100]
                          : GlobalColors.appBarLightText,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            _buildActiveLinesPanel(activeLines, isDark),
          ],
        ),
      ),
    );
  }

  Widget _chartCard({
    required bool isDark,
    required String title,
    required Widget child,
    double height = 260,
  }) {
    return Card(
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.lightBlue[100]
                        : GlobalColors.appBarLightText,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: height,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pieChartCard({
    required String title,
    required List<_PieSlice> data,
    required bool isDark,
    double height = 260,
  }) {
    return _chartCard(
      isDark: isDark,
      title: title,
      height: height,
      child: data.isEmpty
          ? _buildEmptyChart('No data available.', isDark)
          : SfCircularChart(
              margin: EdgeInsets.zero,
              legend: Legend(
                isVisible: true,
                overflowMode: LegendItemOverflowMode.wrap,
                textStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.blueGrey[700],
                  fontSize: 11,
                ),
              ),
              tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x: point.y'),
              series: <CircularSeries<_PieSlice, String>>[
                DoughnutSeries<_PieSlice, String>(
                  dataSource: data,
                  xValueMapper: (slice, _) => slice.label,
                  yValueMapper: (slice, _) => slice.value,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      color: isDark ? Colors.white : Colors.blueGrey[900],
                      fontSize: 10,
                    ),
                  ),
                  radius: '70%',
                  innerRadius: '45%',
                ),
              ],
            ),
    );
  }

  Widget _buildLineTrackingChart(
    List<_LineTrackingDatum> data,
    bool isDark,
  ) {
    if (data.isEmpty) {
      return _buildEmptyChart('No active line tracking data.', isDark);
    }

    final rotation = data.length > 8
        ? 60
        : data.length > 5
            ? 40
            : 0;

    return SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      tooltipBehavior: TooltipBehavior(enable: true, header: ''),
      primaryXAxis: CategoryAxis(
        labelRotation: rotation,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.blueGrey[700],
          fontSize: 11,
        ),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        labelFormat: '{value}h',
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.blueGrey[700],
        ),
        majorTickLines: const MajorTickLines(size: 0),
        axisLine: const AxisLine(width: 0),
      ),
      series: <CartesianSeries<dynamic, dynamic>>[
        ColumnSeries<_LineTrackingDatum, String>(
          dataSource: data,
          width: 0.6,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          xValueMapper: (item, _) => item.category,
          yValueMapper: (item, _) => item.hours,
          pointColorMapper: (item, _) => _lineHoursColor(item.hours),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 10,
            ),
          ),
          enableTooltip: true,
        ),
      ],
      onTooltipRender: (TooltipArgs args) {
        final idx = args.pointIndex?.toInt();
        if (idx == null || idx < 0 || idx >= data.length) {
          return;
        }
        final item = data[idx];
        final start = _dateFormat.format(item.startTime.toLocal());
        final use = item.totalUse?.toString() ?? '-';
        args.text =
            'Line: ${item.category}\nHours: ${item.hours.toStringAsFixed(2)}\nStencil: ${item.stencilSn}\nStart: $start\nUse: $use';
      },
    );
  }

  Widget _buildActiveLinesPanel(List<StencilDetail> active, bool isDark) {
    if (active.isEmpty) {
      return _buildEmptyChart('No stencils are currently on a line.', isDark);
    }

    return ListView.separated(
      itemCount: active.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = active[index];
        final hours = item.runningHours ?? 0.0;
        final color = _lineHoursColor(hours);
        final lineLabel = item.lineName?.isNotEmpty == true
            ? item.lineName!
            : item.location?.isNotEmpty == true
                ? item.location!
                : 'Unknown line';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.7), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lineLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.blueGrey[900],
                      ),
                    ),
                  ),
                  Text(
                    '${hours.toStringAsFixed(2)} h',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _infoChip('Stencil',
                      item.stencilSn.isEmpty ? '-' : item.stencilSn, isDark),
                  _infoChip('Location', item.location ?? '-', isDark),
                  _infoChip(
                    'Start',
                    _dateFormat.format(item.startTime!.toLocal()),
                    isDark,
                  ),
                  if (item.totalUseTimes != null)
                    _infoChip('Use', item.totalUseTimes.toString(), isDark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckTimeChart(List<_PieSlice> data, bool isDark) {
    if (data.isEmpty) {
      return _buildEmptyChart('No checking time data.', isDark);
    }

    return SfCircularChart(
      margin: EdgeInsets.zero,
      legend: Legend(
        isVisible: true,
        position: LegendPosition.right,
        overflowMode: LegendItemOverflowMode.wrap,
        textStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.blueGrey[700],
          fontSize: 11,
        ),
      ),
      tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x: point.y'),
      series: <CircularSeries<_PieSlice, String>>[
        DoughnutSeries<_PieSlice, String>(
          dataSource: data,
          xValueMapper: (slice, _) => slice.label,
          yValueMapper: (slice, _) => slice.value,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(
              color: isDark ? Colors.white : Colors.blueGrey[900],
              fontSize: 10,
            ),
          ),
          innerRadius: '45%',
          radius: '70%',
        ),
      ],
    );
  }

  Widget _buildStandardChart(List<_BarDatum> data, bool isDark) {
    if (data.isEmpty) {
      return _buildEmptyChart('No standard time data.', isDark);
    }

    return SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      tooltipBehavior: TooltipBehavior(enable: true, header: ''),
      primaryXAxis: CategoryAxis(
        labelRotation: 20,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.blueGrey[700],
        ),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.blueGrey[700],
        ),
        majorTickLines: const MajorTickLines(size: 0),
        axisLine: const AxisLine(width: 0),
      ),
      series: <CartesianSeries<dynamic, dynamic>>[
        ColumnSeries<_BarDatum, String>(
          dataSource: data,
          xValueMapper: (item, _) => item.label,
          yValueMapper: (item, _) => item.value,
          pointColorMapper: (item, index) =>
              _standardBarColor(index ?? 0),
          width: 0.55,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Color _standardBarColor(int index) {
    final opacity = 0.85 - index * 0.05;
    final safe = opacity.clamp(0.35, 0.85);
    return Colors.lightBlueAccent.withOpacity(safe.toDouble());
  }

  Widget _buildEmptyChart(String message, bool isDark) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.blueGrey[500],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white70 : Colors.blueGrey[700],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.red[200] : Colors.red[800],
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

  Widget _buildFullError(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: isDark ? Colors.red[200] : Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Unable to load stencil monitor data.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.blueGrey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.blueGrey[600],
              ),
            ),
            const SizedBox(height: 16),
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

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.blueGrey[700]! : Colors.blueGrey[100]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            size: 48,
            color: isDark ? Colors.white30 : Colors.blueGrey[300],
          ),
          const SizedBox(height: 12),
          const Text(
            'No stencil records match the selected filters.',
            textAlign: TextAlign.center,
          ),
        ],
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

  List<_BarDatum> _buildStandardBuckets(List<StencilDetail> data) {
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
        .map((entry) => _BarDatum(entry.key, entry.value))
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
      return Colors.orangeAccent.shade200;
    }
    return Colors.cyanAccent.shade200;
  }
}

class _PieSlice {
  _PieSlice(this.label, this.value);

  final String label;
  final int value;
}

class _BarDatum {
  _BarDatum(this.label, this.value);

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
