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
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

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

    final total = filtered.length;
    final active = filtered.where((item) => item.isActive).length;
    final statusMap = controller.statusBreakdown(filtered);
    final vendorMap = controller.vendorBreakdown(filtered);

    final customerSlices = _groupToPie(
      filtered,
      (item) => item.customerLabel,
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
      (item) => (item.process == null || item.process!.trim().isEmpty)
          ? 'Process UNK'
          : 'Process ${item.process!.trim()}',
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
        _buildOverviewRow(
          context,
          isDark: isDark,
          total: total,
          active: active,
          status: statusSlices,
          vendors: vendorSlices,
          maxWidth: maxWidth,
        ),
        const SizedBox(height: 20),
        _buildTopCharts(
          isDark: isDark,
          maxWidth: maxWidth,
          customers: customerSlices,
          status: statusSlices,
          vendors: vendorSlices,
          process: processSlices,
        ),
        const SizedBox(height: 20),
        _buildMiddleSection(
          isDark: isDark,
          maxWidth: maxWidth,
          lineTracking: lineTracking,
          activeLines: activeLines,
        ),
        const SizedBox(height: 20),
        _buildBottomCharts(
          isDark: isDark,
          maxWidth: maxWidth,
          standardBuckets: standardBuckets,
          checkBuckets: checkBuckets,
        ),
        const SizedBox(height: 24),
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
              children: [
                _buildDropdown(
                  label: 'Customer',
                  value: customerValue,
                  items: customers,
                  onChanged: controller.selectCustomer,
                  isDark: isDark,
                ),
                _buildDropdown(
                  label: 'Floor',
                  value: floorValue,
                  items: floors,
                  onChanged: controller.selectFloor,
                  isDark: isDark,
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

  Widget _buildOverviewRow(
    BuildContext context, {
    required bool isDark,
    required int total,
    required int active,
    required List<_PieSlice> status,
    required List<_PieSlice> vendors,
    required double maxWidth,
  }) {
    final statusTop = status.isNotEmpty ? status.first : null;
    final vendorTop = vendors.isNotEmpty ? vendors.first : null;
    final tileWidth = _responsiveTileWidth(maxWidth, preferCount: 4, minWidth: 220);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: tileWidth,
          child: _metricCard(
            title: 'Total Stencils',
            value: total.toString(),
            icon: Icons.inventory_2_outlined,
            color: Colors.cyanAccent,
            isDark: isDark,
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _metricCard(
            title: 'Active Lines',
            value: active.toString(),
            icon: Icons.precision_manufacturing_outlined,
            color: Colors.greenAccent,
            isDark: isDark,
          ),
        ),
        if (statusTop != null)
          SizedBox(
            width: tileWidth,
            child: _metricCard(
              title: 'Top Status',
              value: '${statusTop.label} (${statusTop.value})',
              icon: Icons.stacked_bar_chart,
              color: Colors.orangeAccent,
              isDark: isDark,
            ),
          ),
        if (vendorTop != null)
          SizedBox(
            width: tileWidth,
            child: _metricCard(
              title: 'Top Vendor',
              value: '${vendorTop.label} (${vendorTop.value})',
              icon: Icons.local_shipping_outlined,
              color: Colors.purpleAccent,
              isDark: isDark,
            ),
          ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final bgColor = isDark ? color.withOpacity(0.2) : color.withOpacity(0.12);
    final textColor = isDark ? Colors.white : Colors.blueGrey[900];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.blueGrey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCharts({
    required bool isDark,
    required double maxWidth,
    required List<_PieSlice> customers,
    required List<_PieSlice> status,
    required List<_PieSlice> vendors,
    required List<_PieSlice> process,
  }) {
    final width = _responsiveTileWidth(maxWidth, preferCount: 4, minWidth: 240);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: width,
          child: _pieChartCard(
            title: 'Customer',
            data: customers,
            isDark: isDark,
          ),
        ),
        SizedBox(
          width: width,
          child: _pieChartCard(
            title: 'Status',
            data: status,
            isDark: isDark,
          ),
        ),
        SizedBox(
          width: width,
          child: _pieChartCard(
            title: 'Vendor',
            data: vendors,
            isDark: isDark,
          ),
        ),
        SizedBox(
          width: width,
          child: _pieChartCard(
            title: 'Process',
            data: process,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMiddleSection({
    required bool isDark,
    required double maxWidth,
    required List<_LineTrackingDatum> lineTracking,
    required List<StencilDetail> activeLines,
  }) {
    const spacing = 16.0;
    double primaryWidth;
    double secondaryWidth;

    if (maxWidth >= 1350) {
      secondaryWidth = 360;
      primaryWidth = maxWidth - secondaryWidth - spacing;
    } else if (maxWidth >= 1100) {
      secondaryWidth = 320;
      primaryWidth = maxWidth - secondaryWidth - spacing;
    } else if (maxWidth >= 900) {
      primaryWidth = (maxWidth - spacing) / 2;
      secondaryWidth = primaryWidth;
    } else {
      primaryWidth = maxWidth;
      secondaryWidth = maxWidth;
    }

    if (primaryWidth < 280) primaryWidth = maxWidth;
    if (secondaryWidth < 280 && maxWidth > 320) secondaryWidth = 320;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        SizedBox(
          width: primaryWidth,
          child: _chartCard(
            isDark: isDark,
            title: 'Line Tracking',
            height: 320,
            child: _buildLineTrackingChart(lineTracking, isDark),
          ),
        ),
        SizedBox(
          width: secondaryWidth,
          child: _chartCard(
            isDark: isDark,
            title: 'Currently Lines',
            height: 320,
            child: _buildActiveLinesPanel(activeLines, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCharts({
    required bool isDark,
    required double maxWidth,
    required List<_BarDatum> standardBuckets,
    required List<_PieSlice> checkBuckets,
  }) {
    final width = _responsiveTileWidth(maxWidth, preferCount: 2, minWidth: 320);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: width,
          child: _chartCard(
            isDark: isDark,
            title: 'Standard Use Time',
            height: 280,
            child: _buildStandardChart(standardBuckets, isDark),
          ),
        ),
        SizedBox(
          width: width,
          child: _pieChartCard(
            title: 'Check Time',
            data: checkBuckets,
            isDark: isDark,
            height: 280,
          ),
        ),
      ],
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
        final index = args.pointIndex;
        if (index == null || index < 0 || index >= data.length) {
          return;
        }
        final item = data[index];
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
        final hours = item.runningHours ?? 0;
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
                    '${hours.toStringAsFixed(1)} h',
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
              _standardBarColor(index?.toInt() ?? 0),
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

  double _responsiveTileWidth(
    double maxWidth, {
    int preferCount = 4,
    double minWidth = 220,
  }) {
    const spacing = 16.0;
    if (maxWidth <= 0) return 0;
    if (maxWidth < minWidth) return maxWidth;

    double width;
    if (maxWidth >= 1400) {
      width = (maxWidth - spacing * (preferCount - 1)) / preferCount;
    } else if (maxWidth >= 1000) {
      width = (maxWidth - spacing) / 2;
    } else {
      width = maxWidth;
    }

    if (width < minWidth && maxWidth >= minWidth) {
      width = minWidth;
    }
    if (width > maxWidth) {
      width = maxWidth;
    }
    return width;
  }

  List<_PieSlice> _groupToPie(
    List<StencilDetail> source,
    String Function(StencilDetail item) selector,
  ) {
    final map = <String, int>{};
    for (final item in source) {
      final key = selector(item).trim();
      final normalized = key.isEmpty ? 'UNK' : key;
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
          hours: diff < 0 ? 0 : diff,
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
      '6 – 12 Months': 0,
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
        map['6 – 12 Months'] = map['6 – 12 Months']! + 1;
      } else if (months <= 24) {
        map['1 – 2 Years'] = map['1 – 2 Years']! + 1;
      } else {
        map['Over 2 Years'] = map['Over 2 Years']! + 1;
      }
    }

    final order = {
      '0 – 6 Months': 0,
      '6 – 12 Months': 1,
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
