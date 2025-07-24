// 📁 yield_report_screen.dart (fix: filterPanel crash on open)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/global_color.dart';
import '../../controller/yield_report_controller.dart';
import 'yield_report_filter_panel.dart';
import 'yield_report_table.dart';

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
                      YieldReportTable(
                        controller: controller,
                        isDark: isDark,
                        scrollController: _scrollController,
                      ),
                      if (controller.isLoading.value)
                        Positioned(
                          top: 0,
                          right: 0,
                          left: 0,
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Colors.transparent,
                          ),
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
}
