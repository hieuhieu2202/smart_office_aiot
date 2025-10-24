import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controller/pcba_line_controller.dart';

class PcbaYieldRateLineChart extends StatefulWidget {
  final PcbaLineDashboardController controller;
  const PcbaYieldRateLineChart({super.key, required this.controller});

  @override
  State<PcbaYieldRateLineChart> createState() => _PcbaYieldRateLineChartState();
}

class _PcbaYieldRateLineChartState extends State<PcbaYieldRateLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = controller.yieldPoints;
    if (data.isEmpty) return const Center(child: Text('No data'));

    final spots = <FlSpot>[];
    final labels = <String>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].yieldRate.toDouble()));
      labels.add(DateFormat('MM/dd').format(data[i].date));
    }

    final double minX = -0.9;
    final double maxX = (spots.length - 1).toDouble() + 0.9;
    final maxPoint = spots.reduce((a, b) => a.y > b.y ? a : b);
    final maxValue = maxPoint.y.toStringAsFixed(2);

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = (math.sin(_glowController.value * 2 * math.pi) + 1) / 2;
        final glowColor = Color.lerp(
          const Color(0xFF9B5FFF).withOpacity(0.4),
          const Color(0xFFB47AFF).withOpacity(0.8),
          glow,
        )!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yield Rate',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF330066),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: isDark
                    ? const [Shadow(color: Color(0x408000FF), blurRadius: 6)]
                    : const [Shadow(color: Colors.white70, blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0E0A14), const Color(0xFF1A0F26)]
                        : [const Color(0xFFF3E8FF), const Color(0xFFE9D7FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.25)
                          : Colors.deepPurple.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: [
                    // 📈 Line chart chính
                    LineChart(
                      LineChartData(
                        minX: minX,
                        maxX: maxX,
                        minY: 0.0,
                        maxY: 102.0,
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final idx = value.round();
                                if (idx < 0 || idx >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    labels[idx],
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFE8DFFF)
                                          : const Color(0xFF4A0066),
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? const Color(0x33FFFFFF)
                                  : const Color(0x33000000),
                              width: 1,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          // 🌈 Đường chính có gradient + vùng fill + glow
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: glowColor,
                            barWidth: 3.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  glowColor.withOpacity(0.5),
                                  glowColor.withOpacity(0.15),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) =>
                            isDark ? Colors.black87 : Colors.white,
                            tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            tooltipBorderRadius: BorderRadius.circular(8),
                            getTooltipItems: (spots) {
                              return spots.map((s) {
                                final idx = s.x.toInt();
                                final date = (idx >= 0 && idx < labels.length)
                                    ? labels[idx]
                                    : '';
                                return LineTooltipItem(
                                  '📅 $date\nYield: ${s.y.toStringAsFixed(2)}%',
                                  TextStyle(
                                    color: isDark
                                        ? const Color(0xFFEFEFEF)
                                        : const Color(0xFF330033),
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        extraLinesData: ExtraLinesData(horizontalLines: [
                          HorizontalLine(
                            y: 99.0,
                            color: Colors.greenAccent,
                            strokeWidth: 1.8,
                            dashArray: const [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              labelResolver: (_) => 'Target (99%)',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),

                    // 🟧 Box highlight giá trị cao nhất
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepOrangeAccent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrangeAccent.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Text(
                          'Highest: $maxValue%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
