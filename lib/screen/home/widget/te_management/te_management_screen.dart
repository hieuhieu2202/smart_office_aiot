import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/global_color.dart';
import '../../controller/te_management_controller.dart';

class TEManagementScreen extends StatelessWidget {
  TEManagementScreen({super.key});

  final TEManagementController controller = Get.put(TEManagementController());

  Color _rateColor(double v, bool isDark) {
    if (v < 90) return isDark ? Colors.redAccent : Colors.red;
    if (v < 97) return Colors.orangeAccent;
    return isDark ? Colors.greenAccent : Colors.green;
  }

  DataRow _buildRow(Map<String, dynamic> row, bool isDark) {
    double parseDouble(dynamic v) =>
        double.tryParse(v?.toString() ?? '') ?? 0.0;
    return DataRow(cells: [
      DataCell(Text(row['MODEL_NAME']?.toString() ?? '')),
      DataCell(Text(row['GROUP_NAME']?.toString() ?? '')),
      DataCell(Text(row['INPUT']?.toString() ?? '')),
      DataCell(Text(row['PASS']?.toString() ?? '',
          style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green))),
      DataCell(Text(row['FIRST_FAIL']?.toString() ?? '',
          style: TextStyle(color: isDark ? Colors.redAccent : Colors.red))),
      DataCell(Text(row['FPR']?.toString() ?? '',
          style: TextStyle(
              color: _rateColor(parseDouble(row['FPR']), isDark))),),
      DataCell(Text(row['SPR']?.toString() ?? '',
          style: TextStyle(
              color: _rateColor(parseDouble(row['SPR']), isDark))),),
      DataCell(Text(row['YR']?.toString() ?? '',
          style: TextStyle(
              color: _rateColor(parseDouble(row['YR']), isDark))),),
      DataCell(Text(row['RR']?.toString() ?? '')),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
      appBar: AppBar(
        title: const Text('TE Management'),
        centerTitle: true,
        backgroundColor:
            isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
        iconTheme: IconThemeData(
            color: isDark
                ? GlobalColors.appBarDarkText
                : GlobalColors.appBarLightText),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchData,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }
        final data = controller.data;
        if (data.isEmpty) {
          return const Center(child: Text('No data'));
        }
        final rows = <DataRow>[];
        for (final group in data) {
          for (final r in group) {
            rows.add(_buildRow(r, isDark));
          }
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('MODEL')),
              DataColumn(label: Text('GROUP')),
              DataColumn(label: Text('INPUT')),
              DataColumn(label: Text('PASS')),
              DataColumn(label: Text('FIRST_FAIL')),
              DataColumn(label: Text('FPR')),
              DataColumn(label: Text('SPR')),
              DataColumn(label: Text('YR')),
              DataColumn(label: Text('RR')),
            ],
            rows: rows,
            headingRowColor: MaterialStateProperty.resolveWith(
              (_) => isDark ? Colors.blueGrey[700] : Colors.blueGrey[100],
            ),
            dataRowColor: MaterialStateProperty.resolveWith(
              (_) => isDark ? Colors.blueGrey[800] : Colors.white,
            ),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        );
      }),
    );
  }
}
