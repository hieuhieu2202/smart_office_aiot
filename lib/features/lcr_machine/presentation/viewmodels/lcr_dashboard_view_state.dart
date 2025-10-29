import '../../domain/entities/lcr_entities.dart';

class LcrPieSlice {
  const LcrPieSlice({required this.label, required this.value});

  final String label;
  final int value;
}

class LcrStackedSeries {
  const LcrStackedSeries({
    required this.categories,
    required this.pass,
    required this.fail,
  });

  final List<String> categories;
  final List<int> pass;
  final List<int> fail;
}

class LcrOutputTrend {
  const LcrOutputTrend({
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

class LcrMachineGauge {
  const LcrMachineGauge({
    required this.machineNo,
    required this.total,
    required this.pass,
    required this.fail,
  });

  final int machineNo;
  final int total;
  final int pass;
  final int fail;

  double get yieldRate => total == 0 ? 0 : pass / total * 100;
}

class LcrDashboardViewState {
  const LcrDashboardViewState({
    required this.overview,
    required this.factorySlices,
    required this.departmentSeries,
    required this.typeSeries,
    required this.employeeSeries,
    required this.outputTrend,
    required this.machineGauges,
    required this.errorSlices,
  });

  final LcrOverview overview;
  final List<LcrPieSlice> factorySlices;
  final LcrStackedSeries departmentSeries;
  final LcrStackedSeries typeSeries;
  final LcrStackedSeries employeeSeries;
  final LcrOutputTrend outputTrend;
  final List<LcrMachineGauge> machineGauges;
  final List<LcrPieSlice> errorSlices;

  factory LcrDashboardViewState.fromSources({
    required List<LcrRecord> trackingRecords,
    required List<LcrRecord> analysisRecords,
  }) {
    final Map<String, List<LcrRecord>> byFactory = <String, List<LcrRecord>>{};
    final Map<String, List<LcrRecord>> byDepartment = <String, List<LcrRecord>>{};
    final Map<String, List<LcrRecord>> byType = <String, List<LcrRecord>>{};
    final Map<String, List<LcrRecord>> byEmployee = <String, List<LcrRecord>>{};
    final Map<int, List<LcrRecord>> byMachine = <int, List<LcrRecord>>{};
    final Map<String, List<LcrRecord>> byError = <String, List<LcrRecord>>{};
    const startHour = 7;
    const endHour = 18;
    const shiftStartMinutes = startHour * 60 + 30;
    const shiftEndMinutes = (endHour + 1) * 60 + 30;
    final defaultSlotLabels = <String>[
      for (var hour = startHour; hour <= endHour; hour++)
        '${hour.toString().padLeft(2, '0')}:30 - '
            '${(hour + 1).toString().padLeft(2, '0')}:30',
    ];
    final Map<int, _SlotTotals> bySlot = <int, _SlotTotals>{};
    var trackingPassTotal = 0;
    var trackingFailTotal = 0;
    var analysisPassTotal = 0;
    var analysisFailTotal = 0;

    int _resolveQuantity(int? primary, int? secondary) {
      if (primary != null && primary > 0) return primary;
      if (secondary != null && secondary > 0) return secondary;
      return 1;
    }

    for (final record in trackingRecords) {
      final factoryKey = (record.factory.isEmpty ? 'UNKNOWN' : record.factory);
      byFactory.putIfAbsent(factoryKey, () => <LcrRecord>[]).add(record);

      final departmentKey =
          ((record.department ?? '').isEmpty ? 'UNKNOWN' : record.department!);
      byDepartment.putIfAbsent(departmentKey, () => <LcrRecord>[]).add(record);

      final typeKey = ((record.materialType ?? '').isEmpty
          ? (record.description ?? 'UNKNOWN')
          : record.materialType!);
      byType.putIfAbsent(typeKey, () => <LcrRecord>[]).add(record);

      final employeeKey =
          ((record.employeeId ?? '').isEmpty ? 'UNKNOWN' : record.employeeId!);
      byEmployee.putIfAbsent(employeeKey, () => <LcrRecord>[]).add(record);

      byMachine.putIfAbsent(record.machineNo, () => <LcrRecord>[]).add(record);

      final errorKey =
          ((record.description ?? '').isEmpty ? 'NO ERROR' : record.description!);
      byError.putIfAbsent(errorKey, () => <LcrRecord>[]).add(record);

      final isPass = record.status;
      final qty = isPass
          ? _resolveQuantity(record.qty, record.extQty)
          : _resolveQuantity(record.extQty, record.qty);
      if (isPass) {
        trackingPassTotal += qty;
      } else {
        trackingFailTotal += qty;
      }

      final totalMinutes = record.dateTime.hour * 60 + record.dateTime.minute;
      if (totalMinutes >= shiftStartMinutes && totalMinutes < shiftEndMinutes) {
        final slotIndex = (totalMinutes - shiftStartMinutes) ~/ 60;
        final slotHour = startHour + slotIndex;
        final bucket = bySlot.putIfAbsent(slotHour, () => _SlotTotals());
        if (isPass) {
          bucket.pass += qty;
        } else {
          bucket.fail += qty;
        }
      }
    }

    List<LcrPieSlice> _buildPie(Map<String, List<LcrRecord>> map,
        {bool includeZero = false}) {
      return map.entries
          .map((entry) => LcrPieSlice(
                label: entry.key,
                value: entry.value.length,
              ))
          .where((slice) => includeZero || slice.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    }

    LcrStackedSeries _buildStacked(Map<String, List<LcrRecord>> map) {
      final categories = map.keys.toList()..sort();
      final pass = <int>[];
      final fail = <int>[];
      for (final cat in categories) {
        final list = map[cat] ?? const <LcrRecord>[];
        final passCount = list.where((e) => e.status).length;
        pass.add(passCount);
        fail.add(list.length - passCount);
      }
      return LcrStackedSeries(categories: categories, pass: pass, fail: fail);
    }

    final factorySlices = _buildPie(byFactory);
    final departmentSeries = _buildStacked(byDepartment);
    final typeSeries = _buildStacked(byType);
    final employeeSeries = _buildStacked(byEmployee);
    final errorSlices = _buildPie(byError, includeZero: true);

    LcrOutputTrend _buildTrendFromTracking() {
      final outputPass = <int>[];
      final outputFail = <int>[];
      final outputYr = <double>[];
      final categoriesLabel = <String>[];

      for (var index = 0; index < defaultSlotLabels.length; index++) {
        final hour = startHour + index;
        final bucket = bySlot[hour];
        final passCount = bucket?.pass ?? 0;
        final failCount = bucket?.fail ?? 0;
        outputPass.add(passCount);
        outputFail.add(failCount);
        final total = passCount + failCount;
        final yr = total == 0 ? 0 : passCount / total * 100;
        outputYr.add(double.parse(yr.toStringAsFixed(2)));
        categoriesLabel.add(defaultSlotLabels[index]);
      }

      return LcrOutputTrend(
        categories: categoriesLabel,
        pass: outputPass,
        fail: outputFail,
        yieldRate: outputYr,
      );
    }

    LcrOutputTrend? _buildTrendFromAnalysis() {
      if (analysisRecords.isEmpty) {
        return null;
      }

      final Map<int, _SlotTotals> bySection = <int, _SlotTotals>{};
      final Map<int, String> extraSectionLabels = <int, String>{};
      final Map<String, _SlotTotals> fallbackByLabel = <String, _SlotTotals>{};
      final Map<String, int> fallbackOrder = <String, int>{};
      var orderCounter = 0;

      String? _normalizeSlotLabel(String? raw) {
        if (raw == null) {
          return null;
        }
        final trimmed = raw.trim();
        if (trimmed.isEmpty) {
          return null;
        }

        final timeMatches =
            RegExp(r'(\d{1,2})[:.](\d{2})').allMatches(trimmed).toList();
        if (timeMatches.length >= 2) {
          String _pad(String value) => value.padLeft(2, '0');
          final start = timeMatches.first;
          final end = timeMatches[1];
          final startHour = _pad(start.group(1)!);
          final startMinute = start.group(2)!;
          final endHour = _pad(end.group(1)!);
          final endMinute = end.group(2)!;
          return '$startHour:$startMinute - $endHour:$endMinute';
        }

        final looksLikeDate =
            RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}').hasMatch(trimmed);
        if (looksLikeDate) {
          return null;
        }

        final shiftLabelMatch =
            RegExp(r'ca\s*(\d{1,2})', caseSensitive: false).firstMatch(trimmed);
        if (shiftLabelMatch != null) {
          final slotIndex = int.tryParse(shiftLabelMatch.group(1)!);
          if (slotIndex != null) {
            return 'Ca ${slotIndex.toString().padLeft(2, '0')}';
          }
        }

        final digitsOnly = RegExp(r'^\d{1,2}$');
        if (digitsOnly.hasMatch(trimmed)) {
          return 'Ca ${trimmed.padLeft(2, '0')}';
        }

        return trimmed;
      }

      int? _slotIndexFromLabel(String label) {
        final defaultIndex = defaultSlotLabels
            .indexWhere((element) => element.toLowerCase() == label.toLowerCase());
        if (defaultIndex != -1) {
          return defaultIndex + 1;
        }

        final shiftLabelMatch =
            RegExp(r'ca\s*(\d{1,2})', caseSensitive: false).firstMatch(label);
        if (shiftLabelMatch != null) {
          return int.tryParse(shiftLabelMatch.group(1)!);
        }

        final digitsOnly = RegExp(r'^\d{1,2}$');
        if (digitsOnly.hasMatch(label)) {
          return int.tryParse(label);
        }

        final timeMatches =
            RegExp(r'(\d{1,2})[:.](\d{2})').allMatches(label).toList();
        if (timeMatches.isNotEmpty) {
          final start = timeMatches.first;
          final hour = int.tryParse(start.group(1)!);
          final minute = int.tryParse(start.group(2)!);
          if (hour != null && minute != null) {
            final totalMinutes = hour * 60 + minute;
            final offset = totalMinutes - shiftStartMinutes;
            if (offset >= 0 && offset % 60 == 0) {
              return offset ~/ 60 + 1;
            }
          }
        }

        return null;
      }

      void _applyQuantities(_SlotTotals bucket, LcrRecord record) {
        final passQty = (record.qty ?? 0) > 0 ? record.qty! : 0;
        final failQty = (record.extQty ?? 0) > 0 ? record.extQty! : 0;

        if (passQty == 0 && failQty == 0) {
          if (record.status) {
            bucket.pass += 1;
            analysisPassTotal += 1;
          } else {
            bucket.fail += 1;
            analysisFailTotal += 1;
          }
          return;
        }

        if (passQty > 0) {
          bucket.pass += passQty;
          analysisPassTotal += passQty;
        }
        if (failQty > 0) {
          bucket.fail += failQty;
          analysisFailTotal += failQty;
        }
      }

      for (final record in analysisRecords) {
        final candidates = <String?>[
          record.className,
          record.classDate,
        ];

        String? normalizedLabel;
        int? section = record.workSection > 0 ? record.workSection : null;

        for (final candidate in candidates) {
          final normalized = _normalizeSlotLabel(candidate);
          if (normalized == null) {
            continue;
          }
          normalizedLabel ??= normalized;
          section ??= _slotIndexFromLabel(normalized);
        }

        if (section != null) {
          final bucket = bySection.putIfAbsent(section, () => _SlotTotals());
          if (section > defaultSlotLabels.length && normalizedLabel != null) {
            extraSectionLabels.putIfAbsent(section, () => normalizedLabel);
          }
          _applyQuantities(bucket, record);
          continue;
        }

        if (normalizedLabel != null) {
          final bucket =
              fallbackByLabel.putIfAbsent(normalizedLabel, () => _SlotTotals());
          fallbackOrder.putIfAbsent(normalizedLabel, () => orderCounter++);
          _applyQuantities(bucket, record);
          continue;
        }

        const unknownLabel = 'UNKNOWN';
        final bucket =
            fallbackByLabel.putIfAbsent(unknownLabel, () => _SlotTotals());
        fallbackOrder.putIfAbsent(unknownLabel, () => orderCounter++);
        _applyQuantities(bucket, record);
      }

      if (bySection.isEmpty && fallbackByLabel.isEmpty) {
        return null;
      }

      final categories = <String>[];
      final pass = <int>[];
      final fail = <int>[];
      final yr = <double>[];

      void appendEntry(String label, _SlotTotals totals) {
        categories.add(label);
        pass.add(totals.pass);
        fail.add(totals.fail);
        final total = totals.pass + totals.fail;
        final yieldValue = total == 0 ? 0 : totals.pass / total * 100;
        yr.add(double.parse(yieldValue.toStringAsFixed(2)));
      }

      for (var section = 1; section <= defaultSlotLabels.length; section++) {
        final totals = bySection.remove(section) ?? _SlotTotals();
        appendEntry(defaultSlotLabels[section - 1], totals);
      }

      final remainingSections = bySection.keys.toList()..sort();
      for (final section in remainingSections) {
        final totals = bySection[section] ?? _SlotTotals();
        final label = extraSectionLabels[section] ??
            'Ca ${section.toString().padLeft(2, '0')}';
        appendEntry(label, totals);
      }

      final fallbackEntries = fallbackByLabel.entries.toList()
        ..sort((a, b) =>
            (fallbackOrder[a.key] ?? 0).compareTo(fallbackOrder[b.key] ?? 0));
      for (final entry in fallbackEntries) {
        appendEntry(entry.key, entry.value);
      }

      return LcrOutputTrend(
        categories: categories,
        pass: pass,
        fail: fail,
        yieldRate: yr,
      );
    }

    final analysisTrend = _buildTrendFromAnalysis();
    final bool usingAnalysisTrend = analysisTrend != null;
    final outputTrend = analysisTrend ?? _buildTrendFromTracking();

    final passTotal = usingAnalysisTrend ? analysisPassTotal : trackingPassTotal;
    final failTotal = usingAnalysisTrend ? analysisFailTotal : trackingFailTotal;
    final combinedTotal = passTotal + failTotal;
    final yieldRate = combinedTotal == 0 ? 0 : passTotal / combinedTotal * 100;
    final overview = LcrOverview(
      total: combinedTotal,
      pass: passTotal,
      fail: failTotal,
      yieldRate: double.parse(yieldRate.toStringAsFixed(2)),
    );

    final machineGauges = byMachine.entries.map((entry) {
      var passTotal = 0;
      var failTotal = 0;
      for (final record in entry.value) {
        if (record.status) {
          passTotal += _resolveQuantity(record.qty, record.extQty);
        } else {
          failTotal += _resolveQuantity(record.extQty, record.qty);
        }
      }
      final combined = passTotal + failTotal;
      return LcrMachineGauge(
        machineNo: entry.key,
        total: combined,
        pass: passTotal,
        fail: failTotal,
      );
    }).toList();

    const expectedMachineCount = 4;
    for (var machine = 1; machine <= expectedMachineCount; machine++) {
      final hasMachine = machineGauges.any((gauge) => gauge.machineNo == machine);
      if (!hasMachine) {
        machineGauges.add(
          LcrMachineGauge(
            machineNo: machine,
            total: 0,
            pass: 0,
            fail: 0,
          ),
        );
      }
    }

    machineGauges.sort((a, b) => a.machineNo.compareTo(b.machineNo));

    return LcrDashboardViewState(
      overview: overview,
      factorySlices: factorySlices,
      departmentSeries: departmentSeries,
      typeSeries: typeSeries,
      employeeSeries: employeeSeries,
      outputTrend: outputTrend,
      machineGauges: machineGauges,
      errorSlices: errorSlices,
    );
  }
}

class _SlotTotals {
  _SlotTotals({this.pass = 0, this.fail = 0});

  int pass;
  int fail;
}
