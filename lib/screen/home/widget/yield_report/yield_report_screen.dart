// 📁 yield_report_screen.dart (fix: filterPanel crash on open)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/global_color.dart';
import '../../controller/yield_report_controller.dart';
import 'yield_report_filter_panel.dart';

class YieldReportScreen extends StatelessWidget {
  YieldReportScreen({super.key});

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(YieldReportController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    controller.quickFilter.listen((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Obx(() => Scaffold(
      appBar: AppBar(
        title: const Text('Yield Rate Report'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_rounded),
            tooltip: 'Bộ lọc nâng cao',
            onPressed: controller.openFilterPanel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu',
            onPressed: controller.fetchReport,
          ),
        ],
      ),
      backgroundColor: isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(13, 18, 13, 0),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.10) : Colors.grey.withOpacity(0.13),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: "Tìm kiếm NickName, Model, Station...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontWeight: FontWeight.w400),
                        ),
                        onChanged: (val) => controller.updateQuickFilter(val),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 7),
              Expanded(
                child: controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : _buildDataTable(context, controller, isDark),
              ),
            ],
          ),
          // ✅ wrap YieldReportFilterPanel with Positioned.fill to avoid layout overflow / cast error
          if (controller.filterPanelOpen.value)
            Positioned.fill(
              child: YieldReportFilterPanel(
                show: true,
                start: controller.startDateTime.value,
                end: controller.endDateTime.value,
                nickName: controller.selectedNickName.value,
                nickNameOptions: controller.nickNameList,
                onApply: (start, end, nick) => controller.applyFilter(start, end, nick),
                onClose: controller.closeFilterPanel,
                isDark: isDark,
              ),
            ),
        ],
      ),
    ));
  }

  Widget _buildDataTable(BuildContext context, YieldReportController controller, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
      itemCount: controller.filteredNickNames.length,
      itemBuilder: (context, idx) {
        final nick = controller.filteredNickNames[idx];
        final models = nick['DataModelNames'] as List? ?? [];
        final nickName = nick['NickName'];
        return Card(
          margin: const EdgeInsets.only(bottom: 18),
          color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
          elevation: 6,
          shadowColor: isDark ? Colors.black45 : Colors.grey[200],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            key: PageStorageKey(nickName),
            initiallyExpanded: controller.expandedNickNames.contains(nickName),
            onExpansionChanged: (expanded) {
              if (expanded) {
                controller.expandedNickNames.add(nickName);
              } else {
                controller.expandedNickNames.remove(nickName);
              }
            },
            tilePadding: const EdgeInsets.symmetric(horizontal: 18),
            childrenPadding: const EdgeInsets.only(bottom: 16),
            maintainState: true,
            title: Text(
              nickName ?? '',
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.lightBlue[100] : Colors.blue[900], fontSize: 17),
            ),
            children: models.asMap().entries.map<Widget>((entry) {
              final idx = entry.key;
              final m = entry.value;
              final stations = m['DataStations'] as List? ?? [];
              final dates = controller.dates;
              final storageKey = '${nickName ?? 'nick'}-$idx';
              return Padding(
                padding: const EdgeInsets.only(top: 7, left: 2, right: 2),
                child: _buildStationTable(storageKey, dates, stations, isDark),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildStationTable(String storageKey, List dates, List stations, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 3, right: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey[900] : Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.grey.withOpacity(0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderCell('Station', 110, isDark, align: Alignment.center),
                ...stations.map((st) => Container(
                  width: 110,
                  height: 42,
                  alignment: Alignment.center,
                  child: Text(
                    st['Station'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                      fontSize: 14,
                    ),
                  ),
                ))
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                key: PageStorageKey('${storageKey}_scroll'),
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: dates.map((d) => _buildHeaderCell(d, 85, isDark)).toList(),
                    ),
                    ...stations.map((st) {
                      final values = (st['Data'] as List? ?? []).map((e) => e.toString()).toList();
                      return Row(
                        children: values.map((v) => Container(
                          width: 85,
                          height: 42,
                          alignment: Alignment.center,
                          child: Text(
                            v,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.yellowAccent : Colors.blueAccent,
                              fontSize: 13,
                            ),
                          ),
                        )).toList(),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width, bool isDark, {Alignment align = Alignment.center}) {
    return Container(
      width: width,
      height: 42,
      alignment: align,
      color: isDark ? Colors.teal[900] : Colors.blue[100],
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.yellowAccent : Colors.blueAccent,
        ),
      ),
    );
  }
}
