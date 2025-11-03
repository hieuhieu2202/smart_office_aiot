import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../viewmodels/resistor_dashboard_view_state.dart';

class ResistorComboChart extends StatelessWidget {
  const ResistorComboChart({
    super.key,
    required this.title,
    required this.series,
    this.alignToShiftWindows = false,
  });

  final String title;
  final ResistorStackedSeries series;
  final bool alignToShiftWindows;

  @override
  Widget build(BuildContext context) {
    final categories = series.categories;
    final pass = series.pass;
    final fail = series.fail;
    final yr = series.yieldRate;
    final sections = series.sections;
    final shiftStartMinutes = series.shiftStartMinutes;
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

    var points = List<_ComboPoint>.generate(
      itemCount,
      (index) => _ComboPoint(
        rawCategory: categories[index],
        displayCategory: _formatCategoryLabel(categories[index]),
        pass: pass[index],
        fail: fail[index],
        yr: yr[index],
        section: index < sections.length ? sections[index] : null,
        shiftStartMinutes:
            index < shiftStartMinutes.length ? shiftStartMinutes[index] : null,
      ),
    );

    if (alignToShiftWindows) {
      points = _normalizeShiftWindows(points);
    }

    final axisLabelStyle = TextStyle(
      color: Colors.white70,
      fontSize: alignToShiftWindows ? 10 : 12,
      fontWeight: alignToShiftWindows ? FontWeight.w600 : FontWeight.w500,
      height: alignToShiftWindows ? 1.18 : 1.0,
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
                labelStyle: axisLabelStyle,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(color: Colors.white.withOpacity(0.2)),
                majorTickLines: const MajorTickLines(size: 4, color: Colors.white30),
                labelRotation:
                    alignToShiftWindows || points.length <= 6 ? 0 : -35,
                labelIntersectAction: alignToShiftWindows
                    ? AxisLabelIntersectAction.wrap
                    : AxisLabelIntersectAction.hide,
                axisLabelFormatter: alignToShiftWindows
                    ? (AxisLabelRenderDetails details) => ChartAxisLabel(
                          _wrapShiftLabel(details.text),
                          axisLabelStyle,
                        )
                    : null,
                maximumLabelWidth: alignToShiftWindows ? 64 : null,
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
    required this.rawCategory,
    required this.displayCategory,
    required this.pass,
    required this.fail,
    required this.yr,
    this.section,
    this.shiftStartMinutes,
  });

  final String rawCategory;
  final String displayCategory;
  final int pass;
  final int fail;
  final double yr;
  final int? section;
  final int? shiftStartMinutes;
}

const List<String> _sectionShiftWindows = <String>[
  '07:30 - 08:30',
  '08:30 - 09:30',
  '09:30 - 10:30',
  '10:30 - 11:30',
  '11:30 - 12:30',
  '12:30 - 13:30',
  '13:30 - 14:30',
  '14:30 - 15:30',
  '15:30 - 16:30',
  '16:30 - 17:30',
  '17:30 - 18:30',
  '18:30 - 19:30',
];

final List<int> _sectionStartMinutes = List<int>.unmodifiable(
  List<int>.generate(
    _sectionShiftWindows.length,
    (index) => (7 + index) * 60 + 30,
  ),
);

String _formatCategoryLabel(String value) {
  final trimmed = value.trim();
  final match = RegExp(r'^S(\d+)$').firstMatch(trimmed);
  if (match == null) {
    return trimmed;
  }

  final index = int.tryParse(match.group(1) ?? '');
  if (index == null || index <= 0) {
    return trimmed;
  }

  if (index <= _sectionShiftWindows.length) {
    return _sectionShiftWindows[index - 1];
  }

  return trimmed;
}

List<_ComboPoint> _normalizeShiftWindows(List<_ComboPoint> points) {
  final buckets = List<_ShiftBucket>.generate(
    _sectionShiftWindows.length,
    (_) => _ShiftBucket(),
  );

  for (final point in points) {
    final slotIndex = _resolveShiftIndex(point);
    if (slotIndex == null) {
      continue;
    }
    final bucket = buckets[slotIndex];
    bucket.pass += point.pass;
    bucket.fail += point.fail;
  }

  return List<_ComboPoint>.generate(_sectionShiftWindows.length, (index) {
    final bucket = buckets[index];
    return _ComboPoint(
      rawCategory: 'S${index + 1}',
      displayCategory: _sectionShiftWindows[index],
      pass: bucket.pass,
      fail: bucket.fail,
      yr: bucket.yr,
      section: index + 1,
      shiftStartMinutes: _sectionStartMinutes[index],
    );
  });
}

int? _resolveShiftIndex(_ComboPoint point) {
  final section = point.section;
  if (section != null && section > 0 && section <= _sectionShiftWindows.length) {
    return section - 1;
  }

  final minuteIndex = _indexForStartMinutes(point.shiftStartMinutes);
  if (minuteIndex != null) {
    return minuteIndex;
  }

  final rawMatch = RegExp(r'^S(\d+)$').firstMatch(point.rawCategory.trim());
  if (rawMatch != null) {
    final value = int.tryParse(rawMatch.group(1) ?? '');
    if (value != null && value > 0 && value <= _sectionShiftWindows.length) {
      return value - 1;
    }
  }

  final normalizedDisplay = point.displayCategory.trim();
  final displayIndex = _sectionShiftWindows
      .indexWhere((element) => element.toLowerCase() == normalizedDisplay.toLowerCase());
  if (displayIndex != -1) {
    return displayIndex;
  }

  final pattern = RegExp(r'^(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})$');
  final displayMatch = pattern.firstMatch(normalizedDisplay);
  if (displayMatch != null) {
    final normalized = '${displayMatch.group(1)} - ${displayMatch.group(2)}';
    final idx = _sectionShiftWindows.indexOf(normalized);
    if (idx != -1) {
      return idx;
    }
  }

  return null;
}

int? _indexForStartMinutes(int? minutes) {
  if (minutes == null || _sectionStartMinutes.isEmpty) {
    return null;
  }

  final base = _sectionStartMinutes.first;
  final delta = minutes - base;
  if (delta < 0) {
    return null;
  }

  final index = delta ~/ 60;
  if (index < 0 || index >= _sectionStartMinutes.length) {
    return null;
  }

  final expected = _sectionStartMinutes[index];
  if ((minutes - expected).abs() >= 60) {
    return null;
  }

  return index;
}

String _wrapShiftLabel(String label) {
  final parts = label.split(' - ');
  if (parts.length == 2) {
    return '${parts[0]}\n${parts[1]}';
  }
  return label;
}

class _ShiftBucket {
  _ShiftBucket({this.pass = 0, this.fail = 0});

  int pass;
  int fail;

  double get yr {
    final total = pass + fail;
    if (total == 0) {
      return 0;
    }
    final ratio = pass / total * 100;
    return double.parse(ratio.toStringAsFixed(2));
  }
}
