import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../../controller/nvidia_lc_switch_kanban_controller.dart';
import 'filter_panel.dart';
import 'mobile_cards.dart';
import 'table.dart';

class OutputTrackingScreen extends StatelessWidget {
  const OutputTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KanbanController controller =
    Get.isRegistered<KanbanController>() ? Get.find<KanbanController>() : Get.put(KanbanController());

    return ResponsiveBuilder(
      builder: (context, sizing) {
        final isMobile = sizing.deviceScreenType == DeviceScreenType.mobile;
        final isTablet = sizing.deviceScreenType == DeviceScreenType.tablet;

        final horizontalPadding = isMobile ? 8.0 : 12.0;
        final verticalPadding = isMobile ? 8.0 : 12.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('OUTPUT TRACKING'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Filter',
                icon: const Icon(Icons.filter_alt_outlined),
                onPressed: () async {
                  final f = await showModalBottomSheet<Map<String, dynamic>>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const OtFilterPanel(),
                  );
                  if (f != null) {
                    final dynamic rawGroups = f['groups'];
                    final List<String> groups =
                        rawGroups is List ? rawGroups.map((e) => e.toString()).toList() : <String>[];
                    controller.updateFilter(
                      newDate: f['date'] is DateTime ? f['date'] as DateTime : controller.date.value,
                      newShift: (f['shift'] ?? controller.shift.value).toString(),
                      newGroups: groups.isNotEmpty ? groups : controller.groups.toList(),
                    );
                  }
                },
              ),
              IconButton(
                tooltip: 'Reload',
                icon: const Icon(Icons.refresh),
                onPressed: controller.loadAll,
              ),
            ],
          ),
          body: SafeArea(
            child: Obx(() {
              final isLoading = controller.isLoading.value;
              final err = controller.error.value;

              final out = controller.outputTracking.value;
              final hours = controller.hours;

              if (isLoading && out == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (err != null && err.isNotEmpty) {
                return _StateBox(
                  icon: Icons.error_outline,
                  title: 'Load failed',
                  subtitle: err,
                  actionText: 'Retry',
                  onPressed: controller.loadAll,
                );
              }

              final data = out?.data ?? const [];
              if (data.isEmpty || hours.isEmpty) {
                return _StateBox(
                  icon: Icons.inbox_outlined,
                  title: 'No data',
                  subtitle: 'Kéo để refresh hoặc chỉnh bộ lọc.',
                  actionText: 'Reload',
                  onPressed: controller.loadAll,
                );
              }

              final groups = <String>[
                for (final g in data)
                  if (g.groupName.toString().trim().isNotEmpty) g.groupName,
              ];

              final totalPassByGroup = <String, int>{
                for (final g in data) g.groupName: g.pass.fold<int>(0, (s, v) => s + (v.isNaN ? 0 : v).round()),
              };
              final totalFailByGroup = <String, int>{
                for (final g in data) g.groupName: g.fail.fold<int>(0, (s, v) => s + (v.isNaN ? 0 : v).round()),
              };

              if (isMobile) {
                return RefreshIndicator(
                  onRefresh: controller.loadAll,
                  child: OtMobileList(
                    groups: groups,
                    hours: hours,
                    modelNameByGroup: controller.modelNameByGroup,
                    passByGroup: controller.passSeriesByGroup,
                    yrByGroup: controller.yrSeriesByGroup,
                    rrByGroup: controller.rrSeriesByGroup,
                    wipByGroup: controller.wipByGroup,
                    totalPassByGroup: totalPassByGroup,
                    totalFailByGroup: totalFailByGroup,
                  ),
                );
              }

              final media = MediaQuery.of(context);
              final totalH = media.size.height;
              final topPad = media.padding.top;

              final paddingVert = EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                isTablet ? 20 : 16,
              );

              const sliverVertPadding = 28.0;
              final rawTableH = totalH - kToolbarHeight - topPad - sliverVertPadding;
              final adjustedTableH = isTablet ? rawTableH - 24 : rawTableH - 12;
              final tableH = adjustedTableH.clamp(200.0, totalH).toDouble();

              return RefreshIndicator(
                onRefresh: controller.loadAll,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: paddingVert,
                      sliver: SliverToBoxAdapter(
                        child: SizedBox(
                          height: tableH,
                          child: OtTable(
                            hours: hours,
                            groups: groups,
                            modelNameByGroup: controller.modelNameByGroup,
                            passByGroup: controller.passSeriesByGroup,
                            yrByGroup: controller.yrSeriesByGroup,
                            rrByGroup: controller.rrSeriesByGroup,
                            wipByGroup: controller.wipByGroup,
                            totalPassByGroup: totalPassByGroup,
                            totalFailByGroup: totalFailByGroup,
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44),
            const SizedBox(height: 12),
            Text(title, style: t.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: t.bodySmall),
            const SizedBox(height: 12),
            FilledButton(onPressed: onPressed, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}
