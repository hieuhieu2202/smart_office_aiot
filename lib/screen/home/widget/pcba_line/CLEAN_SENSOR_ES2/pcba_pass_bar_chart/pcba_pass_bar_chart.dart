import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../controller/pcba_line_controller.dart';
import 'pcba_pass_detail_screen.dart';

// ----- Config -----
const double _barWidth         = 20.0;
const double _labelFontSize    = 12.0;
const double _labelHeight      = 16.0;
const double _labelPad         = 4.0;
const double _bottomReserve    = 24.0;
const double _bottomSafePad    = 2.0;
const double _outsideIfShortPx = 54.0;
const double _outsideOffset    = 14.0;

class PcbaPassBarChart extends StatelessWidget {
  final PcbaLineDashboardController controller;
  const PcbaPassBarChart({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.loading.value) return const Center(child: CircularProgressIndicator());
      if (controller.passFailPoints.isEmpty) return const Center(child: Text('No data'));

      final groups = <BarChartGroupData>[];
      final labels = <String>[];
      double maxY = 0;

      for (int i = 0; i < controller.passFailPoints.length; i++) {
        final p = controller.passFailPoints[i];
        final y = p.pass.toDouble();
        if (y > maxY) maxY = y;

        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: y,
                width: _barWidth,
                color: Colors.greenAccent, // GIỮ NGUYÊN màu cột
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
        labels.add(DateFormat('MM/dd').format(p.date));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pass Quantity',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black, // ✅ theo theme
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.8,
            child: LayoutBuilder(builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              final n = groups.length;

              final chartMaxY = maxY * (1 + (_labelHeight + _labelPad) / h + 0.05);

              return Stack(children: [
                BarChart(
                  BarChartData(
                    maxY: chartMaxY,
                    barGroups: groups,
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: true,
                      horizontalInterval: null,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: isDark ? const Color(0x22FFFFFF) : const Color(0x22000000), // ✅
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (v) => FlLine(
                        color: isDark ? const Color(0x22FFFFFF) : const Color(0x22000000), // ✅
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            final i = v.toInt();
                            return Text(
                              (i >= 0 && i < labels.length) ? labels[i] : '',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black, // ✅ theo theme
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent && response?.spot != null) {
                          final idx = response!.spot!.touchedBarGroupIndex;
                          final tapped = controller.passFailPoints[idx];
                          Get.to(() => PcbaPassDetailScreen(
                            controller: controller,
                            selectedDate: tapped.date,
                          ));
                        }
                      },
                    ),
                  ),
                ),

                // Overlay labels (giữ logic, đổi màu theo theme)
                IgnorePointer(
                  child: Stack(
                    children: List.generate(n, (i) {
                      final y = controller.passFailPoints[i].pass.toDouble();

                      // tâm cột (spaceAround)
                      final centerX = w * ((i + 0.5) / n);

                      final barTopPx    = (1 - (y / chartMaxY)) * h;
                      final barHeightPx = h - barTopPx;

                      // ranh giới trên của vùng ngày
                      final bottomSafeTop = h - _bottomReserve - _labelHeight - _bottomSafePad;

                      // vị trí trong/ngoài
                      final insideTop  = barTopPx + _labelPad;
                      final outsideTop = barTopPx - _labelHeight - _labelPad - _outsideOffset;

                      final isShortBar = barHeightPx < _outsideIfShortPx;

                      final bool canPlaceInside =
                          !isShortBar &&
                              barHeightPx >= (_labelHeight + _labelPad * 2) &&
                              insideTop <= bottomSafeTop;

                      double labelTop =
                      (y == 0) ? bottomSafeTop : (canPlaceInside ? insideTop : outsideTop);
                      // bảo vệ vùng ngày + không cho vượt top
                      labelTop = labelTop.clamp(0, bottomSafeTop);

                      return Positioned(
                        left: centerX - (_barWidth / 2),
                        top: labelTop,
                        child: SizedBox(
                          width: _barWidth,
                          height: _labelHeight,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${y.toInt()}',
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87, // ✅ theo theme
                                  fontSize: _labelFontSize,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ]);
            }),
          ),
        ],
      );
    });
  }
}
