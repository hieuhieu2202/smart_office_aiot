import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../viewmodels/resistor_dashboard_view_state.dart';

class ResistorFailDistributionChart extends StatelessWidget {
  const ResistorFailDistributionChart({
    super.key,
    required this.slices,
    required this.total,
    this.title = 'FAIL DISTRIBUTION',
  });

  final List<ResistorPieSlice> slices;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    final data = slices.isEmpty
        ? const [ResistorPieSlice(label: 'N/A', value: 0, color: 0xFF00FFE7)]
        : slices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
            ),
            const Spacer(),
            Text(
              'Total: ${formatter.format(total)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SfCartesianChart(
            backgroundColor: Colors.transparent,
            isTransposed: true,
            plotAreaBorderWidth: 0,
            tooltipBehavior: TooltipBehavior(enable: true, header: ''),
            legend: const Legend(isVisible: false),
            primaryXAxis: NumericAxis(
              axisLine: const AxisLine(color: Colors.white24),
              majorGridLines: const MajorGridLines(color: Color(0x2200FFFF)),
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
              numberFormat: NumberFormat.compact(),
            ),
            primaryYAxis: CategoryAxis(
              axisLine: const AxisLine(width: 0),
              majorGridLines: const MajorGridLines(width: 0),
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            series: <BarSeries<ResistorPieSlice, String>>[
              BarSeries<ResistorPieSlice, String>(
                dataSource: data,
                xValueMapper: (slice, _) => slice.label,
                yValueMapper: (slice, _) => slice.value,
                pointColorMapper: (slice, _) => Color(slice.color),
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(10)),
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  textStyle: TextStyle(color: Colors.white),
                  labelAlignment: ChartDataLabelAlignment.middle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
