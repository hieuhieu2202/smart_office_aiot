import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../service/lc_switch_rack_api.dart' show RackDetail;
import '../../../../widget/animation/loading/eva_loading_view.dart';
import '../../controller/racks_monitor_controller.dart';
import 'rack_filter_sheet.dart';
import 'rack_left_panel.dart';
import 'rack_list_filter.dart';
import 'rack_monitor_header.dart';
import 'rack_monitor_insights.dart';
import 'rack_monitor_states.dart';
import 'rack_partition.dart';

class GroupMonitorScreen extends StatefulWidget {
  final String? initialFactory;
  final String? initialFloor;
  final String? initialRoom;
  final String? initialGroup;
  final String? initialModel;
  final String? controllerTag;

  const GroupMonitorScreen({
    super.key,
    this.initialFactory,
    this.initialFloor,
    this.initialRoom,
    this.initialGroup,
    this.initialModel,
    this.controllerTag,
  });

  @override
  State<GroupMonitorScreen> createState() => _GroupMonitorScreenState();
}

class _GroupMonitorScreenState extends State<GroupMonitorScreen>
    with SingleTickerProviderStateMixin {
  late final GroupMonitorController controller;
  late final TabController _tabController;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = widget.controllerTag ??
        [
          'racks_monitor',
          widget.initialFactory ?? 'any',
          widget.initialFloor ?? 'any',
          widget.initialRoom ?? 'any',
          widget.initialGroup ?? 'any',
          widget.initialModel ?? 'any',
        ].join('_');
    if (Get.isRegistered<GroupMonitorController>(tag: _tag)) {
      Get.delete<GroupMonitorController>(tag: _tag);
    }
    controller = Get.put(
      GroupMonitorController(
        initialFactory: widget.initialFactory,
        initialFloor: widget.initialFloor,
        initialRoom: widget.initialRoom,
        initialGroup: widget.initialGroup,
        initialModel: widget.initialModel,
      ),
      tag: _tag,
    );
    _tabController = TabController(length: RackListFilter.values.length, vsync: this)
      ..addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    if (Get.isRegistered<GroupMonitorController>(tag: _tag)) {
      Get.delete<GroupMonitorController>(tag: _tag);
    }
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  RackListFilter get _activeFilter =>
      RackListFilter.values[_tabController.index];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final f = controller.selFactory.value;
          final fl = controller.selFloor.value;
          final g = controller.selGroup.value;
          final m = controller.selModel.value;
          final parts = <String>[
            f,
            if (fl.isNotEmpty && fl != 'ALL') fl,
            if (controller.selRoom.value != 'ALL') controller.selRoom.value,
            if (g.isNotEmpty && g != 'ALL') g,
            if (m != 'ALL') m,
          ];
          return Text(parts.isEmpty ? 'Rack Monitor' : parts.join('  ·  '));
        }),
        actions: [
          RackFilterPanel(controller: controller),
          Obx(
            () => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed:
                  controller.isLoading.value ? null : controller.refresh,
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Obx(() {
        final error = controller.error.value;
        if (error != null) {
          return RackErrorState(
            message: error,
            onRetry: controller.refresh,
          );
        }

        if (controller.isLoading.value && controller.data.value == null) {
          return const EvaLoadingView(size: 280);
        }

        final data = controller.data.value;
        if (data == null) {
          return const Center(child: Text('No data'));
        }

        final partition = RackPartition.from(data.rackDetails);

        final filter = _activeFilter;
        late final List<RackDetail> selectedRacks;
        switch (filter) {
          case RackListFilter.all:
            selectedRacks = [
              ...partition.online,
              ...partition.offline,
            ];
            break;
          case RackListFilter.online:
            selectedRacks = partition.online;
            break;
          case RackListFilter.offline:
            selectedRacks = partition.offline;
            break;
        }

        return Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                const sidePanelWidth = 360.0;
                const sidePanelGap = 20.0;
                final wide = constraints.maxWidth >= 1180;
                final leftViewportWidth = wide
                    ? math.max(
                        0.0, constraints.maxWidth - sidePanelWidth - sidePanelGap)
                    : constraints.maxWidth;
                final insights = RackInsightsColumn(
                  controller: controller,
                  totalRacks: partition.total,
                  onlineCount: partition.online.length,
                  offlineCount: partition.offline.length,
                  activeFilter: filter,
                );

                final headerViewportWidth = wide
                    ? (constraints.maxWidth - sidePanelWidth - sidePanelGap)
                        .clamp(0.0, constraints.maxWidth)
                    : constraints.maxWidth;
                final headerHeight = RackPinnedHeader.estimateHeight(
                  context: context,
                  maxWidth: headerViewportWidth,
                );

                final slivers = <Widget>[
                  if (!wide)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                        child: insights,
                      ),
                    ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: RackHeaderDelegate(
                      height: headerHeight,
                      child: RackPinnedHeader(
                        controller: _tabController,
                        total: partition.total,
                        online: partition.online.length,
                        offline: partition.offline.length,
                      ),
                    ),
                  ),
                  if (selectedRacks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: RackEmptyState(
                        mode: filter,
                        onRefresh: controller.refresh,
                      ),
                    )
                  else ...[
                    RackLeftPanel(
                      racks: selectedRacks,
                      maxWidthHint: leftViewportWidth,
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ];

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: controller.refresh,
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: slivers,
                          ),
                        ),
                      ),
                      const SizedBox(width: sidePanelGap),
                      SizedBox(
                        width: sidePanelWidth,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 18, 12, 26),
                          physics: const BouncingScrollPhysics(),
                          child: insights,
                        ),
                      ),
                    ],
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: slivers,
                  ),
                );
              },
            ),
            if (controller.isLoading.value && controller.data.value != null)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: true,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ),
          ],
        );
      }),
    );
  }
}
