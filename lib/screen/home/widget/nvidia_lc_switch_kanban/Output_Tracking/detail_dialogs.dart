import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../../../service/lc_switch_kanban_api.dart';
import 'output_tracking_view_state.dart';
import 'series_utils.dart';

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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: const Color(0xFF10233F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, minWidth: 320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
                child: SfCartesianChart(
                  backgroundColor: Colors.transparent,
                  tooltipBehavior: TooltipBehavior(enable: true),
                  primaryXAxis: CategoryAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  primaryYAxis: NumericAxis(
                    name: 'passAxis',
                    majorGridLines: const MajorGridLines(dashArray: [4, 4], color: Colors.white24),
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                    axisLine: const AxisLine(color: Colors.transparent),
                  ),
                  axes: <ChartAxis>[
                    NumericAxis(
                      name: 'rrAxis',
                      opposedPosition: true,
                      axisLine: const AxisLine(color: Colors.transparent),
                      majorGridLines: const MajorGridLines(width: 0),
                      minimum: 0,
                      maximum: 100,
                      labelFormat: '{value}%',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                    overflowMode: LegendItemOverflowMode.wrap,
                    textStyle: const TextStyle(color: Colors.white70),
                  ),
                  series: <CartesianSeries<dynamic, dynamic>>[
                    ColumnSeries<_StationTrendPoint, String>(
                      name: 'Pass Qty',
                      dataSource: data,
                      xValueMapper: (p, _) => p.label,
                      yValueMapper: (p, _) => p.pass,
                      color: const Color(0xFF44CA71),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelAlignment: ChartDataLabelAlignment.outer,
                        textStyle: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      dataLabelMapper: (p, _) => p.pass.toStringAsFixed(0),
                    ),
                    SplineSeries<_StationTrendPoint, String>(
                      name: 'Retest Rate',
                      dataSource: data,
                      xValueMapper: (p, _) => p.label,
                      yValueMapper: (p, _) => p.rr,
                      yAxisName: 'rrAxis',
                      markerSettings: const MarkerSettings(isVisible: true, color: Colors.white),
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        textStyle: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
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
    return List<_StationTrendPoint>.generate(count, (index) {
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

class OtSectionDetailDialog extends StatelessWidget {
  const OtSectionDetailDialog({
    super.key,
    required this.station,
    required this.section,
    required this.detail,
  });

  final String station;
  final String section;
  final KanbanOutputTrackingDetail detail;

  @override
  Widget build(BuildContext context) {
    final errorPoints = detail.errorDetails
        .map((e) => _DetailPoint(label: e.code, value: e.failQty))
        .where((p) => p.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final testerPoints = detail.testerDetails
        .map((e) => _DetailPoint(label: e.stationName, value: e.failQty))
        .where((p) => p.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sectionLabel = formatHourRange(section);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: const Color(0xFF10233F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, minWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$station · $sectionLabel',
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 20),
              _buildBarChart(
                title: 'Top Error Codes',
                points: errorPoints,
                emptyMessage: 'Không có lỗi nào trong khung giờ này.',
              ),
              const SizedBox(height: 24),
              _buildBarChart(
                title: 'Top Tester Stations',
                points: testerPoints,
                emptyMessage: 'Không có dữ liệu máy test trong khung giờ này.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart({
    required String title,
    required List<_DetailPoint> points,
    required String emptyMessage,
  }) {
    return SizedBox(
      height: points.isEmpty ? 140 : math.min(320, 56.0 * math.max(4, points.length)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: points.isEmpty
                ? Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF162C4B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      emptyMessage,
                      style: const TextStyle(color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SfCartesianChart(
                    backgroundColor: const Color(0xFF162C4B),
                    plotAreaBorderWidth: 0,
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
                      labelRotation: points.length > 6 ? -35 : 0,
                    ),
                    primaryYAxis: NumericAxis(
                      majorGridLines: const MajorGridLines(dashArray: [4, 4], color: Colors.white24),
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
                      axisLine: const AxisLine(color: Colors.transparent),
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries<dynamic, dynamic>>[
                      ColumnSeries<_DetailPoint, String>(
                        dataSource: points,
                        xValueMapper: (p, _) => p.label,
                        yValueMapper: (p, _) => p.value.toDouble(),
                        color: const Color(0xFF66D9EF),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          textStyle: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        dataLabelMapper: (p, _) => p.value.toString(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
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
  _DetailPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;
}
