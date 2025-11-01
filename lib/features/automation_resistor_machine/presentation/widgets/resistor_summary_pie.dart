import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../viewmodels/resistor_dashboard_view_state.dart';

class ResistorSummaryPie extends StatelessWidget {
  const ResistorSummaryPie({
    super.key,
    required this.slices,
  });

  final List<ResistorPieSlice> slices;

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
      backgroundColor: Colors.transparent,
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: TextStyle(color: Colors.white70),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <DoughnutSeries<ResistorPieSlice, String>>[
        DoughnutSeries<ResistorPieSlice, String>(
          dataSource: slices,
          innerRadius: '55%',
          cornerStyle: CornerStyle.bothCurve,
          xValueMapper: (slice, _) => slice.label,
          yValueMapper: (slice, _) => slice.value,
          pointColorMapper: (slice, _) => Color(slice.color),
          dataLabelMapper: (slice, _) => slice.label,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
