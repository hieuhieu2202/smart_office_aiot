import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/racks_monitor_controller.dart';
import 'rack_filter_sheet.dart';
import 'rack_left_panel.dart';
import 'rack_pass_by_model_chart.dart';
import 'rack_slot_status_donut.dart';
import 'rack_yield_rate_gauge.dart';
import 'rack_wip_pass_summary.dart';
import 'rack_kpi_summary.dart';

class GroupMonitorScreen extends StatelessWidget {
  const GroupMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(GroupMonitorController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final f = c.selFactory.value;
          final fl = c.selFloor.value;
          final g = c.selGroup.value;
          final m = c.selModel.value;
          final parts = <String>[
            f,
            if (fl != 'ALL') fl,
            if (g != 'ALL') g,
            if (m != 'ALL') m,
          ];
          return Text(parts.isEmpty ? 'Rack Monitor' : parts.join('  ·  '));
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              await showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                backgroundColor:
                    isDark ? const Color(0xFF071833) : Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => RackFilterSheet(controller: c),
              );
            },
            tooltip: 'Filter',
          ),
          Obx(
            () => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: c.isLoading.value ? null : c.refresh,
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: Obx(() {
        if (c.error.value != null) {
          return Center(
            child: Text(c.error.value!, textAlign: TextAlign.center),
          );
        }
        if (c.isLoading.value && c.data.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = c.data.value;
        if (data == null) return const Center(child: Text('No data'));

        return LayoutBuilder(
          builder: (ctx, ct) {
            final wide = ct.maxWidth >= 1100;

            if (wide) {
              // ===== Desktop/Tablet rộng: Trái (Grid) - Phải (Panels)
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: _PanelCard(
                              child: RackNumbersBox(controller: c),
                            ),
                          ),
                        ),
                        RackLeftPanel(racks: data.rackDetails),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 360,
                    child: ColoredBox(
                      color:
                          isDark
                              ? const Color(0xFF061A2F)
                              : const Color(0xFFF5F7FA),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                        children: [
                          _PanelCard(child: PassByModelBar(controller: c)),
                          _PanelCard(child: SlotStatusDonut(controller: c)),
                          _PanelCard(child: YieldRateGauge(controller: c)),
                          _PanelCard(child: WipPassSummary(controller: c)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // ===== Mobile: 1 cột (SUMMARY + các panel + Grid)
            return RefreshIndicator(
              onRefresh: c.refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Wrap(
                        runSpacing: 12,
                        spacing: 12,
                        children: [
                          _PanelCard(child: RackNumbersBox(controller: c)),
                          _PanelCard(child: PassByModelBar(controller: c)),
                          _PanelCard(child: SlotStatusDonut(controller: c)),
                          _PanelCard(child: YieldRateGauge(controller: c)),
                          _PanelCard(child: WipPassSummary(controller: c)),
                        ],
                      ),
                    ),
                  ),
                  RackLeftPanel(racks: data.rackDetails),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        );
      }),


    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: child,
    );
  }
}
