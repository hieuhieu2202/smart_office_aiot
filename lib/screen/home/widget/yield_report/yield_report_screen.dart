import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/global_color.dart';
import '../../controller/yield_report_controller.dart';

class YieldReportScreen extends StatelessWidget {
  const YieldReportScreen({super.key});

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 1),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(YieldReportController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;

    return Obx(() => Scaffold(
          appBar: AppBar(
            title: const Text('Yield Rate Report'),
            centerTitle: true,
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
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await _pickDateTime(
                                        context, controller.startDateTime.value);
                                    if (picked != null) {
                                      controller.updateStart(picked);
                                    }
                                  },
                                  child: Obx(() => Text(
                                        'From: ${DateFormat('yyyy/MM/dd HH:mm').format(controller.startDateTime.value)}',
                                        style: TextStyle(
                                            color: isDark
                                                ? GlobalColors.darkPrimaryText
                                                : GlobalColors.lightPrimaryText),
                                      )),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await _pickDateTime(
                                        context, controller.endDateTime.value);
                                    if (picked != null) {
                                      controller.updateEnd(picked);
                                    }
                                  },
                                  child: Obx(() => Text(
                                        'To:   ${DateFormat('yyyy/MM/dd HH:mm').format(controller.endDateTime.value)}',
                                        style: TextStyle(
                                            color: isDark
                                                ? GlobalColors.darkPrimaryText
                                                : GlobalColors.lightPrimaryText),
                                      )),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () => controller.fetchReport(),
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
