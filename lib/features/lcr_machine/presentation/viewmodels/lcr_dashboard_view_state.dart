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
    final overview = LcrOverview.fromRecords(trackingRecords);

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
    final Map<int, _SlotTotals> bySlot = <int, _SlotTotals>{};

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

      final totalMinutes = record.dateTime.hour * 60 + record.dateTime.minute;
      if (totalMinutes >= shiftStartMinutes && totalMinutes < shiftEndMinutes) {
        final slotIndex = (totalMinutes - shiftStartMinutes) ~/ 60;
        final slotHour = startHour + slotIndex;
        final bucket = bySlot.putIfAbsent(slotHour, () => _SlotTotals());
        if (record.status) {
          bucket.pass += _resolveQuantity(record.qty, record.extQty);
        } else {
          bucket.fail += _resolveQuantity(record.extQty, record.qty);
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

      for (var hour = startHour; hour <= endHour; hour++) {
        final bucket = bySlot[hour];
        final passCount = bucket?.pass ?? 0;
        final failCount = bucket?.fail ?? 0;
        outputPass.add(passCount);
        outputFail.add(failCount);
        final total = passCount + failCount;
        final yr = total == 0 ? 0 : passCount / total * 100;
        outputYr.add(double.parse(yr.toStringAsFixed(2)));
        final startLabel = '${hour.toString().padLeft(2, '0')}:30';
        final endLabel = '${(hour + 1).toString().padLeft(2, '0')}:30';
        categoriesLabel.add('$startLabel - $endLabel');
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

      final Map<String, _SlotTotals> grouped = <String, _SlotTotals>{};
      final Map<String, int> insertionOrder = <String, int>{};
      var order = 0;

      String? labelForRecord(LcrRecord record) {
        final className = record.className.trim();
        if (className.isNotEmpty) {
          return className;
        }
        final classDate = record.classDate.trim();
        if (classDate.isNotEmpty) {
          return classDate;
        }
        if (record.workSection != 0) {
          return record.workSection.toString();
        }
        return null;
      }

      int? sortKey(String label) {
        final rangeMatch = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(label);
        if (rangeMatch != null) {
          final hour = int.tryParse(rangeMatch.group(1)!);
          final minute = int.tryParse(rangeMatch.group(2)!);
          if (hour != null && minute != null) {
            return hour * 60 + minute;
          }
        }
        final digitMatch = RegExp(r'\d+').firstMatch(label);
        if (digitMatch != null) {
          return int.tryParse(digitMatch.group(0)!);
        }
        return null;
      }

      void accumulateQuantities(_SlotTotals bucket, LcrRecord record) {
        final passQty = record.qty ?? 0;
        final failQty = record.extQty ?? 0;
        final hasPassQty = passQty > 0;
        final hasFailQty = failQty > 0;

        if (!hasPassQty && !hasFailQty) {
          if (record.status) {
            bucket.pass += 1;
          } else {
            bucket.fail += 1;
          }
          return;
        }

        if (record.status) {
          if (hasPassQty) {
            bucket.pass += passQty;
          } else if (hasFailQty) {
            bucket.pass += failQty;
          }

          if (hasFailQty) {
            bucket.fail += failQty;
          }
          return;
        }

        if (hasFailQty) {
          bucket.fail += failQty;
          if (hasPassQty) {
            bucket.pass += passQty;
          }
          return;
        }

        bucket.fail += passQty;
      }

      for (final record in analysisRecords) {
        final label = labelForRecord(record);
        if (label == null) {
          continue;
        }
        final normalized = label.trim();
        if (normalized.isEmpty) {
          continue;
        }
        final bucket =
            grouped.putIfAbsent(normalized, () => _SlotTotals());
        insertionOrder.putIfAbsent(normalized, () => order++);

        accumulateQuantities(bucket, record);
      }

      if (grouped.isEmpty) {
        return null;
      }

      final entries = grouped.entries.toList()
        ..sort((a, b) {
          final aKey = sortKey(a.key);
          final bKey = sortKey(b.key);
          if (aKey != null && bKey != null) {
            final comparison = aKey.compareTo(bKey);
            if (comparison != 0) {
              return comparison;
            }
          } else if (aKey != null) {
            return -1;
          } else if (bKey != null) {
            return 1;
          }
          return insertionOrder[a.key]!.compareTo(insertionOrder[b.key]!);
        });

      final categories = <String>[];
      final pass = <int>[];
      final fail = <int>[];
      final yr = <double>[];

      for (final entry in entries) {
        categories.add(entry.key);
        pass.add(entry.value.pass);
        fail.add(entry.value.fail);
        final total = entry.value.pass + entry.value.fail;
        final yieldValue =
            total == 0 ? 0 : entry.value.pass / total * 100;
        yr.add(double.parse(yieldValue.toStringAsFixed(2)));
      }

      return LcrOutputTrend(
        categories: categories,
        pass: pass,
        fail: fail,
        yieldRate: yr,
      );
    }

    final outputTrend = _buildTrendFromAnalysis() ?? _buildTrendFromTracking();

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
