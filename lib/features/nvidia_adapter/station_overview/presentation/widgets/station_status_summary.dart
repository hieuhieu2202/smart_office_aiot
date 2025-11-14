import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/station_overview_controller.dart';
import '../viewmodels/station_overview_view_state.dart';
import '../../domain/entities/station_overview_entities.dart';

class StationStatusSummary extends StatelessWidget {
  const StationStatusSummary({super.key, required this.controller});

  final StationOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Obx(() {
      final StationOverviewDashboardViewState? state = controller.dashboard.value;
      if (state == null) {
        return const SizedBox.shrink();
      }
      final Map<StationStatus, int> counts = state.statusCounts;
      final List<_StatusInfo> items = <_StatusInfo>[
        _StatusInfo(
          status: StationStatus.error,
          label: 'Error',
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFE53935), Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _StatusInfo(
          status: StationStatus.warning,
          label: 'Warning',
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFFFCA28), Color(0xFFF57F17)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _StatusInfo(
          status: StationStatus.normal,
          label: 'Normal',
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF43A047), Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _StatusInfo(
          status: StationStatus.offline,
          label: 'Offline',
          gradient: LinearGradient(
            colors: <Color>[
              Colors.blueGrey.shade400,
              Colors.blueGrey.shade700,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ];

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isStacked = constraints.maxWidth < 720;
          final Iterable<Widget> cards = items.map(
            (_StatusInfo info) => _StatusCard(
              info: info,
              count: counts[info.status] ?? 0,
              total: state.totalStations,
            ),
          );

          if (isStacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: cards
                  .map(
                    (Widget card) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: card,
                    ),
                  )
                  .toList(),
            );
          }

          final List<Widget> cardList = cards.toList();
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(cardList.length, (int index) {
              final Widget card = cardList[index];
              final EdgeInsets padding = EdgeInsets.only(right: index == cardList.length - 1 ? 0 : 14);
              return Expanded(
                child: Padding(
                  padding: padding,
                  child: card,
                ),
              );
            }),
          );
        },
      );
    });
  }
}

class _StatusInfo {
  const _StatusInfo({
    required this.status,
    required this.label,
    required this.gradient,
  });

  final StationStatus status;
  final String label;
  final Gradient gradient;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.info,
    required this.count,
    required this.total,
  });

  final _StatusInfo info;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double percentage = total == 0 ? 0 : (count / total) * 100;

    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: info.gradient,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            info.label.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$count',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
