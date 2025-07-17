import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../../config/global_color.dart';

class PTHDashboardOutputChart extends StatelessWidget {
  final Map data;

  const PTHDashboardOutputChart({super.key, required this.data});

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

    // Chuẩn hóa data
    final sections =
        output.map((e) => (e['section'] ?? e['SECTION']).toString()).toList();
    final passList =
        output.map((e) => (e['pass'] ?? e['PASS'] ?? 0) as num).toList();
    final failList =
        output.map((e) => (e['fail'] ?? e['FAIL'] ?? 0) as num).toList();
    final lineList =
        output
            .map((e) => (e['yr'] ?? e['YR'] ?? 0) as num)
            .toList(); // ví dụ đường line là tỷ lệ YR%

    double maxY = 0;
    for (int i = 0; i < output.length; i++) {
      maxY = math.max(
        maxY,
        math.max(passList[i].toDouble(), failList[i].toDouble()),
      );
    }
    maxY = maxY < 10 ? 10 : maxY * 1.12;

    const barWidth = 20.0;
    const barSpace = 12.0;
    const groupSpace = 30.0;
    final chartWidth = math.max(
      350.0,
      sections.length * (barWidth * 2 + barSpace + groupSpace) + 10,
    );
    final chartHeight = maxY < 30 ? 120.0 : math.min(maxY * 2.7, 220.0);

    return Card(
      color: bgColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề & legend
            Padding(
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
                  _legendDot(const Color(0xFF2196F3)),
                  const SizedBox(width: 4),
                  Text(
                    "PASS",
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 14),
                  _legendDot(const Color(0xFFFF9800)),
                  const SizedBox(width: 4),
                  Text(
                    "FAIL",
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 14),
                  _legendDot(Colors.green),
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
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trục Y cố định
                SizedBox(
                  width: 36,
                  height: chartHeight + 38,
                  child: Stack(
                    children: List.generate(6, (i) {
                      final v = (maxY * i / 5).round();
                      final top = chartHeight - (v / maxY) * chartHeight + 18;
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
                // Chart scroll ngang
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: chartWidth,
                      child: Stack(
                        children: [
                          // 1. Bar chart + số đỉnh
                          Column(
                            children: [
                              SizedBox(
                                height: chartHeight+20,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(sections.length, (
                                    idx,
                                  ) {
                                    final pass = passList[idx];
                                    final fail = failList[idx];
                                    final passHeight =
                                        chartHeight * (pass / maxY);
                                    final failHeight =
                                        chartHeight * (fail / maxY);

                                    return SizedBox(
                                      width:
                                          (barWidth * 2) +
                                          barSpace +
                                          groupSpace,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Số trên đỉnh bar (PASS)
                                          if (pass > 0)
                                            Positioned(
                                              bottom: passHeight + 8,
                                              left: -3,
                                              width: barWidth + 10,
                                              child: Center(
                                                child: Text(
                                                  '$pass',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF2196F3,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    height: 1,
                                                    letterSpacing: .2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // Bar PASS
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            child: Container(
                                              width: barWidth+5,
                                              height: passHeight,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2196F3),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                          ),
                                          // Số trên đỉnh bar (FAIL)
                                          if (fail > 0)
                                            Positioned(
                                              bottom: failHeight + 8,
                                              left: barWidth + 10,
                                              width: barWidth + 5,
                                              child: Center(
                                                child: Text(
                                                  '$fail',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFFFF9800,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    height: 1,
                                                    letterSpacing: .2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // Bar FAIL
                                          Positioned(
                                            bottom: 0,
                                            left: barWidth + barSpace,
                                            child: Container(
                                              width: barWidth+5,
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
                              // Label dưới trục X
                              SizedBox(
                                height: 28,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(sections.length, (
                                    idx,
                                  ) {
                                    final section = sections[idx];
                                    return SizedBox(
                                      width:
                                          (barWidth * 2) +
                                          barSpace +
                                          groupSpace,
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
                          // 2. Line chart (ví dụ vẽ YR%)
                          Positioned(
                            top: 20,
                            left: 10,
                            right: 0,
                            bottom: 28,
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _LineChartPainter(
                                  values: lineList.map((e) => e.toDouble()).toList(),
                                  maxLineValue: 110,   // <<< Đúng nè! (Luôn là 100 cho %)
                                  chartHeight: chartHeight,
                                  barWidth: barWidth,
                                  barSpace: barSpace,
                                  groupSpace: groupSpace,
                                ),
                              )
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.5),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxLineValue;    // Luôn là 100 cho %!
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

    // Vẽ đường nối giữa các điểm
    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        // Nếu một trong hai giá trị là 0 (không dữ liệu), bỏ qua đoạn line
        if (values[i] == 0 && values[i + 1] == 0) continue;
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    // Vẽ điểm tròn và số %
    final circlePaint = Paint()..color = dotColor;
    for (int i = 0; i < points.length; i++) {
      // Không vẽ dot cho điểm không dữ liệu nếu muốn
      canvas.drawCircle(points[i], 4, circlePaint);

      // Vẽ số % ở trên, lệch phải của điểm
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

