import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../domain/entities/kanban_entities.dart';
import '../viewmodels/output_tracking_view_state.dart';
import '../viewmodels/series_utils.dart';

class OtStationTrendDialog extends StatelessWidget {
  const OtStationTrendDialog({
    super.key,
    required this.station,
    required this.hours,
    required this.metrics,
  });

  final String station;
  final List<String> hours;
  final List<OtCellMetrics> metrics;

  @override
  Widget build(BuildContext context) {
    final data = _buildPoints();
    final screenWidth = MediaQuery.of(context).size.width;
    final double dialogMaxWidth =
        (screenWidth * 0.8).clamp(360.0, 1280.0).toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: const Color(0xFF10233F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          minWidth: math.min(dialogMaxWidth, 360.0),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$station Station Trend',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: math.max(280, math.min(400, 60.0 * data.length)),
                child: SfCartesianChart3D(
                  backgroundColor: Colors.transparent,
                  tooltipBehavior: TooltipBehavior(enable: true),
                  primaryXAxis: CategoryAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  primaryYAxis: NumericAxis(
                    name: 'passAxis',
                    majorGridLines:
                        const MajorGridLines(dashArray: [4, 4], color: Colors.white24),
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                    axisLine: const AxisLine(color: Colors.transparent),
                  ),
                  axes: const <ChartAxis>[
                    NumericAxis(
                      name: 'rrAxis',
                      opposedPosition: true,
                      axisLine: AxisLine(color: Colors.transparent),
                      majorGridLines: MajorGridLines(width: 0),
                      minimum: 0,
                      maximum: 100,
                      labelFormat: '{value}%',
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                  legend: const Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                    overflowMode: LegendItemOverflowMode.wrap,
                    textStyle: TextStyle(color: Colors.white70),
                  ),
                  series: <ChartSeries<dynamic, dynamic>>[
                    ColumnSeries3D<_StationTrendPoint, String>(
                      name: 'Pass Qty',
                      dataSource: data,
                      xValueMapper: (p, _) => p.label,
                      yValueMapper: (p, _) => p.pass,
                      color: const Color(0xFF44CA71),
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelAlignment: ChartDataLabelAlignment.outer,
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      dataLabelMapper: (p, _) => p.pass.toStringAsFixed(0),
                    ),
                    SplineSeries3D<_StationTrendPoint, String>(
                      name: 'Retest Rate',
                      dataSource: data,
                      xValueMapper: (p, _) => p.label,
                      yValueMapper: (p, _) => p.rr,
                      yAxisName: 'rrAxis',
                      markerSettings:
                          const MarkerSettings(isVisible: true, color: Colors.white),
                      width: 3.2,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        labelAlignment: ChartDataLabelAlignment.outer,
                      ),
                      dataLabelMapper: (p, _) => '${p.rr.toStringAsFixed(2)}%',
                      color: const Color(0xFFE36269),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_StationTrendPoint> _buildPoints() {
    final count = math.min(hours.length, metrics.length);
    return List<_StationTrendPoint>.generate(count, (int index) {
      final label = formatHourRange(hours[index]);
      final metric = metrics[index];
      return _StationTrendPoint(
        label: label,
        pass: metric.pass,
        rr: metric.rr,
      );
    });
  }
}

class OtSectionDetailDialog extends StatefulWidget {
  const OtSectionDetailDialog({
    super.key,
    required this.station,
    required this.section,
    required this.detail,
  });

  final String station;
  final String section;
  final OutputTrackingDetailEntity detail;

  @override
  State<OtSectionDetailDialog> createState() => _OtSectionDetailDialogState();
}

class _OtSectionDetailDialogState extends State<OtSectionDetailDialog> {
  late final TextEditingController _testerSearchController;
  String _testerQuery = '';

  @override
  void initState() {
    super.initState();
    _testerSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _testerSearchController.dispose();
    super.dispose();
  }

  void _onTesterSearchChanged(String value) {
    setState(() => _testerQuery = value.trim());
  }

  void _clearTesterSearch() {
    if (_testerSearchController.text.isEmpty) return;
    _testerSearchController.clear();
    _onTesterSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final List<_DetailPoint> errorPoints = widget.detail.errorDetails
        .map((e) => _DetailPoint(label: e.code, value: e.failQty))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final List<_DetailPoint> testerPointsBase = widget.detail.testerDetails
        .map((e) => _DetailPoint(label: e.stationName, value: e.failQty))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<_DetailPoint> testerPoints = _filterTesterPoints(testerPointsBase);

    final sectionLabel = formatHourRange(widget.section);
    final screenWidth = MediaQuery.of(context).size.width;
    final double dialogMaxWidth =
        (screenWidth * 0.8).clamp(380.0, 1320.0).toDouble();

    final bool isSearching = _testerQuery.isNotEmpty;
    final String testerEmptyMessage = testerPoints.isEmpty &&
            testerPointsBase.isNotEmpty &&
            isSearching
        ? 'Không tìm thấy tester trùng khớp.'
        : 'Không có dữ liệu máy test trong khung giờ này.';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: const Color(0xFF10233F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          minWidth: math.min(dialogMaxWidth, 380.0),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.station} · $sectionLabel',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Yield & Retest analysis',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 18),
                _buildBarChart(
                  title: 'Top Error Codes',
                  points: errorPoints,
                  emptyMessage: 'Không có lỗi nào trong khung giờ này.',
                  primaryHeader: 'Error Code',
                  barColor: const Color(0xFFE45A61),
                ),
                const SizedBox(height: 20),
                _buildBarChart(
                  title: 'Top Tester Stations',
                  points: testerPoints,
                  emptyMessage: testerEmptyMessage,
                  primaryHeader: 'Tester Station',
                  barColor: const Color(0xFF66D9EF),
                  enableSearch: true,
                  searchController: _testerSearchController,
                  searchQuery: _testerQuery,
                  onSearchChanged: _onTesterSearchChanged,
                  onClearSearch: _clearTesterSearch,
                  searchPlaceholder: 'Tìm tester station',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_DetailPoint> _filterTesterPoints(List<_DetailPoint> source) {
    if (_testerQuery.isEmpty) return source;
    final lower = _testerQuery.toLowerCase();
    return source
        .where((point) => point.label.toLowerCase().contains(lower))
        .toList();
  }

  Widget _buildBarChart({
    required String title,
    required List<_DetailPoint> points,
    required String emptyMessage,
    required String primaryHeader,
    required Color barColor,
    bool enableSearch = false,
    TextEditingController? searchController,
    String searchQuery = '',
    ValueChanged<String>? onSearchChanged,
    VoidCallback? onClearSearch,
    String searchPlaceholder = 'Search',
  }) {
    const panelColor = Color(0xFF162C4B);
    final List<_DetailPoint> effectivePoints = _effectivePoints(points);
    final List<_DetailPoint> chartPoints =
        effectivePoints.where((p) => p.value > 0).toList();
    if (chartPoints.isEmpty && effectivePoints.isNotEmpty) {
      chartPoints.addAll(
        effectivePoints.take(math.min(6, effectivePoints.length)),
      );
    }

    final bool hasData = chartPoints.isNotEmpty;

    final double baseHeight = hasData
        ? math.min(320.0, 58.0 * math.max(4, effectivePoints.length))
        : 150.0;

    return SizedBox(
      height: baseHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget? buildSearchBox() {
            if (!(enableSearch &&
                searchController != null &&
                onSearchChanged != null)) {
              return null;
            }
            return TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: searchPlaceholder,
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: Colors.white54),
                suffixIcon:
                    searchQuery.isNotEmpty && onClearSearch != null
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 18, color: Colors.white54),
                            onPressed: onClearSearch,
                          )
                        : null,
                filled: true,
                fillColor: const Color(0xFF1F3458),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2A4165),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.cyanAccent,
                    width: 1.2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            );
          }

          if (!hasData) {
            final searchBox = buildSearchBox();
            return Container(
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (searchBox != null) ...[
                    searchBox,
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: Center(
                      child: Text(
                        emptyMessage,
                        style: const TextStyle(color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final bool isWide = constraints.maxWidth >= 640;
          final double listWidth = math.min(280.0, constraints.maxWidth * 0.38);
          final headerStyle = const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          );

          Widget buildListColumn() {
            final searchBox = buildSearchBox();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (searchBox != null) ...[
                  searchBox,
                  const SizedBox(height: 8),
                ],
                _DetailListHeader(
                  primaryHeader: primaryHeader,
                  valueHeader: 'Fail Qty',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _DetailList(
                    points: effectivePoints,
                    emptyMessage: emptyMessage,
                  ),
                ),
              ],
            );
          }

          final Widget chartPanel = Container(
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: headerStyle),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _buildDetailChart(
                                chartPoints,
                                panelColor,
                                baseColor: barColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: listWidth, child: buildListColumn()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: headerStyle),
                      const SizedBox(height: 12),
                      Flexible(
                        flex: 3,
                        child: _buildDetailChart(
                          chartPoints,
                          panelColor,
                          baseColor: barColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        flex: 2,
                        child: buildListColumn(),
                      ),
                    ],
                  ),
          );

          return chartPanel;
        },
      ),
    );
  }

  Widget _buildDetailChart(
    List<_DetailPoint> points,
    Color panelColor, {
    required Color baseColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SfCartesianChart3D(
        backgroundColor: panelColor,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
          labelRotation: points.length > 6 ? -30 : 0,
        ),
        primaryYAxis: NumericAxis(
          majorGridLines:
              const MajorGridLines(dashArray: [4, 4], color: Colors.white24),
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
          axisLine: const AxisLine(color: Colors.transparent),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <ChartSeries<dynamic, dynamic>>[
          ColumnSeries3D<_DetailPoint, String>(
            dataSource: points,
            xValueMapper: (p, _) => p.label,
            yValueMapper: (p, _) => p.value.toDouble(),
            color: baseColor,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              labelAlignment: ChartDataLabelAlignment.outer,
            ),
            dataLabelMapper: (p, _) => p.value.toString(),
          ),
        ],
      ),
    );
  }

  List<_DetailPoint> _effectivePoints(List<_DetailPoint> points) {
    if (points.isEmpty) return const <_DetailPoint>[];
    return points.take(18).toList();
  }
}

class _StationTrendPoint {
  _StationTrendPoint({
    required this.label,
    required this.pass,
    required this.rr,
  });

  final String label;
  final double pass;
  final double rr;
}

class _DetailPoint {
  _DetailPoint({required this.label, required this.value});

  final String label;
  final int value;
}

class _DetailListHeader extends StatelessWidget {
  const _DetailListHeader({
    required this.primaryHeader,
    required this.valueHeader,
  });

  final String primaryHeader;
  final String valueHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3358),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              primaryHeader,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            valueHeader,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailList extends StatelessWidget {
  const _DetailList({
    required this.points,
    this.emptyMessage = 'Không có dữ liệu',
  });

  final List<_DetailPoint> points;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: points.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final point = points[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B3358),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  point.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                point.value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
