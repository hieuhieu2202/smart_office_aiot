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
    return Scaffold(
      appBar: AppBar(
        title: const Text('NVIDIA Station Overview'),
      ),
      body: SafeArea(
        child: Obx(() {
          final bool loading = controller.isLoading.value;
          final String? error = controller.error.value;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StationOverviewFilterBar(controller: controller),
              const SizedBox(height: 16),
              if (loading) const LinearProgressIndicator(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MaterialBanner(
                    content: Text(error),
                    leading: const Icon(Icons.error_outline),
                    actions: <Widget>[
                      TextButton(
                        onPressed: controller.loadOverview,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              StationStatusSummary(controller: controller),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 1200) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: StationGroupGrid(controller: controller),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              StationAnalysisSection(controller: controller),
                              const SizedBox(height: 16),
                              StationDetailSection(controller: controller),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  if (constraints.maxWidth >= 800) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        StationGroupGrid(controller: controller),
                        const SizedBox(height: 16),
                        StationAnalysisSection(controller: controller),
                        const SizedBox(height: 16),
                        StationDetailSection(controller: controller),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      StationGroupGrid(controller: controller),
                      const SizedBox(height: 16),
                      StationAnalysisSection(controller: controller),
                      const SizedBox(height: 16),
                      StationDetailSection(controller: controller),
                    ],
                  );
                },
              ),
            ],
          );

          return RefreshIndicator(
            onRefresh: controller.refreshOverview,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: content,
            ),
          );
        }),
      ),
      floatingActionButton: Obx(() {
        final bool hasSelection = controller.highlightedStation.value != null;
        if (!hasSelection) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: controller.loadStationDetails,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh station'),
        );
      }),
    );
  }
}
