import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/station_overview_controller.dart';
import '../widgets/station_analysis_section.dart';
import '../widgets/station_detail_section.dart';
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
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF010919),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF041642),
              Color(0xFF020B24),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            final bool loading = controller.isLoading.value;
            final String? error = controller.error.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: _DashboardHeader(controller: controller),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.refreshOverview,
                    color: theme.colorScheme.secondary,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: <Widget>[
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                StationOverviewFilterBar(controller: controller),
                                const SizedBox(height: 18),
                                if (loading)
                                  const LinearProgressIndicator(
                                    minHeight: 4,
                                    backgroundColor: Color(0x3300BCD4),
                                  ),
                                if (error != null)
                                  _ErrorBanner(
                                    message: error,
                                    onRetry: controller.loadOverview,
                                  ),
                                StationStatusSummary(controller: controller),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverToBoxAdapter(
                            child: LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                                final bool isUltraWide = constraints.maxWidth > 1500;
                                if (isUltraWide) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        flex: 7,
                                        child: StationGroupGrid(controller: controller),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: <Widget>[
                                            StationAnalysisSection(controller: controller),
                                            const SizedBox(height: 24),
                                            StationDetailSection(controller: controller),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    StationGroupGrid(controller: controller),
                                    const SizedBox(height: 24),
                                    StationAnalysisSection(controller: controller),
                                    const SizedBox(height: 24),
                                    StationDetailSection(controller: controller),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
      floatingActionButton: Obx(() {
        final bool hasSelection = controller.highlightedStation.value != null;
        if (!hasSelection) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          onPressed: controller.loadStationDetails,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh station data'),
        );
      }),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.controller});

  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle = theme.textTheme.headlineSmall!.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    );
    final TextStyle subtitleStyle = theme.textTheme.titleMedium!.copyWith(
      color: Colors.white70,
      letterSpacing: 1.1,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('NVIDIA ADAPTER', style: subtitleStyle),
            const SizedBox(height: 4),
            Text('STATION OVERVIEW', style: titleStyle),
            const SizedBox(height: 8),
            Obx(() {
              final String serial = controller.selectedModelSerial.value;
              final String product = controller.selectedProduct.value;
              return Text(
                'MODEL SERIAL: $serial • PRODUCT: $product',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                  letterSpacing: 1.05,
                ),
              );
            }),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              _formatNow(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                letterSpacing: 1.05,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: controller.loadOverview,
              icon: const Icon(Icons.sync),
              label: const Text('Refresh overview'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0AA5FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNow() {
    final DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.redAccent.withOpacity(0.16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
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
