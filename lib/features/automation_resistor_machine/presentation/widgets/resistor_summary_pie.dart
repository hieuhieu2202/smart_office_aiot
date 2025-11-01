import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../viewmodels/resistor_dashboard_view_state.dart';

class ResistorSummaryPie extends StatelessWidget {
  const ResistorSummaryPie({
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

    return SfCircularChart(
      backgroundColor: Colors.transparent,
      title: ChartTitle(
        text: title,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
        alignment: ChartAlignment.near,
        borderWidth: 0,
      ),
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: TextStyle(color: Colors.white70),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      annotations: <CircularChartAnnotation>[
        CircularChartAnnotation(
          widget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.1,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                formatter.format(total),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ],
      series: <DoughnutSeries<ResistorPieSlice, String>>[
        DoughnutSeries<ResistorPieSlice, String>(
          dataSource: slices,
          radius: '95%',
          innerRadius: '65%',
          startAngle: 270,
          endAngle: 270,
          explode: false,
          cornerStyle: CornerStyle.bothCurve,
          xValueMapper: (slice, _) => slice.label,
          yValueMapper: (slice, _) => slice.value,
          pointColorMapper: (slice, _) => Color(slice.color),
          dataLabelMapper: (slice, _) => slice.label,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: Colors.white),
            labelPosition: ChartDataLabelPosition.outside,
            connectorLineSettings: ConnectorLineSettings(
              color: Colors.white54,
              width: 1,
            ),
          ),
        ),
      ],
    );
  }
}
