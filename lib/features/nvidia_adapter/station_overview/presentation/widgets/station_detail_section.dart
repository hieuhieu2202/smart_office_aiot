import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/station_overview_controller.dart';
import '../viewmodels/station_overview_view_state.dart';
import '../../domain/entities/station_overview_entities.dart';

class StationDetailSection extends StatelessWidget {
  StationDetailSection({super.key, required this.controller});

  final StationOverviewController controller;
  final DateFormat _formatter = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Obx(() {
      final StationSummary? summary = controller.highlightedStation.value;
      final StationOverviewDashboardViewState? state = controller.dashboard.value;
      final List<StationDetailData> details = state?.detailData ?? const <StationDetailData>[];
      final bool isLoading = controller.isLoadingStation.value;

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
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Station details',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 12),
            if (summary == null)
              Text(
                'Select a station to view detailed tracking information.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              )
            else ...<Widget>[
              Text(
                '${summary.productName} • ${summary.groupName} • ${summary.data.stationName}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: StationDetailType.values.map((StationDetailType type) {
                  final bool selected = controller.selectedDetailType.value == type;
                  return ChoiceChip(
                    label: Text(type.apiKey.replaceAll('_', ' ').toUpperCase()),
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: selected ? Colors.black : Colors.white70,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: const Color(0xFF0AA5FF),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    onSelected: (_) => controller.changeDetailType(type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const LinearProgressIndicator(
                  minHeight: 4,
                  color: Color(0xFF0AA5FF),
                  backgroundColor: Color(0x330AA5FF),
                ),
              if (!isLoading && details.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    'No detail data available for the selected criteria.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                )
              else if (details.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withOpacity(0.25),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTableTheme(
                          data: DataTableThemeData(
                            headingRowColor:
                                MaterialStateProperty.all<Color>(const Color(0x330AA5FF)),
                            dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) => states.contains(MaterialState.selected)
                                    ? const Color(0x330AA5FF)
                                    : Colors.white.withOpacity(0.02)),
                            headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                            dataTextStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
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
                                  (StationDetailData detail) => DataRow(
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
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }

  String _format(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _formatter.format(dateTime.toLocal());
  }
}
