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
              series: <ChartSeries<dynamic, String>>[
                ColumnSeries<dynamic, String>(
                  name: 'PASS',
                  width: 0.6,
                  spacing: 0.2,
                  color: const Color(0xFF00FFE7),
                  dataSource: List<int>.from(pass),
                  xValueMapper: (dynamic _, int index) => categories[index],
                  yValueMapper: (dynamic value, _) => value,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: false,
                  ),
                ),
                ColumnSeries<dynamic, String>(
                  name: 'FAIL',
                  width: 0.6,
                  spacing: 0.2,
                  color: const Color(0xFFFF004F),
                  dataSource: List<int>.from(fail),
                  xValueMapper: (dynamic _, int index) => categories[index],
                  yValueMapper: (dynamic value, _) => value,
                  dataLabelSettings: const DataLabelSettings(isVisible: false),
                ),
                SplineSeries<dynamic, String>(
                  name: 'YR',
                  dataSource: List<double>.from(yr),
                  yAxisName: 'yrAxis',
                  color: const Color(0xFF39FF14),
                  markerSettings: const MarkerSettings(isVisible: true),
                  xValueMapper: (dynamic _, int index) => categories[index],
                  yValueMapper: (dynamic value, _) => value,
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
}
