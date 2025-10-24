import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../controller/pcba_line_controller.dart';
import 'pcba_fail_detail_screen.dart';
import 'package:smart_factory/widget/animation/loading/eva_loading_view.dart';

class PcbaFailBarChart3D extends StatelessWidget {
  final PcbaLineDashboardController controller;
  const PcbaFailBarChart3D({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.loading.value) return const EvaLoadingView(size: 240);
      if (controller.passFailPoints.isEmpty) {
        return const Center(child: Text('No data'));
      }

      final points = controller.passFailPoints;
      final maxValue = points.map((e) => e.fail).reduce(math.max);
      final labels = points.map((e) => DateFormat('MM/dd').format(e.date)).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fail Quantity',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF330033),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF140814), const Color(0xFF2A0E2A)]
                      : [const Color(0xFFFFE6F7), const Color(0xFFFAD7F2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.pinkAccent.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapUp: (d) {},
                    child: CustomPaint(
                      painter: _PcbaFail3DBarPainter(
                        values: points.map((e) => e.fail.toDouble()).toList(),
                        labels: labels,
                        isDark: isDark,
                        maxValue: maxValue.toDouble(),
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _PcbaFail3DBarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final bool isDark;
  final double maxValue;

  _PcbaFail3DBarPainter({
    required this.values,
    required this.labels,
    required this.isDark,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barGap = 28.0; // tăng khoảng cách giữa các cột
    final barWidth = (size.width - (values.length + 1) * barGap) / values.length * 0.85;
    final depth = barWidth * 0.35;

    final chartHeight = size.height * 0.8;
    final chartBaseY = size.height * 0.9;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    final baseColor = isDark ? const Color(0xFFFF66CC) : const Color(0xFFD63384);

    for (int i = 0; i < values.length; i++) {
      final val = values[i];
      final barHeight = (val / maxValue) * chartHeight;
      final left = barGap + i * (barWidth + barGap);
      final bottom = chartBaseY;
      final top = bottom - barHeight;

      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);

      final topFace = Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right + depth, rect.top - depth)
        ..lineTo(rect.left + depth, rect.top - depth)
        ..close();

      final rightFace = Path()
        ..moveTo(rect.right, rect.top)
        ..lineTo(rect.right + depth, rect.top - depth)
        ..lineTo(rect.right + depth, rect.bottom - depth)
        ..lineTo(rect.right, rect.bottom)
        ..close();

      final frontFace = Path()..addRect(rect);

      // gradient 3 mặt
      final topPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            baseColor.withOpacity(0.95),
            baseColor.withOpacity(0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(topFace.getBounds());

      final rightPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            baseColor.withOpacity(0.7),
            baseColor.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rightFace.getBounds());

      final frontPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            baseColor.withOpacity(0.9),
            baseColor.withOpacity(0.55),
            baseColor.withOpacity(0.3),
          ],
          stops: const [0.0, 0.6, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(frontFace.getBounds());

      // Vẽ khối 3D
      canvas.drawPath(frontFace, frontPaint);
      canvas.drawPath(topFace, topPaint);
      canvas.drawPath(rightFace, rightPaint);
      canvas.drawShadow(frontFace, baseColor.withOpacity(0.4), 6, false);

      // Badge hiển thị số
      final label = val.toInt().toString();
      final labelText = TextSpan(
        text: label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: isDark ? Colors.black : Colors.white,
        ),
      );
      textPainter.text = labelText;
      textPainter.layout();

      final badgeW = textPainter.width + 16;
      final badgeH = 20.0;
      final badgeX = rect.left + (barWidth - badgeW) / 2;
      final badgeY = rect.top - depth - badgeH - 4;

      final badgeR = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(999),
      );

      final badgePaint = Paint()
        ..shader = LinearGradient(
          colors: [baseColor, baseColor.withOpacity(0.6)],
        ).createShader(badgeR.outerRect);
      canvas.drawRRect(badgeR, badgePaint);
      textPainter.paint(canvas, Offset(badgeX + 8, badgeY + 3));

      // Nhãn ngày
      final dateText = TextSpan(
        text: labels[i],
        style: TextStyle(
          fontSize: 10,
          color: isDark
              ? Colors.white.withOpacity(0.8)
              : Colors.black.withOpacity(0.7),
        ),
      );
      textPainter.text = dateText;
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(rect.left + (barWidth - textPainter.width) / 2, chartBaseY + 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
