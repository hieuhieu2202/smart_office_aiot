import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../config/global_color.dart';
import '../../controller/te_management_controller.dart';
import 'te_management_search_bar.dart';
import 'te_management_filter_panel.dart';

class TEManagementScreen extends StatefulWidget {
  TEManagementScreen({super.key});

  @override
  State<TEManagementScreen> createState() => _TEManagementScreenState();
}

class _TEManagementScreenState extends State<TEManagementScreen> {
  final TEManagementController controller = Get.put(TEManagementController());

  Color _rateColor(double v, bool isDark) {
    if (v < 90) return isDark ? Colors.redAccent : Colors.red;
    if (v < 97) return Colors.orangeAccent;
    return isDark ? Colors.greenAccent : Colors.green;
  }

  DataRow _buildRow(Map<String, dynamic> row, bool isDark) {
    double parseDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    return DataRow(cells: [
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: isDark ? Colors.blueGrey[900] : Colors.blueGrey[50],
        child: Text(row['GROUP_NAME']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      )),
      DataCell(Text(row['WIP_QTY']?.toString() ?? '')),
      DataCell(Text(row['INPUT']?.toString() ?? '')),
      DataCell(Text(row['FIRST_FAIL']?.toString() ?? '',
          style: TextStyle(color: isDark ? Colors.redAccent : Colors.red))),
      DataCell(Text(row['REPAIR_QTY']?.toString() ?? '')),
      DataCell(Text(row['FIRST_PASS']?.toString() ?? '')),
      DataCell(Text(row['PASS']?.toString() ?? '',
          style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green))),
      DataCell(Text(row['R_PASS']?.toString() ?? '')),
      DataCell(Text(row['FPR']?.toString() ?? '',
          style: TextStyle(color: _rateColor(parseDouble(row['FPR']), isDark)))),
      DataCell(Text(row['SPR']?.toString() ?? '',
          style: TextStyle(color: _rateColor(parseDouble(row['SPR']), isDark)))),
      DataCell(Text(row['YR']?.toString() ?? '',
          style: TextStyle(color: _rateColor(parseDouble(row['YR']), isDark)))),
      DataCell(Text(row['RR']?.toString() ?? '')),
    ]);
  }

  Widget _buildGroup(List<Map<String, dynamic>> group, bool isDark) {
    final modelName = group.first['MODEL_NAME']?.toString() ?? '';
    final rows = group.map((r) => _buildRow(r, isDark)).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 18, left: 11, right: 11),
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      elevation: 8,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color:
              isDark ? Colors.blueAccent.withOpacity(.4) : Colors.blueAccent.withOpacity(.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        key: PageStorageKey(modelName),
        title: Text(
          modelName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.lightBlue[100] : Colors.blue[900],
          ),
        ),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                key: PageStorageKey('scroll_$modelName'),
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable2(
                    fixedLeftColumns: 1,
                    columnSpacing: 12,
                    columns: const [
                      DataColumn2(label: Text('GROUP'), size: ColumnSize.L),
                      DataColumn2(label: Text('WIP')),
                      DataColumn2(label: Text('INPUT')),
                      DataColumn2(label: Text('FAIL')),
                      DataColumn2(label: Text('REPAIR')),
                      DataColumn2(label: Text('FIRST_PASS')),
                      DataColumn2(label: Text('PASS')),
                      DataColumn2(label: Text('R_PASS')),
                      DataColumn2(label: Text('FPR')),
                      DataColumn2(label: Text('SPR')),
                      DataColumn2(label: Text('YR')),
                      DataColumn2(label: Text('RR')),
                    ],
                    rows: rows,
                    headingRowColor: MaterialStateProperty.resolveWith(
                      (_) => isDark
                          ? Colors.blueGrey[700]
                          : Colors.blueGrey[100],
                    ),
                    dataRowColor: MaterialStateProperty.resolveWith(
                      (_) =>
                          isDark ? Colors.blueGrey[800] : Colors.white,
                    ),
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(
      () => Scaffold(
        backgroundColor:
            isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
        appBar: AppBar(
          title: const Text('TE Management'),
          centerTitle: true,
          backgroundColor:
              isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
          iconTheme: IconThemeData(
            color:
                isDark ? GlobalColors.appBarDarkText : GlobalColors.appBarLightText,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt_rounded),
              onPressed: controller.openFilterPanel,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.fetchData,
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                TEManagementSearchBar(controller: controller, isDark: isDark),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildBody(isDark),
                ),
              ],
            ),
            if (controller.filterPanelOpen.value)
              Positioned.fill(
                child: TEManagementFilterPanel(
                  show: controller.filterPanelOpen.value,
                  start: controller.startDate.value,
                  end: controller.endDate.value,
                  modelSerial: controller.modelSerial.value,
                  model: controller.model.value,
                  onApply: controller.applyFilter,
                  onClose: controller.closeFilterPanel,
                  isDark: isDark,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error.isNotEmpty) {
      return Center(child: Text(controller.error.value));
    }
    final data = controller.filteredData;
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: data.length,
      itemBuilder: (context, idx) => _buildGroup(data[idx], isDark),
    );
  }
}
