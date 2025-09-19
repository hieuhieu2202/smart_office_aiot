import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/cdu_controller.dart';
import 'cdu_summary_header.dart';
import 'cdu_history_panel.dart';
import 'cdu_layout_canvas.dart';
import 'cdu_node.dart';

class CduMonitoringScreen extends StatelessWidget {
  final CduController controller;

  const CduMonitoringScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
              () => Text(
            'CDU ${controller.factory.value}-${controller.floor.value}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Chọn tòa/tầng',
            icon: const Icon(Icons.filter_list),
            onSelected: (val) {
              final p = val.split('_');
              controller.changeLocation(newFactory: p[0], newFloor: p[1]);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'F16_3F', child: Text('F16 - 3F')),
              PopupMenuItem(value: 'F17_3F', child: Text('F17 - 3F')),
            ],
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshAll,
          ),
        ],
      ),
      body: Obx(() {
        // Trạng thái loading lần đầu
        if (controller.isLoading.value && controller.dashboard.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Không có dữ liệu
        if (controller.dashboard.value == null) {
          return const Center(child: Text('No data'));
        }

        return LayoutBuilder(
          builder: (ctx, b) {
            final isWide = b.maxWidth >= 900;

            // ==== LEFT PANE ====
            final leftPane = ListView(
              padding: const EdgeInsets.all(12),
              children: [
                CduSummaryHeader(
                  total: controller.totalCdu,
                  running: controller.runningCdu,
                  warning: controller.warningCdu,
                  abnormal: controller.abnormalCdu,
                ),
                const SizedBox(height: 12),

                // Canvas giữ nguyên
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: AspectRatio(
                    aspectRatio: isWide ? 21 / 9 : 16 / 9,
                    child: Obx(() {
                      final bg = controller.layoutImage; // đọc Rx qua getter
                      final nodes = controller.nodes;     // RxList

                      final isLoadingCanvas =
                          controller.isLoading.value && nodes.isEmpty;

                      if (isLoadingCanvas) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return InteractiveViewer(
                        minScale: 0.7,
                        maxScale: 3.0,
                        child: CduLayoutCanvas(bgImage: bg, nodes: nodes),
                      );
                    }),
                  ),
                ),
              ],
            );

            // ==== RIGHT PANE ====
            final rightPaneContent = Obx(
                  () => CduHistoryPanel(
                items: controller.historyItems,
                isInitialLoading: controller.isFirstHistoryLoad.value,
                isRefreshing: controller.isRefreshingHistory.value,
              ),
            );

            final rightPane = Padding(
              padding: const EdgeInsets.all(12),
              child: rightPaneContent,
            );

            // ==== RESPONSIVE SPLIT ====
            return isWide
                ? Row(
              children: [
                Expanded(flex: 3, child: leftPane),
                Expanded(flex: 1, child: rightPane),
              ],
            )
                : Column(
              children: [
                Expanded(child: leftPane),


                const SizedBox(height: 13),

                // giữ khung riêng & cuộn độc lập, nhưng sát layout
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: (b.maxHeight * 0.38).clamp(300.0, 420.0),
                  ),
                  child: Padding(
                    // bỏ padding top để dính sát layout
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: rightPaneContent,
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  void _showNodeDialog(BuildContext context, CduNode n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(n.id),
        content: SingleChildScrollView(
          child: Text(const JsonEncoder.withIndent('  ').convert(n.detail)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
