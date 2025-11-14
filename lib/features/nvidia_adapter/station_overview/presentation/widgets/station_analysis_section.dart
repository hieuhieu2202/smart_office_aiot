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
    final ThemeData theme = Theme.of(context);
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
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isVertical = constraints.maxWidth < 1100;
          final List<Widget> panels = <Widget>[
            _ChartCard(
              title: 'Fail quantity by station',
              child: _buildColumnChart(failSeries, theme),
            ),
            _ChartCard(
              title:
                  'Error codes (${hasStationSelection ? controller.highlightedStation.value!.data.stationName : 'select station'})',
              child: errorSeries.isEmpty
                  ? _EmptyChartPlaceholder(
                      message: hasStationSelection
                          ? 'No error codes for selected station'
                          : 'Select a station to view error codes',
                    )
                  : _buildColumnChart(errorSeries, theme, paletteColor: const Color(0xFFFF7043)),
            ),
            _ChartCard(
              title: 'Fail trend',
              child: trendSeries.isEmpty
                  ? _EmptyChartPlaceholder(
                      message: hasStationSelection
                          ? 'No trend data available'
                          : 'Select a station to view fail trend',
                    )
                  : _buildLineChart(trendSeries, theme),
            ),
          ];

          if (isVertical) {
            return Column(
              children: panels
                  .map(
                    (Widget widget) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: widget,
                    ),
                  )
                  .toList(),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(panels.length, (int index) {
              final Widget panel = panels[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == panels.length - 1 ? 0 : 20),
                  child: panel,
                ),
              );
            }),
          );
        },
      );
    });
  }

  Widget _buildColumnChart(List<StationChartPoint> series, ThemeData theme,
      {Color paletteColor = const Color(0xFF64B5F6)}) {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBackgroundColor: Colors.transparent,
      primaryXAxis: CategoryAxis(
        axisLine: const AxisLine(color: Colors.white30),
        labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(color: Colors.white30),
        labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        majorGridLines: const MajorGridLines(color: Color(0x33FFFFFF)),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<StationChartPoint, String>>[
        ColumnSeries<StationChartPoint, String>(
          dataSource: series,
          xValueMapper: (StationChartPoint point, _) => point.category,
          yValueMapper: (StationChartPoint point, _) => point.value,
          color: paletteColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<StationTrendPoint> series, ThemeData theme) {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBackgroundColor: Colors.transparent,
      primaryXAxis: CategoryAxis(
        axisLine: const AxisLine(color: Colors.white30),
        labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(color: Colors.white30),
        labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        majorGridLines: const MajorGridLines(color: Color(0x33FFFFFF)),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<StationTrendPoint, String>>[
        LineSeries<StationTrendPoint, String>(
          color: const Color(0xFF42A5F5),
          dataSource: series,
          xValueMapper: (StationTrendPoint point, _) => point.category,
          yValueMapper: (StationTrendPoint point, _) => point.value,
          markerSettings: const MarkerSettings(isVisible: true),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        gradient: LinearGradient(
          colors: <Color>[
            Colors.white.withOpacity(0.07),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 260, child: child),
        ],
      ),
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  const _EmptyChartPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
    );
  }
}
