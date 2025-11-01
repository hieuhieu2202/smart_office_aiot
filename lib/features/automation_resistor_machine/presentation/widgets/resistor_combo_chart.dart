import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../viewmodels/resistor_dashboard_view_state.dart';

class ResistorComboChart extends StatelessWidget {
  const ResistorComboChart({
    super.key,
    required this.title,
    required this.series,
  });

  final String title;
  final ResistorStackedSeries series;

  @override
  Widget build(BuildContext context) {
    final categories = series.categories;
    final pass = series.pass;
    final fail = series.fail;
    final yr = series.yieldRate;

    if (categories.isEmpty || pass.isEmpty || fail.isEmpty || yr.isEmpty) {
      return _buildEmptyState(context);
    }

    final itemCount = math.min(
      categories.length,
      math.min(pass.length, math.min(fail.length, yr.length)),
    );

    if (itemCount == 0) {
      return _buildEmptyState(context);
    }

    final points = List<_ComboPoint>.generate(
      itemCount,
      (index) => _ComboPoint(
        category: categories[index],
        pass: pass[index],
        fail: fail[index],
        yr: yr[index],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF04142F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueGrey.shade800, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              legend: const Legend(
                isVisible: true,
                textStyle: TextStyle(color: Colors.white70),
              ),
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(color: Colors.white70),
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(color: Colors.white24),
                labelRotation: categories.length > 6 ? -35 : 0,
              ),
              primaryYAxis: NumericAxis(
                labelStyle: const TextStyle(color: Colors.white70),
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(color: Colors.white12),
              ),
              axes: <ChartAxis>[
                NumericAxis(
                  name: 'yrAxis',
                  opposedPosition: true,
                  minimum: 0,
                  maximum: 110,
                  interval: 10,
                  labelFormat: '{value}%',
                  labelStyle: const TextStyle(color: Colors.cyanAccent),
                  majorGridLines: const MajorGridLines(width: 0),
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries<_ComboPoint, String>>[
                ColumnSeries<_ComboPoint, String>(
                  name: 'PASS',
                  width: 0.6,
                  spacing: 0.2,
                  color: const Color(0xFF00FFE7),
                  dataSource: points,
                  xValueMapper: (_ComboPoint point, _) => point.category,
                  yValueMapper: (_ComboPoint point, _) => point.pass,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: false,
                  ),
                ),
                ColumnSeries<_ComboPoint, String>(
                  name: 'FAIL',
                  width: 0.6,
                  spacing: 0.2,
                  color: const Color(0xFFFF004F),
                  dataSource: points,
                  xValueMapper: (_ComboPoint point, _) => point.category,
                  yValueMapper: (_ComboPoint point, _) => point.fail,
                  dataLabelSettings: const DataLabelSettings(isVisible: false),
                ),
                SplineSeries<_ComboPoint, String>(
                  name: 'YR',
                  dataSource: points,
                  yAxisName: 'yrAxis',
                  color: const Color(0xFF39FF14),
                  markerSettings: const MarkerSettings(isVisible: true),
                  xValueMapper: (_ComboPoint point, _) => point.category,
                  yValueMapper: (_ComboPoint point, _) => point.yr,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF04142F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueGrey.shade800, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Text(
        'No chart data',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _ComboPoint {
  const _ComboPoint({
    required this.category,
    required this.pass,
    required this.fail,
    required this.yr,
  });

  final String category;
  final int pass;
  final int fail;
  final double yr;
}
