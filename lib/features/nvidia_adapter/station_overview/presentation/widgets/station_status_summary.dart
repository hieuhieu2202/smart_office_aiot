import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/station_overview_entities.dart';
import '../controllers/station_overview_controller.dart';
import '../viewmodels/station_overview_view_state.dart';
import 'station_analysis_section.dart';

class StationStatusSummary extends StatelessWidget {
  const StationStatusSummary({super.key, required this.controller});

  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final StationOverviewDashboardViewState? state = controller.dashboard.value;
      if (state == null) {
        return const SizedBox.shrink();
      }

      final Map<StationStatus, int> counts = state.statusCounts;
      final int total = state.totalStations;
      final int warning = counts[StationStatus.warning] ?? 0;
      final int error = counts[StationStatus.error] ?? 0;
      final int offline = counts[StationStatus.offline] ?? 0;
      int normal = total - warning - error - offline;
      if (normal < 0) {
        normal = 0;
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF04152C).withOpacity(0.9),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _FooterChip(
                label: 'ANALYSIS',
                color: const Color(0xFFA770FF),
                onTap: () => _openAnalysis(context),
              ),
              _FooterChip(
                label: 'TOTAL',
                color: const Color(0xFF00E5FF),
                value: total,
                percentage: total == 0 ? 0 : 100,
              ),
              _FooterChip(
                label: 'NORMAL',
                color: const Color(0xFF4CAF50),
                value: normal,
                percentage: total == 0 ? 0 : (normal / total * 100),
              ),
              _FooterChip(
                label: 'WARNING',
                color: const Color(0xFFFFC107),
                value: warning,
                percentage: total == 0 ? 0 : (warning / total * 100),
              ),
              _FooterChip(
                label: 'ERROR',
                color: const Color(0xFFF44336),
                value: error,
                percentage: total == 0 ? 0 : (error / total * 100),
              ),
              _FooterChip(
                label: 'OFFLINE',
                color: Colors.blueGrey.shade300,
                value: offline,
                percentage: total == 0 ? 0 : (offline / total * 100),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _openAnalysis(BuildContext context) {
    if (controller.highlightedStation.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a station to view analysis'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final double height = MediaQuery.of(context).size.height * 0.75;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF041023),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: StationAnalysisSection(controller: controller),
            ),
          ),
        );
      },
    );
  }
}

class _FooterChip extends StatelessWidget {
  const _FooterChip({
    required this.label,
    required this.color,
    this.value,
    this.percentage,
    this.onTap,
  });

  final String label;
  final Color color;
  final int? value;
  final double? percentage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isAction = onTap != null && value == null;
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
        ),
        if (value != null) ...<Widget>[
          const SizedBox(width: 8),
          Text(
            '$value',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (percentage != null) ...<Widget>[
            const SizedBox(width: 4),
            Text(
              '(${percentage!.toStringAsFixed(2)}%)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ],
      ],
    );

    final EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    final BorderRadius radius = BorderRadius.circular(16);

    if (isAction) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: color.withOpacity(0.6)),
            ),
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: Colors.black.withOpacity(0.35),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: content,
      ),
    );
  }
}
