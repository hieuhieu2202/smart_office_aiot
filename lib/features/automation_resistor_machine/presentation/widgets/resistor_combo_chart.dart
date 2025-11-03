import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../viewmodels/resistor_dashboard_view_state.dart';

class ResistorComboChart extends StatelessWidget {
  const ResistorComboChart({
    super.key,
    required this.title,
    required this.series,
    this.alignToShiftWindows = false,
    this.startSection = 1,
    this.shiftStartTime,
  });

  final String title;
  final ResistorStackedSeries series;
  final bool alignToShiftWindows;
  final int startSection;
  final DateTime? shiftStartTime;

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

    if (itemCount == 0) return _buildEmptyState(context);

    var points = List<_ComboPoint>.generate(
      itemCount,
      (index) => _ComboPoint(
        rawCategory: categories[index],
        displayCategory: _formatCategoryLabel(
          categories[index],
          index < sections.length ? sections[index] : null,
          baseStartSection: alignToShiftWindows ? startSection : null,
          shiftStartTime: alignToShiftWindows ? shiftStartTime : null,
        ),
        pass: pass[index],
        fail: fail[index],
        yr: yr[index],
        section: index < sections.length ? sections[index] : null,
        shiftStartMinutes:
            index < shiftStartMinutes.length ? shiftStartMinutes[index] : null,
      ),
    );

    if (alignToShiftWindows) {
      points = _normalizeShiftWindows(points, startSection, shiftStartTime);
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
          colors: [Color(0xFF031A3C), Color(0xFF020B24)],
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
                  xValueMapper: (_ComboPoint p, _) => p.displayCategory,
                  yValueMapper: (_ComboPoint p, _) => p.pass,
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
                  xValueMapper: (_ComboPoint p, _) => p.displayCategory,
                  yValueMapper: (_ComboPoint p, _) => p.fail,
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
                  xValueMapper: (_ComboPoint p, _) => p.displayCategory,
                  yValueMapper: (_ComboPoint p, _) => p.yr,
                ),
                LineSeries<_ComboPoint, String>(
                  name: 'Target (98%)',
                  yAxisName: 'yrAxis',
                  dataSource: points,
                  color: Colors.cyanAccent,
                  dashArray: const <double>[6, 4],
                  width: 2,
                  markerSettings: const MarkerSettings(isVisible: false),
                  xValueMapper: (_ComboPoint p, _) => p.displayCategory,
                  yValueMapper: (_ComboPoint p, _) => 98,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF031A3C), Color(0xFF020B24)],
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

const int _minutesPerSection = 60;
const int _sectionsPerShift = 12;

String _formatCategoryLabel(
  String value,
  int? section, {
  int? baseStartSection,
  DateTime? shiftStartTime,
}) {
  final trimmed = value.trim();
  final match = RegExp(r'^S(\d+)$').firstMatch(trimmed);
  final parsedSection = section ?? int.tryParse(match?.group(1) ?? '');

  if (parsedSection == null || parsedSection <= 0) {
    return trimmed;
  }

  final effectiveBase = baseStartSection ?? parsedSection;
  return _formatShiftLabel(parsedSection, null, effectiveBase, shiftStartTime);
}

List<_ComboPoint> _normalizeShiftWindows(
  List<_ComboPoint> points,
  int startSectionHint,
  DateTime? shiftStartTime,
) {
  if (points.isEmpty) return points;

  final sectionBuckets = <int, _ShiftBucket>{};
  final sectionStartMinutes = <int, int>{};

  for (final point in points) {
    final section = _extractSectionNumber(point);
    if (section == null) {
      continue;
    }

    final bucket = sectionBuckets.putIfAbsent(section, () => _ShiftBucket());
    bucket.pass += point.pass;
    bucket.fail += point.fail;

    final minutes = point.shiftStartMinutes;
    if (minutes != null && !sectionStartMinutes.containsKey(section)) {
      sectionStartMinutes[section] = minutes;
    }
  }

  if (sectionBuckets.isEmpty) {
    return points;
  }

  final sortedSections = sectionBuckets.keys.toList()..sort();
  final baseSection = startSectionHint > 0 ? startSectionHint : sortedSections.first;
  final normalizedStart = baseSection;
  final offset = sortedSections.first - normalizedStart;

  final normalized = <_ComboPoint>[];
  for (var index = 0; index < _sectionsPerShift; index++) {
    final normalizedSection = normalizedStart + index;
    final actualSection = normalizedSection + offset;
    final bucket = sectionBuckets[actualSection];
    final minutes = sectionStartMinutes[actualSection] ??
        _minutesFromNormalizedSection(normalizedSection);

    normalized.add(
      _ComboPoint(
        rawCategory: 'S$normalizedSection',
        displayCategory: _formatShiftLabel(
          normalizedSection,
          minutes,
          baseSection,
          shiftStartTime,
        ),
        pass: bucket?.pass ?? 0,
        fail: bucket?.fail ?? 0,
        yr: bucket?.yr ?? 0,
        section: normalizedSection,
        shiftStartMinutes: minutes,
      ),
    );
  }

  return normalized;
}

int _minutesFromNormalizedSection(int section) {
  if (section <= 0) {
    return 7 * 60 + 30;
  }

  final normalizedIndex =
      ((section - 1) % _sectionsPerShift + _sectionsPerShift) % _sectionsPerShift;
  final blockIndex = ((section - 1) ~/ _sectionsPerShift);
  final baseHour = blockIndex.isEven ? 7 : 19;
  final startHour = (baseHour + normalizedIndex) % 24;
  return startHour * 60 + 30;
}

int? _extractSectionNumber(_ComboPoint point) {
  final section = point.section;
  if (section != null && section > 0) {
    return section;
  }

  final raw = RegExp(r'^S(\d+)$', caseSensitive: false)
      .firstMatch(point.rawCategory.trim());
  if (raw != null) {
    return int.tryParse(raw.group(1)!);
  }

  final display = RegExp(r'^S(\d+)$', caseSensitive: false)
      .firstMatch(point.displayCategory.trim());
  if (display != null) {
    return int.tryParse(display.group(1)!);
  }

  return null;
}

String _formatShiftLabel(
  int section,
  int? startMinutes,
  int baseSection,
  DateTime? shiftStartTime,
) {
  final formatter = DateFormat('HH:mm');

  if (shiftStartTime != null && baseSection > 0) {
    final offsetHours = section - baseSection;
    final start = shiftStartTime.add(Duration(hours: offsetHours));
    final end = start.add(const Duration(hours: 1));
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  if (startMinutes != null) {
    final start = _dateFromMinutes(startMinutes);
    final end = _dateFromMinutes(startMinutes + _minutesPerSection);
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  if (baseSection > 0) {
    final reference = DateTime(1970, 1, 1, 7, 30);
    final start = reference.add(Duration(hours: section - baseSection));
    final end = start.add(const Duration(hours: 1));
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  final fallbackStart = DateTime(1970, 1, 1, 7, 30);
  final fallbackEnd = fallbackStart.add(const Duration(hours: 1));
  return '${formatter.format(fallbackStart)} - ${formatter.format(fallbackEnd)}';
}

DateTime _dateFromMinutes(int minutes) {
  final normalized = ((minutes % (24 * 60)) + (24 * 60)) % (24 * 60);
  return DateTime(1970, 1, 1).add(Duration(minutes: normalized));
}

String _wrapShiftLabel(String label) {
  final parts = label.split(' - ');
  return parts.length == 2 ? '${parts[0]}\n${parts[1]}' : label;
}

class _ShiftBucket {
  _ShiftBucket({this.pass = 0, this.fail = 0});
  int pass;
  int fail;
  double get yr {
    final total = pass + fail;
    if (total == 0) return 0;
    return double.parse((pass / total * 100).toStringAsFixed(2));
  }
}
