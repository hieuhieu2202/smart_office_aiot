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
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final testerPoints = detail.testerDetails
        .map((e) => _DetailPoint(label: e.stationName, value: e.failQty))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sectionLabel = formatHourRange(section);
    final screenWidth = MediaQuery.of(context).size.width;
    final double dialogMaxWidth =
        (screenWidth * 0.8).clamp(380.0, 1320.0).toDouble();

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
              const SizedBox(height: 18),
              _buildBarChart(
                title: 'Top Error Codes',
                points: errorPoints,
                emptyMessage: 'Không có lỗi nào trong khung giờ này.',
              ),
              const SizedBox(height: 20),
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
    const panelColor = Color(0xFF162C4B);
    final effectivePoints = _effectivePoints(points);
    final hasData = effectivePoints.isNotEmpty;

    final baseHeight = hasData
        ? math.min(320.0, 58.0 * math.max(4, effectivePoints.length))
        : 150.0;

    return SizedBox(
      height: baseHeight,
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
            child: hasData
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 640;

                      final chart = Expanded(
                        child: _buildDetailChart(
                          effectivePoints,
                          panelColor,
                          isWide ? 0.0 : math.max(0.0, baseHeight - 170.0),
                        ),
                      );

                      final list = _DetailList(
                        points: effectivePoints,
                        backgroundColor: panelColor,
                      );

                      if (isWide) {
                        final listWidth = math.min(240.0, constraints.maxWidth * 0.35);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            chart,
                            const SizedBox(width: 16),
                            SizedBox(width: listWidth, child: list),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          chart,
                          const SizedBox(height: 12),
                          SizedBox(
                            height: math.min(180.0, constraints.maxHeight * 0.45),
                            child: list,
                          ),
                        ],
                      );
                    },
                  )
                : Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
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

  Widget _buildDetailChart(
    List<_DetailPoint> points,
    Color panelColor,
    double minHeight,
  ) {
    return SizedBox.expand(
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        child: SfCartesianChart(
          backgroundColor: panelColor,
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
    );
  }

  List<_DetailPoint> _effectivePoints(List<_DetailPoint> points) {
    if (points.isEmpty) return const [];

    final positive = <_DetailPoint>[];
    final zeros = <_DetailPoint>[];
    for (final point in points) {
      if (point.value > 0) {
        positive.add(point);
      } else {
        zeros.add(point);
      }
    }

    return <_DetailPoint>[...positive, ...zeros];
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

class _DetailList extends StatelessWidget {
  const _DetailList({
    super.key,
    required this.points,
    required this.backgroundColor,
  });

  final List<_DetailPoint> points;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView.separated(
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: points.length,
        separatorBuilder: (_, __) => const Divider(
          height: 12,
          thickness: 0.6,
          color: Color(0xFF233755),
        ),
        itemBuilder: (context, index) {
          final point = points[index];
          return Row(
            children: [
              Expanded(
                child: Text(
                  point.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                point.value.toString(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
