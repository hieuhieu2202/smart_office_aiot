import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/station_overview_controller.dart';
import '../widgets/station_group_grid.dart';
import '../widgets/station_overview_filter_bar.dart';
import '../widgets/station_status_summary.dart';

class StationOverviewPage extends GetView<StationOverviewController> {
  StationOverviewPage({super.key}) {
    Get.put(StationOverviewController());
  }

  @override
  StationOverviewController get controller => Get.find<StationOverviewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020A1A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isDesktop = constraints.maxWidth >= 1280;
            return Obx(() {
              final bool loading = controller.isLoading.value;
              final bool refreshing = controller.isRefreshing.value;
              final String? error = controller.error.value;

              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFF001637), Color(0xFF010B20)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: _LegacyHeader(controller: controller),
                        ),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              color: Color(0xFF00BCD4),
                              backgroundColor: Color(0x3300BCD4),
                            ),
                          ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: _ErrorBanner(message: error, onRetry: controller.loadOverview),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: isDesktop
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      SizedBox(
                                        width: 320,
                                        child: StationOverviewFilterBar(
                                          controller: controller,
                                          orientation: Axis.vertical,
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(child: _BoardContainer(controller: controller)),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      StationOverviewFilterBar(
                                        controller: controller,
                                        orientation: Axis.vertical,
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(child: _BoardContainer(controller: controller)),
                                    ],
                                  ),
                          ),
                        ),
                        StationStatusSummary(controller: controller),
                        const SizedBox(height: 12),
                      ],
                    ),
                    if (refreshing)
                      Positioned(
                        right: 24,
                        top: 24,
                        child: _RefreshingBadge(),
                      ),
                  ],
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

class _BoardContainer extends StatelessWidget {
  const _BoardContainer({required this.controller});

  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF021127).withOpacity(0.9),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: controller.refreshOverview,
        color: Colors.cyanAccent,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: StationGroupGrid(controller: controller),
          ),
        ),
      ),
    );
  }
}

class _LegacyHeader extends StatelessWidget {
  const _LegacyHeader({required this.controller});

  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF04152C).withOpacity(0.85),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Obx(() {
        final String modelSerial = controller.selectedModelSerial.value;
        final String product = controller.selectedProduct.value;
        final String model = controller.selectedModel.value;
        final String group = controller.selectedGroup.value;
        final DateTimeRange? range = controller.selectedRange.value;

        final String subtitle = [
          'MODEL SERIAL: $modelSerial',
          'PRODUCT: $product',
          'MODEL: $model',
          'GROUP: $group',
        ].join('  •  ');

        final String rangeText = range == null
            ? 'AUTO REFRESH • LAST 24 HOURS'
            : '${_format(range.start)}  →  ${_format(range.end)}';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'NVIDIA ADAPTER STATION OVERVIEW',
                    style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 1.1,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rangeText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.cyanAccent,
                          letterSpacing: 1.0,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: controller.loadOverview,
              icon: const Icon(Icons.sync),
              label: const Text('REFRESH'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _format(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.red.withOpacity(0.18),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }
}

class _RefreshingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
          ),
          SizedBox(width: 8),
          Text(
            'Refreshing...',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
