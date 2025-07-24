import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../config/global_color.dart';
import '../../controller/yield_report_controller.dart';

class YieldReportScreen extends StatelessWidget {
  const YieldReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(YieldReportController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;

    return Obx(() => Scaffold(
          appBar: AppBar(
            title: const Text('Yield Rate Report'),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.fetchReport,
              ),
            ],
          ),
          backgroundColor:
              isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
          body: controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Card(
                        color: bgColor,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Obx(() => _DateTimeField(
                                      label: 'From',
                                      value: controller.startDateTime.value,
                                      isDark: isDark,
                                      onChanged: controller.updateStart,
                                    )),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Obx(() => _DateTimeField(
                                      label: 'To',
                                      value: controller.endDateTime.value,
                                      isDark: isDark,
                                      onChanged: controller.updateEnd,
                                    )),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: GlobalColors.accentByIsDark(isDark),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: controller.fetchReport,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.filter_list, color: Colors.white),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: controller.dataNickNames.length,
                        itemBuilder: (context, idx) {
                          final nick = controller.dataNickNames[idx];
                          final models = nick['DataModelNames'] as List? ?? [];
                          return Card(
                            color: bgColor,
                            child: ExpansionTile(
                              title: Text(nick['NickName'] ?? ''),
                              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                              childrenPadding: const EdgeInsets.only(bottom: 12),
                              maintainState: true,
                              children: models.map<Widget>((m) {
                                final stations = m['DataStations'] as List? ?? [];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m['ModelName'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          headingRowColor: MaterialStateProperty.all(
                                              GlobalColors.accentByIsDark(isDark).withOpacity(0.1)),
                                          border: TableBorder.all(
                                            width: 0.5,
                                            color: isDark ? Colors.white24 : Colors.black26,
                                          ),
                                          columns: [
                                            const DataColumn(label: Text('Station')),
                                            ...controller.dates
                                                .map((d) => DataColumn(label: Text(d)))
                                                .toList(),
                                          ],
                                          rows: stations.map<DataRow>((st) {
                                            final values = (st['Data'] as List? ?? [])
                                                .map((e) => e.toString())
                                                .toList();
                                            return DataRow(cells: [
                                              DataCell(Text(st['Station'] ?? '')),
                                              ...values
                                                  .map((v) => DataCell(Text(v)))
                                                  .toList(),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ));
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool isDark;

  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  Future<void> _select(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(value.year - 1),
      lastDate: DateTime(value.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: GlobalColors.accentDark,
                    surface: GlobalColors.cardDarkBg,
                    onSurface: GlobalColors.darkPrimaryText,
                  )
                : const ColorScheme.light(
                    primary: GlobalColors.accentLight,
                    surface: GlobalColors.cardLightBg,
                    onSurface: GlobalColors.lightPrimaryText,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: GlobalColors.accentDark,
                    surface: GlobalColors.cardDarkBg,
                    onSurface: GlobalColors.darkPrimaryText,
                  )
                : const ColorScheme.light(
                    primary: GlobalColors.accentLight,
                    surface: GlobalColors.cardLightBg,
                    onSurface: GlobalColors.lightPrimaryText,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _select(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
        child: Text(
          '$label: ${DateFormat('yyyy/MM/dd HH:mm').format(value)}',
          style: TextStyle(
            color:
                isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText,
          ),
        ),
      ),
    );
  }
}
