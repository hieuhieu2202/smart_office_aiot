import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../controller/racks_monitor_controller.dart';

class YieldRateGauge extends StatelessWidget {
  const YieldRateGauge({super.key, required this.controller});
  final GroupMonitorController controller;

  @override
  Widget build(BuildContext context) {
    final yr = controller.kpiYr.clamp(0, 100).toDouble();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // màu theo theme
    final baseColor   = isDark ? const Color(0xFF233140) : Colors.grey.shade300;
    final activeColor = isDark ? const Color(0xFF46B85F) : const Color(0xFF4CAF50);
    final labelColor  = Theme.of(context).textTheme.bodyMedium?.color
        ?? (isDark ? Colors.white : Colors.black87);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YIELD RATE',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            // rộng hơn cao để có khoảng trống dưới cho “0” và “100”
            width: 240, height: 150,
            child: CustomPaint(
              painter: _GaugePainter(
                value: yr,
                baseColor: baseColor,
                activeColor: activeColor,
                labelColor: labelColor,
                thickness: 14,        // mỏng hơn → đỡ đè chữ
                sideLabelPadding: 8,  // khoảng cách “0/100” với cung
              ),
              // đặt % hơi cao lên để nằm gọn trong lòng cung
              child: LayoutBuilder(
                builder: (context, c) => Padding(
                  padding: const EdgeInsets.only(top: 8), // đẩy text lên chút
                  child: Align(
                    alignment: const Alignment(0, -0.05),
                    child: Text(
                      '${yr.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;      // 0..100
  final Color baseColor;
  final Color activeColor;
  final Color labelColor;
  final double thickness;
  final double sideLabelPadding;

  _GaugePainter({
    required this.value,
    required this.baseColor,
    required this.activeColor,
    required this.labelColor,
    this.thickness = 14,
    this.sideLabelPadding = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Tâm ở giữa đáy, bán kính tính để không bị cắt viền
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = math.min(size.width / 2 - 8, size.height - 16);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = baseColor;

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = activeColor;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // nền 180°
    canvas.drawArc(rect, math.pi, math.pi, false, base);

    // phần active theo %
    final sweep = (value.clamp(0, 100) / 100) * math.pi;
    canvas.drawArc(rect, math.pi, sweep, false, active);

    // ===== Nhãn “0” và “100” đặt DƯỚI mép cung =====
    final tp0 = TextPainter(
      text: TextSpan(
        text: '0',
        style: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tp100 = TextPainter(
      text: TextSpan(
        text: '100',
        style: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();


    final y = center.dy + thickness / 2 + sideLabelPadding;
    final left = Offset(rect.left + sideLabelPadding, y - tp0.height / 2);
    final right =
    Offset(rect.right - sideLabelPadding - tp100.width, y - tp100.height / 2);

    tp0.paint(canvas, left);
    tp100.paint(canvas, right);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) {
    return old.value != value ||
        old.baseColor != baseColor ||
        old.activeColor != activeColor ||
        old.labelColor != labelColor ||
        old.thickness != thickness ||
        old.sideLabelPadding != sideLabelPadding;
  }
}
