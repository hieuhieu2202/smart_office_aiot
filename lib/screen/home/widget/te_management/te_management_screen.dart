import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../config/global_color.dart';
import '../../../../widget/animation/loading/eva_loading_view.dart';
import '../../controller/te_management_controller.dart';
import 'te_management_search_bar.dart';
import 'te_management_filter_panel.dart';

class TEManagementScreen extends StatefulWidget {
  const TEManagementScreen({
    super.key,
    this.initialModelSerial = 'SWITCH',
    this.initialModel = '',
    this.controllerTag,
    this.title,
  });

  final String initialModelSerial;
  final String initialModel;
  final String? controllerTag;
  final String? title;

  @override
  State<TEManagementScreen> createState() => _TEManagementScreenState();
}

class _TEManagementScreenState extends State<TEManagementScreen> {
  late final String _controllerTag;
  late final TEManagementController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.controllerTag ??
        'TE_MANAGEMENT_${widget.initialModelSerial}_${widget.initialModel}';
    controller = Get.put(
      TEManagementController(
        initialModelSerial: widget.initialModelSerial,
        initialModel: widget.initialModel,
      ),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<TEManagementController>(tag: _controllerTag)) {
      Get.delete<TEManagementController>(tag: _controllerTag);
    }
    super.dispose();
  }

  Color _rateColor(double v, bool isDark) {
    if (v < 90) return isDark ? Colors.redAccent : Colors.red;
    if (v < 97) return Colors.orangeAccent;
    return isDark ? Colors.greenAccent : Colors.green;
  }

  DataRow _buildRow(Map<String, dynamic> row, bool isDark) {
    double parseDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    return DataRow(
      cells: [
        DataCell(Text(row['GROUP_NAME']?.toString() ?? '')),
        DataCell(Text(row['WIP_QTY']?.toString() ?? '')),
        DataCell(Text(row['INPUT']?.toString() ?? '')),
        DataCell(
          Text(
            row['FIRST_FAIL']?.toString() ?? '',
            style: TextStyle(color: isDark ? Colors.redAccent : Colors.red),
          ),
        ),
        DataCell(Text(row['REPAIR_QTY']?.toString() ?? '')),
        DataCell(Text(row['FIRST_PASS']?.toString() ?? '')),
        DataCell(
          Text(
            row['PASS']?.toString() ?? '',
            style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green),
          ),
        ),
        DataCell(Text(row['R_PASS']?.toString() ?? '')),
        DataCell(
          Text(
            row['FPR']?.toString() ?? '',
            style: TextStyle(color: _rateColor(parseDouble(row['FPR']), isDark)),
          ),
        ),
        DataCell(
          Text(
            row['SPR']?.toString() ?? '',
            style: TextStyle(color: _rateColor(parseDouble(row['SPR']), isDark)),
          ),
        ),
        DataCell(
          Text(
            row['YR']?.toString() ?? '',
            style: TextStyle(color: _rateColor(parseDouble(row['YR']), isDark)),
          ),
        ),
        DataCell(Text(row['RR']?.toString() ?? '')),
      ],
    );
  }

  Widget _buildGroup(List<Map<String, dynamic>> group, bool isDark) {
    final modelName = group.first['MODEL_NAME']?.toString() ?? '';
    final rows = group.map((row) => _buildRow(row, isDark)).toList();

    return Card(
      margin: const EdgeInsets.only(top: 18, left: 11, right: 11),
      color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      elevation: 8,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isDark ? Colors.blueAccent.withOpacity(.4) : Colors.blueAccent.withOpacity(.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              modelName,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.lightBlue[100] : Colors.blue[900],
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                columns: const [
                  DataColumn(label: Text('GROUP', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('WIP', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('INPUT', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('FAIL', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('REPAIR', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('FIRST_PASS', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('PASS', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('R_PASS', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('FPR', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('SPR', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('YR', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('RR', style: TextStyle(fontWeight: FontWeight.bold))),
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(
          () => Scaffold(
        backgroundColor: isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
        appBar: AppBar(
          title: Text(widget.title ?? 'TE Management'),
          centerTitle: true,
          backgroundColor: isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
          iconTheme: IconThemeData(
            color: isDark ? GlobalColors.appBarDarkText : GlobalColors.appBarLightText,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt_rounded),
              onPressed: controller.openFilterPanel,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.fetchData(force: true),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                TEManagementSearchBar(controller: controller, isDark: isDark),
                const SizedBox(height: 10),
                Expanded(child: _buildBody(isDark)),
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
      return const EvaLoadingView(size: 260);
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