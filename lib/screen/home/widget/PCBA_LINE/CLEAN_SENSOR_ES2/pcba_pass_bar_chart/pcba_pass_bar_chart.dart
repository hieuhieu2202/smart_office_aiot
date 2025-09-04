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
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
        labels.add(DateFormat('MM/dd').format(p.date));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Pass Quantity',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
        ],
      ).copyWith(children: [
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
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) {
                          final i = v.toInt();
                          return Text(
                            (i >= 0 && i < labels.length) ? labels[i] : '',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
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
                    touchCallback: (e, resp) {
                      if (e.isInterestedForInteractions && resp?.spot != null) {
                        final idx = resp!.spot!.touchedBarGroupIndex;
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

              // Overlay labels
              IgnorePointer(
                child: Stack(
                  children: List.generate(n, (i) {
                    final y = controller.passFailPoints[i].pass.toDouble();

                    // tâm cột (spaceAround)
                    final centerX = w * ((i + 0.5) / n);

                    final barTopPx    = (1 - (y / chartMaxY)) * h;
                    final barHeightPx = h - barTopPx;

                    // ranh giới trên của vùng ngày
                    final bottomSafeTop =
                        h - _bottomReserve - _labelHeight - _bottomSafePad;

                    // vị trí trong/ngoài
                    final insideTop  = barTopPx + _labelPad;
                    // đẩy ra ngoài và thêm offset để nằm cao hơn đỉnh cột
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
                              style: const TextStyle(
                                color: Colors.white,
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
      ]);
    });
  }
}

extension _ColumnAdd on Column {
  Column copyWith({List<Widget>? children}) =>
      Column(crossAxisAlignment: crossAxisAlignment, children: [...this.children, ...?children]);
}
