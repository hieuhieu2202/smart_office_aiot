import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/station_overview_controller.dart';
import '../viewmodels/station_overview_view_state.dart';

class StationDetailSection extends StatelessWidget {
  StationDetailSection({super.key, required this.controller});

  final StationOverviewController controller;
  final DateFormat _formatter = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final StationSummary? summary = controller.highlightedStation.value;
      final StationOverviewDashboardViewState? state = controller.dashboard.value;
      final List<StationDetailData> details = state?.detailData ?? const <StationDetailData>[];
      final bool isLoading = controller.isLoadingStation.value;

      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Station details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (summary == null)
                Text(
                  'Select a station to view detailed tracking information.',
                  style: theme.textTheme.bodyMedium,
                )
              else ...<Widget>[
                Text(
                  '${summary.productName} • ${summary.groupName} • ${summary.data.stationName}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: StationDetailType.values.map((type) {
                    return ChoiceChip(
                      label: Text(type.apiKey.replaceAll('_', ' ')),
                      selected: controller.selectedDetailType.value == type,
                      onSelected: (_) => controller.changeDetailType(type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                if (isLoading) const LinearProgressIndicator(),
                if (!isLoading && details.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No detail data available for the selected criteria.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else if (details.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const <DataColumn>[
                        DataColumn(label: Text('EMP NO')),
                        DataColumn(label: Text('MO')),
                        DataColumn(label: Text('MODEL')),
                        DataColumn(label: Text('SERIAL')),
                        DataColumn(label: Text('LINE')),
                        DataColumn(label: Text('GROUP')),
                        DataColumn(label: Text('STATION')),
                        DataColumn(label: Text('ERROR')),
                        DataColumn(label: Text('DESCRIPTION')),
                        DataColumn(label: Text('CYCLE')),
                        DataColumn(label: Text('IN STATION')),
                      ],
                      rows: details
                          .map(
                            (detail) => DataRow(
                              cells: <DataCell>[
                                DataCell(Text(detail.empNo)),
                                DataCell(Text(detail.moNumber)),
                                DataCell(Text(detail.modelName)),
                                DataCell(Text(detail.serialNumber)),
                                DataCell(Text(detail.lineName)),
                                DataCell(Text(detail.groupName)),
                                DataCell(Text(detail.stationName)),
                                DataCell(Text(detail.errorCode)),
                                DataCell(Text(detail.description)),
                                DataCell(Text(detail.cycleTime)),
                                DataCell(Text(_format(detail.inStationTime))),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    });
  }

  String _format(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _formatter.format(dateTime.toLocal());
  }
}
