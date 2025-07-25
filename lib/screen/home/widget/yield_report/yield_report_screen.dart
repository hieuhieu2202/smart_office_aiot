// 📁 yield_report_screen.dart (fix: filterPanel crash on open)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/global_color.dart';
import '../../../../util/linked_scroll_controller.dart';
import '../../controller/yield_report_controller.dart';
import 'yield_report_filter_panel.dart';
import 'yield_report_table.dart';

class YieldReportScreen extends StatefulWidget {
  YieldReportScreen({super.key});

  @override
  State<YieldReportScreen> createState() => _YieldReportScreenState();
}

class _YieldReportScreenState extends State<YieldReportScreen> {
  final ScrollController _scrollController = ScrollController();
  late final LinkedScrollControllerGroup _hGroup;
  late final ScrollController _headerController;
  final List<ScrollController> _tableControllers = [];

  @override
  void initState() {
    super.initState();
    _hGroup = LinkedScrollControllerGroup();
    _headerController = _hGroup.addAndGet();
  }

  @override
  void dispose() {
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

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: const Text('Yield Rate Report'),
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
                Container(
                  margin: const EdgeInsets.fromLTRB(13, 18, 13, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? GlobalColors.cardDarkBg
                            : GlobalColors.cardLightBg,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDark
                                ? Colors.black.withOpacity(0.10)
                                : Colors.grey.withOpacity(0.13),
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: isDark ? Colors.white54 : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
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
          child: _buildHeaderRow(
            controller.dates,
            isDark,
            _headerController,
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

  Widget _buildHeaderRow(List dates, bool isDark, ScrollController controller) {
    Widget cell(String text, {bool alignLeft = false, double? width}) =>
        YieldReportTable.buildCell(text, isDark,
            header: true, alignLeft: alignLeft, width: width);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available =
            constraints.maxWidth - YieldReportTable.stationWidth;
        double cw = YieldReportTable.cellWidth;
        if (dates.isNotEmpty &&
            dates.length * YieldReportTable.cellWidth < available) {
          cw = available / dates.length;
        }
        final contentWidth = cw * dates.length;
        final canCenter = contentWidth <= available;
        final tableWidth = YieldReportTable.stationWidth + contentWidth;

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: tableWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cell('Station', alignLeft: true),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    physics:
                        canCenter ? const NeverScrollableScrollPhysics() : null,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: available),
                      child: Align(
                        alignment: canCenter
                            ? Alignment.center
                            : Alignment.centerLeft,
                        child: Row(
                          children: dates
                              .map<Widget>((d) => cell(d.toString(), width: cw))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
