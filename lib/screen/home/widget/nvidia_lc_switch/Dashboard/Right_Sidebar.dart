import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'Model_Pass_Tile.dart';

class RightSidebar extends StatelessWidget {
  final List<Map<String, dynamic>> passDetails;
  final int wip;
  final int pass;

  const RightSidebar({
    super.key,
    required this.passDetails,
    required this.wip,
    required this.pass,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final bgColor = isDark ? const Color(0xFF0E2A3A) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ========== MODEL PASS ==========
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Model Pass',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < passDetails.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ModelPassTile(
                      modelName: passDetails[i]['ModelName'] ?? '',
                      qty: passDetails[i]['Qty'] ?? 0,
                      colorIndex: i,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ========== WIP / PASS ==========
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildCircle("Total Wip Qty", wip, Icons.hourglass_empty),
                const SizedBox(height: 24),
                _buildCircle("Total Pass Qty", pass, Icons.local_shipping),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(String title, int value, IconData icon) {
    return Column(
      children: [
        RotatingDashedCircle(
          child: Icon(icon, size: 32, color: Colors.cyan),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$value PCS', style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

// Vòng tròn nét đứt quay xung quanh, ICON ở giữa đứng im
class RotatingDashedCircle extends StatefulWidget {
  final Widget child;
  const RotatingDashedCircle({super.key, required this.child});

  @override
  State<RotatingDashedCircle> createState() => _RotatingDashedCircleState();
}

class _RotatingDashedCircleState extends State<RotatingDashedCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ICON đứng im ở giữa; chỉ vòng tròn đứt quay
    return Stack(
      alignment: Alignment.center,
      children: [
        RotationTransition(
          turns: _ctrl,
          child: CustomPaint(
            painter: DashedCirclePainter(),
            child: const SizedBox(width: 90, height: 90),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const dashAngle = 12.0; // độ dài mỗi nét (độ)
    const gapAngle  = 12.0; // khoảng cách giữa các nét (độ)
    final radius = size.width / 2 - 3;
    final center = Offset(size.width / 2, size.height / 2);

    for (double angle = 0; angle < 360; angle += dashAngle + gapAngle) {
      final startRad = angle * math.pi / 180;
      final endRad   = (angle + dashAngle) * math.pi / 180;

      final start = Offset(
        center.dx + radius * math.cos(startRad),
        center.dy + radius * math.sin(startRad),
      );
      final end = Offset(
        center.dx + radius * math.cos(endRad),
        center.dy + radius * math.sin(endRad),
      );

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
