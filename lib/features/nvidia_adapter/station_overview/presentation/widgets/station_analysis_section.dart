import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../controllers/station_overview_controller.dart';
import '../viewmodels/station_overview_view_state.dart';

class StationAnalysisSection extends StatelessWidget {
  const StationAnalysisSection({super.key, required this.controller});

  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final StationOverviewDashboardViewState? state = controller.dashboard.value;
      if (state == null) {
        return const SizedBox.shrink();
      }
      final bool hasStationSelection = controller.highlightedStation.value != null;
      final List<StationChartPoint> failSeries = state.failQuantitySeries;
      final List<StationChartPoint> errorSeries =
          hasStationSelection ? state.analysisByErrorCode() : const <StationChartPoint>[];
      final List<StationTrendPoint> trendSeries =
          hasStationSelection ? state.analysisTrendByDate() : const <StationTrendPoint>[];

      return LayoutBuilder(
        builder: (context, constraints) {
          final bool isVertical = constraints.maxWidth < 900;
          final children = <Widget>[
            _ChartCard(
              title: 'Fail quantity by station',
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ChartSeries<StationChartPoint, String>>[
                  ColumnSeries<StationChartPoint, String>(
                    dataSource: failSeries,
                    xValueMapper: (StationChartPoint point, _) => point.category,
                    yValueMapper: (StationChartPoint point, _) => point.value,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
            _ChartCard(
              title: 'Error codes (${hasStationSelection ? controller.highlightedStation.value!.data.stationName : 'select station'})',
              child: errorSeries.isEmpty
                  ? _EmptyChartPlaceholder(
                      message: hasStationSelection
                          ? 'No error codes for selected station'
                          : 'Select a station to view error codes',
                    )
                  : SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <ChartSeries<StationChartPoint, String>>[
                        ColumnSeries<StationChartPoint, String>(
                          dataSource: errorSeries,
                          xValueMapper: (StationChartPoint point, _) => point.category,
                          yValueMapper: (StationChartPoint point, _) => point.value,
                          dataLabelSettings: const DataLabelSettings(isVisible: true),
                        ),
                      ],
                    ),
            ),
            _ChartCard(
              title: 'Fail trend',
              child: trendSeries.isEmpty
                  ? _EmptyChartPlaceholder(
                      message: hasStationSelection
                          ? 'No trend data available'
                          : 'Select a station to view fail trend',
                    )
                  : SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <ChartSeries<StationTrendPoint, String>>[
                        LineSeries<StationTrendPoint, String>(
                          dataSource: trendSeries,
                          xValueMapper: (StationTrendPoint point, _) => point.category,
                          yValueMapper: (StationTrendPoint point, _) => point.value,
                          markerSettings: const MarkerSettings(isVisible: true),
                        ),
                      ],
                    ),
            ),
          ];

          if (isVertical) {
            return Column(
              children: children
                  .map((widget) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: widget,
                      ))
                  .toList(),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .map((widget) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: widget,
                      ),
                    ))
                .toList(),
          );
        },
      );
    });
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  const _EmptyChartPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
