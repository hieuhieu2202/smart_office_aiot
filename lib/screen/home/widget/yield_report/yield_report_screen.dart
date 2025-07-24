import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          ),
          body: controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
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
        ));
  }
}
