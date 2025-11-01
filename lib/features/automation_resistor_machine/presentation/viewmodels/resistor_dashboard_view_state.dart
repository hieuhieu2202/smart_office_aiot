import 'dart:math' as math;

import '../../domain/entities/resistor_machine_entities.dart';

class ResistorSummaryTileData {
  const ResistorSummaryTileData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final int color;
}

class ResistorPieSlice {
  const ResistorPieSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final int color;
}

class ResistorStackedSeries {
  const ResistorStackedSeries({
    required this.categories,
    required this.pass,
    required this.fail,
    required this.yieldRate,
  });

  final List<String> categories;
  final List<int> pass;
  final List<int> fail;
  final List<double> yieldRate;
}

class ResistorDashboardViewState {
  const ResistorDashboardViewState({
    required this.summary,
    required this.summaryTiles,
    required this.summarySlices,
    required this.sectionSeries,
    required this.machineSeries,
  });

  final ResistorMachineSummary summary;
  final List<ResistorSummaryTileData> summaryTiles;
  final List<ResistorPieSlice> summarySlices;
  final ResistorStackedSeries sectionSeries;
  final ResistorStackedSeries machineSeries;

  factory ResistorDashboardViewState.fromTracking(
    ResistorMachineTrackingData tracking,
  ) {
    final summary = tracking.summary;
    final total = math.max(summary.total, 1);
    final passPercent = summary.pass / total * 100;
    final failPercent = summary.fail / total * 100;

    final summaryTiles = <ResistorSummaryTileData>[
      ResistorSummaryTileData(
        title: 'PASS',
        value: summary.pass.toString(),
        subtitle: 'Finished good quantity',
        color: 0xFF00E676,
      ),
      ResistorSummaryTileData(
        title: 'FAIL',
        value: summary.fail.toString(),
        subtitle: 'Defect quantity',
        color: 0xFFFF5252,
      ),
      ResistorSummaryTileData(
        title: 'RR',
        value: '${summary.retestRate.toStringAsFixed(2)}%',
        subtitle: 'Retest rate',
        color: 0xFFFFD740,
      ),
      ResistorSummaryTileData(
        title: 'YR',
        value: '${summary.yieldRate.toStringAsFixed(2)}%',
        subtitle: 'Yield rate',
        color: 0xFF40C4FF,
      ),
    ];

    final summarySlices = <ResistorPieSlice>[
      ResistorPieSlice(
        label: 'PASS ${passPercent.toStringAsFixed(1)}%',
        value: summary.pass,
        color: 0xFF00FFE7,
      ),
      ResistorPieSlice(
        label: 'FAIL ${failPercent.toStringAsFixed(1)}%',
        value: summary.fail,
        color: 0xFFFF004F,
      ),
    ];

    ResistorStackedSeries _buildSeries(List<dynamic> raw, bool isMachine) {
      final categories = <String>[];
      final pass = <int>[];
      final fail = <int>[];
      final yieldRate = <double>[];

      for (final item in raw) {
        if (item is ResistorMachineOutput) {
          categories.add(item.displayLabel);
          pass.add(item.pass);
          fail.add(item.fail);
          yieldRate.add(item.yieldRate);
        } else if (item is ResistorMachineInfo) {
          categories.add(item.name);
          pass.add(item.pass);
          fail.add(item.fail);
          yieldRate.add(item.yieldRate);
        }
      }

      if (categories.isEmpty) {
        categories.add(isMachine ? 'N/A' : 'S1');
        pass.add(0);
        fail.add(0);
        yieldRate.add(0);
      }

      return ResistorStackedSeries(
        categories: categories,
        pass: pass,
        fail: fail,
        yieldRate: yieldRate,
      );
    }

    final sectionSeries = _buildSeries(tracking.outputs, false);
    final machineSeries = _buildSeries(tracking.machines, true);

    return ResistorDashboardViewState(
      summary: summary,
      summaryTiles: summaryTiles,
      summarySlices: summarySlices,
      sectionSeries: sectionSeries,
      machineSeries: machineSeries,
    );
  }
}
