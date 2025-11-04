import 'package:intl/intl.dart';

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
    required this.sections,
    required this.shiftStartMinutes,
  });

  final List<String> categories;
  final List<int> pass;
  final List<int> fail;
  final List<double> yieldRate;
  final List<int?> sections;
  final List<int?> shiftStartMinutes;
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
    ResistorMachineTrackingData tracking, {
    bool aggregateOutputsByDay = false,
  }) {
    final summary = tracking.summary;
    final outputs =
        aggregateOutputsByDay ? _aggregateOutputsByDay(tracking.outputs) : tracking.outputs;

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
      final sections = <int?>[];
      final shiftStartMinutes = <int?>[];

      for (final item in raw) {
        if (item is ResistorMachineOutput) {
          categories.add(item.displayLabel);
          pass.add(item.pass);
          fail.add(item.fail);
          yieldRate.add(item.yieldRate);
          sections.add(item.section);
          shiftStartMinutes.add(_computeShiftStartMinutes(item));
        } else if (item is ResistorMachineInfo) {
          categories.add(item.name);
          pass.add(item.pass);
          fail.add(item.fail);
          yieldRate.add(item.yieldRate);
          sections.add(null);
          shiftStartMinutes.add(null);
        }
      }

      if (categories.isEmpty) {
        categories.add(isMachine ? 'N/A' : 'S1');
        pass.add(0);
        fail.add(0);
        yieldRate.add(0);
        sections.add(null);
        shiftStartMinutes.add(null);
      }

      return ResistorStackedSeries(
        categories: categories,
        pass: pass,
        fail: fail,
        yieldRate: yieldRate,
        sections: sections,
        shiftStartMinutes: shiftStartMinutes,
      );
    }

    final sectionSeries = _buildSeries(outputs, false);
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

const int _resistorShiftStartMinute = 7 * 60 + 30;

int? _computeShiftStartMinutes(ResistorMachineOutput output) {
  final raw = output.workDate?.trim();
  if (raw != null && raw.isNotEmpty) {
    DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null && raw.contains(' ')) {
      parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    }
    if (parsed == null && raw.contains('/')) {
      final normalized = raw.replaceAll('/', '-');
      parsed = DateTime.tryParse(normalized);
      if (parsed == null && normalized.contains(' ')) {
        parsed = DateTime.tryParse(normalized.replaceFirst(' ', 'T'));
      }
    }
    if (parsed != null) {
      return parsed.hour * 60 + parsed.minute;
    }

    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match != null) {
      final hour = int.tryParse(match.group(1)!);
      final minute = int.tryParse(match.group(2)!);
      if (hour != null && minute != null) {
        return hour * 60 + minute;
      }
    }
  }

  final section = output.section;
  if (section != null && section > 0) {
    return _resistorShiftStartMinute + (section - 1) * 60;
  }

  return null;
}

List<ResistorMachineOutput> _aggregateOutputsByDay(
  List<ResistorMachineOutput> outputs,
) {
  if (outputs.isEmpty) return outputs;

  final buckets = <String, _DailyBucket>{};

  for (final output in outputs) {
    final resolved = _resolveOutputDateInfo(output);
    final key = resolved.label;
    final bucket = buckets.putIfAbsent(
      key,
      () => _DailyBucket(label: resolved.label, sortKey: resolved.date),
    );

    bucket.pass += output.pass;
    bucket.fail += output.fail;
    bucket.firstFail += output.firstFail;
    bucket.retest += output.retest;
  }

  final sortedBuckets = buckets.values.toList()
    ..sort((a, b) {
      final aDate = a.sortKey;
      final bDate = b.sortKey;
      if (aDate != null && bDate != null) {
        return aDate.compareTo(bDate);
      }
      if (aDate != null) return -1;
      if (bDate != null) return 1;
      return a.label.compareTo(b.label);
    });

  return sortedBuckets.map((bucket) {
    final total = bucket.pass + bucket.fail;
    final yieldRate = total == 0 ? 0.0 : bucket.pass / total * 100;
    final retestRate = total == 0 ? 0.0 : bucket.retest / total * 100;
    return ResistorMachineOutput(
      section: null,
      workDate: bucket.label,
      startTime: bucket.sortKey,
      pass: bucket.pass,
      fail: bucket.fail,
      firstFail: bucket.firstFail,
      retest: bucket.retest,
      yieldRate: double.parse(yieldRate.toStringAsFixed(2)),
      retestRate: double.parse(retestRate.toStringAsFixed(2)),
    );
  }).toList();
}

_ResolvedDateInfo _resolveOutputDateInfo(ResistorMachineOutput output) {
  final startTime = output.startTime;
  if (startTime != null) {
    final date = DateTime(startTime.year, startTime.month, startTime.day);
    final label = DateFormat('yyyy-MM-dd').format(date);
    return _ResolvedDateInfo(label: label, date: date);
  }

  final parsed = _parseDateString(output.workDate);
  if (parsed != null) {
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    final label = DateFormat('yyyy-MM-dd').format(date);
    return _ResolvedDateInfo(label: label, date: date);
  }

  final fallback = (output.workDate ?? output.displayLabel).trim();
  if (fallback.isNotEmpty) {
    return _ResolvedDateInfo(label: fallback, date: null);
  }
  return const _ResolvedDateInfo(label: 'N/A', date: null);
}

DateTime? _parseDateString(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;

  DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null && value.contains(' ')) {
    parsed = DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }
  if (parsed == null && value.contains('/')) {
    final normalized = value.replaceAll('/', '-');
    parsed = DateTime.tryParse(normalized);
    if (parsed == null && normalized.contains(' ')) {
      parsed = DateTime.tryParse(normalized.replaceFirst(' ', 'T'));
    }
  }
  if (parsed != null) {
    return parsed;
  }

  final match = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(value);
  if (match != null) {
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }

  return null;
}

class _DailyBucket {
  _DailyBucket({required this.label, required this.sortKey});

  final String label;
  final DateTime? sortKey;
  int pass = 0;
  int fail = 0;
  int firstFail = 0;
  int retest = 0;
}

class _ResolvedDateInfo {
  const _ResolvedDateInfo({required this.label, required this.date});

  final String label;
  final DateTime? date;
}
