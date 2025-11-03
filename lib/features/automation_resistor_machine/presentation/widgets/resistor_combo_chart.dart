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
    final showYieldTarget = title.toLowerCase().contains('yield rate');

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
        displayCategory: _formatCategoryLabel(categories[index]),
        pass: pass[index],
        fail: fail[index],
        yr: yr[index],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF031A3C),
            Color(0xFF020B24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.25), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              plotAreaBorderWidth: 0,
              legend: const Legend(
                isVisible: true,
                textStyle: TextStyle(color: Colors.white70),
              ),
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(color: Colors.white70),
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(color: Colors.white.withOpacity(0.2)),
                majorTickLines: const MajorTickLines(size: 4, color: Colors.white30),
                labelRotation: categories.length > 6 ? -35 : 0,
              ),
              primaryYAxis: NumericAxis(
                labelStyle: const TextStyle(color: Colors.white70),
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(color: Colors.white12),
                majorTickLines: const MajorTickLines(size: 0),
                axisLabelFormatter: (AxisLabelRenderDetails details) =>
                    ChartAxisLabel('', const TextStyle()),
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
                  axisLine: const AxisLine(width: 0),
                  axisLabelFormatter: (AxisLabelRenderDetails details) =>
                      ChartAxisLabel('', const TextStyle()),
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
              annotations: <CartesianChartAnnotation>[
                if (showYieldTarget && points.isNotEmpty)
                  CartesianChartAnnotation(
                    widget: Transform.translate(
                      offset: const Offset(14, -8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Target (98%)',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    x: points.last.displayCategory,
                    y: 98,
                    yAxisName: 'yrAxis',
                    coordinateUnit: CoordinateUnit.point,
                    horizontalAlignment: ChartAlignment.far,
                    verticalAlignment: ChartAlignment.center,
                  ),
              ],
              series: <CartesianSeries<_ComboPoint, String>>[
                ColumnSeries<_ComboPoint, String>(
                  name: 'PASS',
                  width: 0.65,
                  spacing: 0.15,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FFE7), Color(0xFF008BFF)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  dataSource: points,
                  xValueMapper: (_ComboPoint point, _) => point.displayCategory,
                  yValueMapper: (_ComboPoint point, _) => point.pass,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.outer,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ColumnSeries<_ComboPoint, String>(
                  name: 'FAIL',
                  width: 0.65,
                  spacing: 0.15,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF597A), Color(0xFFFF004F)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  dataSource: points,
                  xValueMapper: (_ComboPoint point, _) => point.displayCategory,
                  yValueMapper: (_ComboPoint point, _) => point.fail,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.outer,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SplineSeries<_ComboPoint, String>(
                  name: 'YR',
                  dataSource: points,
                  yAxisName: 'yrAxis',
                  color: const Color(0xFF39FF14),
                  width: 3,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    width: 8,
                    height: 8,
                    color: Color(0xFF39FF14),
                    borderColor: Colors.white,
                  ),
                  xValueMapper: (_ComboPoint point, _) => point.displayCategory,
                  yValueMapper: (_ComboPoint point, _) => point.yr,
                  dataLabelSettings: const DataLabelSettings(isVisible: false),
                ),
                LineSeries<_ComboPoint, String>(
                  name: 'Target (98%)',
                  yAxisName: 'yrAxis',
                  dataSource: points,
                  color: Colors.cyanAccent,
                  dashArray: const <double>[6, 4],
                  width: 2,
                  markerSettings: const MarkerSettings(isVisible: false),
                  xValueMapper: (_ComboPoint point, _) => point.displayCategory,
                  yValueMapper: (_ComboPoint point, _) => 98,
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
        gradient: const LinearGradient(
          colors: [
            Color(0xFF031A3C),
            Color(0xFF020B24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.25), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
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
    required this.displayCategory,
    required this.pass,
    required this.fail,
    required this.yr,
  });

  final String displayCategory;
  final int pass;
  final int fail;
  final double yr;
}

String _formatCategoryLabel(String value) {
  final match = RegExp(r'^S(\d+)$').firstMatch(value.trim());
  if (match == null) {
    return value;
  }

  final index = int.tryParse(match.group(1) ?? '') ?? 0;
  if (index <= 0) {
    return value;
  }

  const minutesPerDay = 24 * 60;
  const slotMinutes = 60;
  const baseMinutes = 7 * 60 + 30;

  final startMinutes = baseMinutes + (index - 1) * slotMinutes;
  final endMinutes = startMinutes + slotMinutes;

  final startLabel = _formatMinutes(startMinutes % minutesPerDay);
  final endLabel = _formatMinutes(endMinutes % minutesPerDay);
  return '$startLabel - $endLabel';
}

String _formatMinutes(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}
