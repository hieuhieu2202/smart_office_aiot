import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/rack_entities.dart';
import '../controllers/rack_monitor_controller.dart';

/// Right panel showing analytics and insights
class RackInsightsColumn extends StatelessWidget {
  final RackMonitorController controller;

  const RackInsightsColumn({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = controller.data.value;
      if (data == null) {
        return const SizedBox.shrink();
      }

      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF22365b).withValues(alpha: 0.31),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFF22365b)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary stats
            _buildSummaryStats(data.quantitySummary),

            const Divider(color: Colors.white24, height: 24),

            // Pass by Model Chart
            _buildSectionTitle('PASS BY MODEL'),
            const SizedBox(height: 8),
            _buildPassByModelChart(),

            const Divider(color: Colors.white24, height: 24),

            // Slot Status Chart
            _buildSectionTitle('SLOT STATUS'),
            const SizedBox(height: 8),
            _buildSlotStatusChart(),

            const Divider(color: Colors.white24, height: 24),

            // Yield Rate Gauge
            _buildSectionTitle('YIELD RATE'),
            const SizedBox(height: 8),
            _buildYieldRateGauge(data.quantitySummary.yr),

            const Divider(color: Colors.white24, height: 24),

            // WIP and Total Pass
            _buildWipAndPass(data.quantitySummary),
          ],
        ),
      );
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildSummaryStats(QuantitySummary summary) {
    return Column(
      children: [
        _buildStatRow('INPUT', summary.input, 'PCS'),
        _buildStatRow('PASS', summary.totalPass, 'PCS'),
        _buildStatRow('FAIL', summary.fail, 'PCS'),
        _buildStatRow('FPR', summary.fpr, '%', decimals: 2),
        _buildStatRow('YR', summary.yr, '%', decimals: 2),
      ],
    );
  }

  Widget _buildStatRow(String label, num value, String suffix, {int decimals = 0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${decimals > 0 ? value.toStringAsFixed(decimals) : value.toString()} $suffix',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassByModelChart() {
    final items = controller.passByModelAgg;
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No data',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      );
    }

    final maxValue = items.fold<int>(0, (max, item) => item.totalPass > max ? item.totalPass : max);

    return Column(
      children: items.take(5).map((item) {
        final percentage = maxValue > 0 ? item.totalPass / maxValue : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.model,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    item.totalPass.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForIndex(items.indexOf(item)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlotStatusChart() {
    final statusCount = controller.slotStatusCount;
    if (statusCount.isEmpty) {
      return const Center(
        child: Text(
          'No data',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      );
    }

    final total = statusCount.values.fold<int>(0, (sum, count) => sum + count);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statusCount.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(entry.key).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _getStatusColor(entry.key),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: _getStatusColor(entry.key),
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.key}: ${entry.value} (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYieldRateGauge(double yr) {
    final color = _getYRColor(yr);

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background arc
              CustomPaint(
                size: const Size(100, 100),
                painter: GaugePainter(
                  value: yr / 100,
                  color: color,
                ),
              ),
              // Center text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${yr.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWipAndPass(QuantitySummary summary) {
    return Column(
      children: [
        _buildStatRow('WIP', summary.wip, 'PCS'),
        _buildStatRow('PASS', summary.totalPass, 'PCS'),
      ],
    );
  }

  Color _getColorForIndex(int index) {
    const colors = [
      Color(0xFF4DA3FF), // blue
      Color(0xFF7F5CFF), // purple
      Color(0xFF2ECC71), // green
      Color(0xFFFFA726), // orange
      Color(0xFFE74C3C), // red
      Color(0xFF26C6DA), // cyan
    ];
    return colors[index % colors.length];
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PASS':
        return const Color(0xFF00c853);
      case 'FAIL':
        return const Color(0xFFff3b30);
      case 'TESTING':
        return const Color(0xFF1e88e5);
      case 'WAITING':
        return const Color(0xFFffc107);
      case 'HOLD':
        return const Color(0xFF9c27b0);
      case 'OFFLINE':
      default:
        return const Color(0xFF9e9e9e);
    }
  }

  Color _getYRColor(double yr) {
    if (yr >= 97) return const Color(0xFF00c853);
    if (yr >= 90) return const Color(0xFFffc107);
    if (yr >= 70) return const Color(0xFFff9800);
    return const Color(0xFFff3b30);
  }
}

/// Custom painter for gauge chart
class GaugePainter extends CustomPainter {
  final double value;
  final Color color;

  GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -3.14 * 0.75, // Start angle
      3.14 * 1.5,   // Sweep angle
      false,
      bgPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -3.14 * 0.75,
      3.14 * 1.5 * value,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

