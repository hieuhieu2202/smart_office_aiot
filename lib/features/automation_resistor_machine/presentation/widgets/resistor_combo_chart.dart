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
    this.startSection = 1,
  });

  final String title;
  final ResistorStackedSeries series;
  final bool alignToShiftWindows;
  final int startSection;

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
      points = _normalizeShiftWindows(points, startSection);
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

const List<String> _sectionShiftWindows = [
  '06:30 - 07:30',
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
String _formatCategoryLabel(String value) {
  final trimmed = value.trim();
  final match = RegExp(r'^S(\d+)$').firstMatch(trimmed);
  if (match == null) return trimmed;

  final index = int.tryParse(match.group(1) ?? '');
  if (index == null || index <= 0) return trimmed;

  if (index <= _sectionShiftWindows.length) {
    return _sectionShiftWindows[index - 1];
  }
  return trimmed;
}

List<_ComboPoint> _normalizeShiftWindows(List<_ComboPoint> points, int startSection) {
  final buckets = <int, _ShiftBucket>{};
  int? firstValidIndex;

  for (final p in points) {
    final idx = _resolveShiftIndex(p);
    if (idx != null) {
      final b = buckets.putIfAbsent(idx, () => _ShiftBucket());
      b.pass += p.pass;
      b.fail += p.fail;
      firstValidIndex ??= idx; // ghi nhớ index đầu tiên có dữ liệu
    }
  }

  // nếu controller truyền startSection = 1 thì dùng index đầu tiên có data
  final start = (startSection == 1 && firstValidIndex != null)
      ? firstValidIndex!.clamp(0, _sectionShiftWindows.length - 1)
      : (startSection - 1).clamp(0, _sectionShiftWindows.length - 1);

  final end = math.min(start + 12, _sectionShiftWindows.length);

  final normalized = <_ComboPoint>[];
  for (var i = start; i < end; i++) {
    final b = buckets[i];
    normalized.add(
      _ComboPoint(
        rawCategory: 'S${i + 1}',
        displayCategory: _sectionShiftWindows[i],
        pass: b?.pass ?? 0,
        fail: b?.fail ?? 0,
        yr: b?.yr ?? 0,
      ),
    );
  }
  return normalized;
}

int? _resolveShiftIndex(_ComboPoint p) {
  final s = p.section;
  if (s != null && s > 0 && s <= _sectionShiftWindows.length) return s - 1;

  final raw = RegExp(r'^S(\d+)$').firstMatch(p.rawCategory.trim());
  if (raw != null) {
    final v = int.tryParse(raw.group(1) ?? '');
    if (v != null && v > 0 && v <= _sectionShiftWindows.length) return v - 1;
  }

  final d = _sectionShiftWindows.indexWhere(
        (e) => e.toLowerCase() == p.displayCategory.toLowerCase(),
  );
  return d != -1 ? d : null;
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
