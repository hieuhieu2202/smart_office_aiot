import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import '../../../../config/global_color.dart';

const double _barWidth = 20.0;
const double _barSpace = 12.0;
const double _groupSpace = 30.0;

class PTHDashboardOutputChart extends StatelessWidget {
  final Map data;
  final double? height;

  const PTHDashboardOutputChart({
    super.key,
    required this.data,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final output = data['output'] as List? ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? GlobalColors.labelDark : GlobalColors.labelLight;
    final bgColor = isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;

    if (output.isEmpty) {
      return Card(
        color: bgColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const SizedBox(
          height: 210,
          child: Center(child: Text('No data available')),
        ),
      );
    }

    final sections =
        output.map((e) => (e['section'] ?? e['SECTION']).toString()).toList();
    final passList =
        output.map((e) => (e['pass'] ?? e['PASS'] ?? 0) as num).toList();
    final failList =
        output.map((e) => (e['fail'] ?? e['FAIL'] ?? 0) as num).toList();
    final lineList =
        output.map((e) => (e['yr'] ?? e['YR'] ?? 0) as num).toList();

    double maxY = 0;
    for (int i = 0; i < output.length; i++) {
      maxY = math.max(
        maxY,
        math.max(passList[i].toDouble(), failList[i].toDouble()),
      );
    }
    maxY = maxY < 10 ? 10 : maxY * 1.12;

    final chartWidth = math.max(
      350.0,
      sections.length * (_barWidth * 2 + _barSpace + _groupSpace) + 10,
    );
    final double baseChartHeight =
        maxY < 30 ? 120.0 : math.min(maxY * 2.7, 220.0).toDouble();
    final double? forcedHeight =
        (height != null && height! > 0) ? height : null;

    return Card(
      color: bgColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: _OutputChartBody(
          sections: sections,
          passList: passList,
          failList: failList,
          lineList: lineList,
          maxY: maxY,
          chartWidth: chartWidth,
          labelColor: labelColor,
          isDark: isDark,
          baseChartHeight: baseChartHeight,
          forcedHeight: forcedHeight,
        ),
      ),
    );
  }

  Widget _legendDot(Color color) => _outputLegendDot(color);
}

Widget _outputLegendDot(Color color) {
  return Container(
    width: 13,
    height: 13,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6.5),
    ),
  );
}

class _OutputChartBody extends StatelessWidget {
  final List<String> sections;
  final List<num> passList;
  final List<num> failList;
  final List<num> lineList;
  final double maxY;
  final double chartWidth;
  final Color labelColor;
  final bool isDark;
  final double baseChartHeight;
  final double? forcedHeight;

  const _OutputChartBody({
    required this.sections,
    required this.passList,
    required this.failList,
    required this.lineList,
    required this.maxY,
    required this.chartWidth,
    required this.labelColor,
    required this.isDark,
    required this.baseChartHeight,
    this.forcedHeight,
  });

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 7),
      child: Row(
        children: [
          Text(
            "Output by Section",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          _outputLegendDot(const Color(0xFF2196F3)),
          const SizedBox(width: 4),
          Text(
            "PASS",
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 5),
          _outputLegendDot(const Color(0xFFFF9800)),
          const SizedBox(width: 4),
          Text(
            "FAIL",
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 5),
          _outputLegendDot(Colors.green),
          const SizedBox(width: 4),
          Text(
            "Yield (%)",
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );

    final chart = forcedHeight != null
        ? Expanded(
            child: _ResponsiveOutputChart(
              sections: sections,
              passList: passList,
              failList: failList,
              lineList: lineList,
              maxY: maxY,
              chartWidth: chartWidth,
              labelColor: labelColor,
              baseChartHeight: baseChartHeight,
              expand: true,
            ),
          )
        : _ResponsiveOutputChart(
            sections: sections,
            passList: passList,
            failList: failList,
            lineList: lineList,
            maxY: maxY,
            chartWidth: chartWidth,
            labelColor: labelColor,
            baseChartHeight: baseChartHeight,
            expand: false,
          );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        chart,
      ],
    );

    if (forcedHeight != null) {
      return SizedBox(height: forcedHeight, child: column);
    }
    return column;
  }
}

class _ResponsiveOutputChart extends StatelessWidget {
  final List<String> sections;
  final List<num> passList;
  final List<num> failList;
  final List<num> lineList;
  final double maxY;
  final double chartWidth;
  final Color labelColor;
  final double baseChartHeight;
  final bool expand;

  const _ResponsiveOutputChart({
    required this.sections,
    required this.passList,
    required this.failList,
    required this.lineList,
    required this.maxY,
    required this.chartWidth,
    required this.labelColor,
    required this.baseChartHeight,
    required this.expand,
  });

  @override
  Widget build(BuildContext context) {
    final layout = LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : baseChartHeight + 60;

        double resolvedChartHeight = baseChartHeight;
        if (availableHeight.isFinite) {
          final double maxAllowed = availableHeight - 60;
          if (maxAllowed > 0) {
            if (maxAllowed < 80) {
              resolvedChartHeight =
                  resolvedChartHeight.clamp(0.0, maxAllowed).toDouble();
              resolvedChartHeight = math.max(
                resolvedChartHeight,
                math.min(maxAllowed, 60.0),
              );
            } else {
              resolvedChartHeight =
                  resolvedChartHeight.clamp(80.0, maxAllowed).toDouble();
            }
          } else {
            final double safeUpper = math.max(0.0, availableHeight - 40);
            resolvedChartHeight = math.min(resolvedChartHeight, safeUpper);
            if (safeUpper > 0) {
              resolvedChartHeight = math.max(
                resolvedChartHeight,
                math.min(safeUpper, 40.0),
              );
            }
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              height: resolvedChartHeight + 38,
              child: Stack(
                children: List.generate(6, (i) {
                  final v = (maxY * i / 5).round();
                  final top =
                      resolvedChartHeight - (v / maxY) * resolvedChartHeight + 18;
                  return Positioned(
                    top: top,
                    left: 0,
                    right: 0,
                    child: Text(
                      '$v',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: labelColor.withOpacity(i == 0 ? 0.45 : 0.9),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: resolvedChartHeight + 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(sections.length, (idx) {
                                final pass = passList[idx];
                                final fail = failList[idx];
                                final passHeight =
                                    resolvedChartHeight * (pass / maxY);
                                final failHeight =
                                    resolvedChartHeight * (fail / maxY);

                                return SizedBox(
                                  width:
                                      (_barWidth * 2) + _barSpace + _groupSpace,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      if (pass > 0)
                                        Positioned(
                                          bottom: passHeight + 8,
                                          left: -3,
                                          width: _barWidth + 10,
                                          child: Center(
                                            child: Text(
                                              '$pass',
                                              style: TextStyle(
                                                color:
                                                    const Color(0xFF2196F3),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                height: 1,
                                                letterSpacing: .2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        child: Container(
                                          width: _barWidth + 5,
                                          height: passHeight,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2196F3),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                      if (fail > 0)
                                        Positioned(
                                          bottom: failHeight + 8,
                                          left: _barWidth + 10,
                                          width: _barWidth + 5,
                                          child: Center(
                                            child: Text(
                                              '$fail',
                                              style: TextStyle(
                                                color:
                                                    const Color(0xFFFF9800),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                height: 1,
                                                letterSpacing: .2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        bottom: 0,
                                        left: _barWidth + _barSpace,
                                        child: Container(
                                          width: _barWidth + 5,
                                          height: failHeight,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF9800),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                          SizedBox(
                            height: 28,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(sections.length, (idx) {
                                final section = sections[idx];
                                return SizedBox(
                                  width:
                                      (_barWidth * 2) + _barSpace + _groupSpace,
                                  child: Center(
                                    child: Text(
                                      section,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: labelColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 20,
                        left: 10,
                        right: 0,
                        bottom: 28,
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _LineChartPainter(
                              values: lineList.map((e) => e.toDouble()).toList(),
                              maxLineValue: 110,
                              chartHeight: resolvedChartHeight,
                              barWidth: _barWidth,
                              barSpace: _barSpace,
                              groupSpace: _groupSpace,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (expand) {
      return SizedBox.expand(child: layout);
    }
    return SizedBox(
      height: baseChartHeight + 60,
      child: layout,
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxLineValue;
  final double chartHeight;
  final double barWidth;
  final double barSpace;
  final double groupSpace;
  final Color lineColor;
  final Color dotColor;
  final Color textColor;

  _LineChartPainter({
    required this.values,
    required this.maxLineValue,
    required this.chartHeight,
    required this.barWidth,
    required this.barSpace,
    required this.groupSpace,
    this.lineColor = Colors.green,
    this.dotColor = Colors.greenAccent,
    this.textColor = Colors.greenAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = i * ((barWidth * 2) + barSpace + groupSpace) + barWidth;
      final y = chartHeight - (values[i] / maxLineValue) * chartHeight;
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        if (values[i] == 0 && values[i + 1] == 0) continue;
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    final circlePaint = Paint()..color = dotColor;
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, circlePaint);

      final valueStr = "${values[i].toStringAsFixed(1)}%";
      final textSpan = TextSpan(
        text: valueStr,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.15), blurRadius: 2),
          ],
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(points[i].dx + 6, points[i].dy - 20));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxLineValue != maxLineValue ||
        oldDelegate.chartHeight != chartHeight ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.barSpace != barSpace ||
        oldDelegate.groupSpace != groupSpace ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.textColor != textColor;
  }
}
