import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/rack_entities.dart';
import '../../../../../widget/animation/loading/eva_loading_view.dart';
import '../controllers/rack_monitor_binding.dart';
import '../controllers/rack_monitor_controller.dart';
import '../widgets/rack_filter_sheet.dart';
import '../widgets/rack_left_panel.dart';
import '../widgets/rack_list_filter.dart';
import '../widgets/rack_monitor_header.dart';
import '../widgets/rack_monitor_insights.dart';
import '../widgets/rack_monitor_states.dart';
import '../widgets/rack_partition.dart';

/// Rack Monitor Page - Main entry point for rack monitoring feature
class RackMonitorPage extends StatefulWidget {
  final String? initialFactory;
  final String? initialFloor;
  final String? initialRoom;
  final String? initialGroup;
  final String? initialModel;
  final String? controllerTag;

  const RackMonitorPage({
    super.key,
    this.initialFactory,
    this.initialFloor,
    this.initialRoom,
    this.initialGroup,
    this.initialModel,
    this.controllerTag,
  });

  @override
  State<RackMonitorPage> createState() => _RackMonitorPageState();
}

class _RackMonitorPageState extends State<RackMonitorPage>
    with SingleTickerProviderStateMixin {
  late final RackMonitorController controller;
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

    // Initialize dependencies using binding
    RackMonitorBinding(
      initialFactory: widget.initialFactory,
      initialFloor: widget.initialFloor,
      initialRoom: widget.initialRoom,
      initialGroup: widget.initialGroup,
      initialModel: widget.initialModel,
      tag: _tag,
    ).dependencies();

    controller = Get.find<RackMonitorController>(tag: _tag);
    _tabController = TabController(
      length: RackListFilter.values.length,
      vsync: this,
    )..addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    if (Get.isRegistered<RackMonitorController>(tag: _tag)) {
      Get.delete<RackMonitorController>(tag: _tag);
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
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF76B900),
        title: Obx(() {
          final f = controller.selFactory.value;
          final fl = controller.selFloor.value;
          final g = controller.selGroup.value;
          final m = controller.selModel.value;
          final filters = <String>[
            if (f.isNotEmpty) f,
            if (fl.isNotEmpty && fl != 'ALL') fl,
            if (controller.selRoom.value != 'ALL') controller.selRoom.value,
            if (g.isNotEmpty && g != 'ALL') g,
            if (m != 'ALL') m,
          ];
          final parts = <String>['NVIDIA', ...filters, 'RACK MONITOR'];
          final text = parts.join('  ·  ');

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: Text(
              text.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          );
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
        late final List<RackDetail> racks;
        switch (filter) {
          case RackListFilter.all:
            racks = [
              ...partition.online,
              ...partition.offline,
            ];
            break;
          case RackListFilter.online:
            racks = partition.online;
            break;
          case RackListFilter.offline:
            racks = partition.offline;
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
                        0.0,
                        constraints.maxWidth - sidePanelWidth - sidePanelGap,
                      )
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
                  if (racks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: RackEmptyState(
                        mode: filter,
                        onRefresh: controller.refresh,
                      ),
                    )
                  else ...[
                    RackLeftPanel(
                      racks: racks,
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

