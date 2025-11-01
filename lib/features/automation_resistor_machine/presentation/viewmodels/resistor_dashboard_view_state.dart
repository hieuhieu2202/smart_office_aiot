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
    int? pass,
  }) : _pass = pass;

  final String label;
  final int value;
  final int color;
  final int? _pass;

  int get pass => _pass ?? 0;
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
    List<ResistorPieSlice>? failDistributionSlices,
    int? failTotal,
    required this.sectionSeries,
    required this.machineSeries,
  })  : _failDistributionSlices = failDistributionSlices,
        _failTotal = failTotal;

  final ResistorMachineSummary summary;
  final List<ResistorSummaryTileData> summaryTiles;
  final List<ResistorPieSlice>? _failDistributionSlices;
  final int? _failTotal;
  final ResistorStackedSeries sectionSeries;
  final ResistorStackedSeries machineSeries;

  static const ResistorPieSlice _defaultFailSlice = ResistorPieSlice(
    label: 'N/A',
    value: 0,
    color: 0xFF00FFE7,
  );

  List<ResistorPieSlice> get failDistributionSlices {
    final slices = _failDistributionSlices;
    if (slices == null || slices.isEmpty) {
      return const [_defaultFailSlice];
    }
    return slices;
  }

  int get failTotal {
    final total = _failTotal;
    if (total != null && total > 0) {
      return total;
    }

    final slices = failDistributionSlices;
    final computed = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    if (computed > 0) {
      return computed;
    }

    return summary.fail;
  }

  factory ResistorDashboardViewState.fromTracking(
    ResistorMachineTrackingData tracking,
  ) {
    final summary = tracking.summary;

    final summaryTiles = <ResistorSummaryTileData>[
      ResistorSummaryTileData(
        title: 'WIP',
        value: summary.wip.toString(),
        subtitle: 'Work in progress',
        color: 0xFF00B0FF,
      ),
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
        title: 'YR',
        value: '${summary.yieldRate.toStringAsFixed(2)}%',
        subtitle: 'Yield rate',
        color: 0xFF40C4FF,
      ),
      ResistorSummaryTileData(
        title: 'RR',
        value: '${summary.retestRate.toStringAsFixed(2)}%',
        subtitle: 'Retest rate',
        color: 0xFFFFD740,
      ),
      ResistorSummaryTileData(
        title: 'FIRST FAIL',
        value: summary.firstFail.toString(),
        subtitle: 'First time failure',
        color: 0xFF9575CD,
      ),
      ResistorSummaryTileData(
        title: 'RETEST',
        value: summary.retest.toString(),
        subtitle: 'Retest quantity',
        color: 0xFFFF8A65,
      ),
    ];

    final failPalette = <int>[
      0xFF00FFE7,
      0xFFFF004F,
      0xFF40C4FF,
      0xFFFFD740,
      0xFF9575CD,
      0xFFFF8A65,
      0xFF69F0AE,
      0xFF82B1FF,
      0xFFFFAB91,
      0xFFFFF176,
    ];

    final failDistributionSlices = <ResistorPieSlice>[];

    final machinesByFail = List<ResistorMachineInfo>.from(tracking.machines)
      ..sort((a, b) => b.fail.compareTo(a.fail));

    for (var i = 0; i < machinesByFail.length; i++) {
      final machine = machinesByFail[i];
      if (machine.fail <= 0) {
        continue;
      }
      failDistributionSlices.add(
        ResistorPieSlice(
          label: machine.name,
          value: machine.fail,
          color: failPalette[i % failPalette.length],
          pass: machine.pass,
        ),
      );
    }

    if (failDistributionSlices.isEmpty) {
      failDistributionSlices.add(
        const ResistorPieSlice(
          label: 'N/A',
          value: 0,
          color: 0xFF00FFE7,
        ),
      );
    }

    final failTotal = failDistributionSlices.fold<int>(
      0,
      (sum, slice) => sum + slice.value,
    );

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
      failDistributionSlices: failDistributionSlices,
      failTotal: failTotal == 0 ? summary.fail : failTotal,
      sectionSeries: sectionSeries,
      machineSeries: machineSeries,
    );
  }
}
