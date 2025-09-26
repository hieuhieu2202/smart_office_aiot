// 📁 yield_report_screen.dart (fix: filterPanel crash on open)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/global_color.dart';
import '../../../../util/linked_scroll_controller.dart';
import '../../controller/yield_report_controller.dart';
import 'yield_report_filter_panel.dart';
import 'yield_report_table.dart';
import 'yield_report_header_row.dart';
import 'yield_report_search_bar.dart';

class YieldReportScreen extends StatefulWidget {
  const YieldReportScreen({
    super.key,
    this.initialNickName = 'All',
    this.controllerTag,
    this.title,
    this.reportType = 'SWITCH',
  });

  final String initialNickName;
  final String? controllerTag;
  final String? title;
  final String reportType;

  @override
  State<YieldReportScreen> createState() => _YieldReportScreenState();
}

class _YieldReportScreenState extends State<YieldReportScreen> {
  final ScrollController _scrollController = ScrollController();
  late final LinkedScrollControllerGroup _hGroup;
  late final ScrollController _headerController;
  final List<ScrollController> _tableControllers = [];
  late final String _controllerTag;
  late final YieldReportController controller;
  Worker? _quickFilterWorker;

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.controllerTag ??
        'YIELD_REPORT_${widget.initialNickName.toUpperCase()}';
    controller = Get.put(
      YieldReportController(
        reportType: widget.reportType,
        initialNickName: widget.initialNickName,
      ),
      tag: _controllerTag,
    );
    _hGroup = LinkedScrollControllerGroup();
    _headerController = _hGroup.addAndGet();
    _quickFilterWorker = ever(controller.quickFilter, (_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _quickFilterWorker?.dispose();
    if (Get.isRegistered<YieldReportController>(tag: _controllerTag)) {
      Get.delete<YieldReportController>(tag: _controllerTag);
    }
    // LinkedScrollControllerGroup already disposes all controllers
    _hGroup.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureTableControllers(int count) {
    while (_tableControllers.length < count) {
      _tableControllers.add(_hGroup.addAndGet());
    }
    // Keep any extra controllers around to avoid disposing ones
    // still attached to widgets being removed this frame.
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? 'Yield Rate Report'),
          centerTitle: true,
          elevation: 0,
          backgroundColor:
              isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
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
        backgroundColor:
            isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
        body: Stack(
          children: [
            Column(
              children: [
                YieldReportSearchBar(
                  controller: controller,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 7),
                Expanded(
                  child: Stack(
                    children: [
                      _buildDataTable(context, controller, isDark),
                      if (controller.isLoading.value)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                    ],
                  ),
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
                  onApply:
                      (start, end, nick) =>
                          controller.applyFilter(start, end, nick),
                  onClose: controller.closeFilterPanel,
                  isDark: isDark,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    YieldReportController controller,
    bool isDark,
  ) {
    final nickNames = controller.filteredNickNames;
    int modelCount = 0;
    for (final nick in nickNames) {
      modelCount += (nick['DataModelNames'] as List? ?? []).length;
    }
    _ensureTableControllers(modelCount);

    int tableIndex = 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
          child: YieldReportHeaderRow(
            dates: controller.dates,
            isDark: isDark,
            controller: _headerController,
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
            itemCount: nickNames.length,
            itemBuilder: (context, idx) {
              final nick = nickNames[idx];
              final models = nick['DataModelNames'] as List? ?? [];
              final nickName = nick['NickName'];
              return Card(
                margin: const EdgeInsets.only(bottom: 18),
                color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
                elevation: 6,
                shadowColor: isDark ? Colors.black45 : Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.lightBlue[100] : Colors.blue[900],
                      fontSize: 17,
                    ),
                  ),
                  children: [
                    ...models.map<Widget>((m) {
                      final stations = m['DataStations'] as List? ?? [];
                      final modelName = m['ModelName']?.toString() ?? '';
                      ScrollController sc;
                      if (tableIndex < _tableControllers.length) {
                        sc = _tableControllers[tableIndex];
                      } else {
                        sc = _hGroup.addAndGet();
                        _tableControllers.add(sc);
                      }
                      tableIndex++;
                      return Padding(
                        padding: const EdgeInsets.only(top: 7, left: 2, right: 2),
                        child: YieldReportTable(
                          modelName: modelName,
                          dates: controller.dates.cast<String>(),
                          stations: stations,
                          isDark: isDark,
                          scrollController: sc,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}
