import 'dart:developer' as developer;

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

  factory LcrDashboardViewState.fromRecords(List<LcrRecord> records) {
    final overview = LcrOverview.fromRecords(records);

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
    const slotCount = endHour - startHour + 1;
    final Map<int, _SlotTotals> bySlot = <int, _SlotTotals>{};
    final Map<int, List<String>> slotLogs = <int, List<String>>{};

    int _resolveQuantity(int? primary, int? secondary) {
      if (primary != null && primary > 0) return primary;
      if (secondary != null && secondary > 0) return secondary;
      return 1;
    }

    for (final record in records) {
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
      int? slotIndex;
      if (record.workSection > 0 && record.workSection <= slotCount) {
        slotIndex = record.workSection - 1;
      } else if (totalMinutes >= shiftStartMinutes &&
          totalMinutes < shiftEndMinutes) {
        slotIndex = (totalMinutes - shiftStartMinutes) ~/ 60;
      }
      if (slotIndex != null) {
        final resolvedQty = record.status
            ? _resolveQuantity(record.qty, record.extQty)
            : _resolveQuantity(record.extQty, record.qty);
        final bucket = bySlot.putIfAbsent(slotIndex, () => _SlotTotals());
        if (record.status) {
          bucket.pass += resolvedQty;
        } else {
          bucket.fail += resolvedQty;
        }

        final assignment = (record.workSection > 0 &&
                record.workSection <= slotCount)
            ? 'workSection=${record.workSection}'
            : 'time=${record.dateTime.hour.toString().padLeft(2, '0')}:${record.dateTime.minute.toString().padLeft(2, '0')} (${record.dateTime.toIso8601String()})';
        final statusLabel = record.status ? 'PASS' : 'FAIL';
        final serial =
            (record.serialNumber?.isNotEmpty ?? false) ? record.serialNumber! : '-';
        final logLine =
            'serial=$serial machine=${record.machineNo} status=$statusLabel qty=$resolvedQty'
            ' (qty=${record.qty ?? '-'}, extQty=${record.extQty ?? '-'}) source=$assignment';
        slotLogs.putIfAbsent(slotIndex, () => <String>[]).add(logLine);
      } else {
        final serial =
            (record.serialNumber?.isNotEmpty ?? false) ? record.serialNumber! : '-';
        final timeLabel =
            '${record.dateTime.hour.toString().padLeft(2, '0')}:${record.dateTime.minute.toString().padLeft(2, '0')}';
        developer.log(
          'Skipped record serial=$serial machine=${record.machineNo} status=${record.status ? 'PASS' : 'FAIL'} outside shift window at $timeLabel (section=${record.workSection})',
          name: 'LCR_OUTPUT_BUCKET',
        );
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

    final outputPass = <int>[];
    final outputFail = <int>[];
    final outputYr = <double>[];
    final categoriesLabel = <String>[];

    for (var slotIndex = 0; slotIndex < slotCount; slotIndex++) {
      final bucket = bySlot[slotIndex];
      final hour = startHour + slotIndex;
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

      final lines = slotLogs[slotIndex];
      final buffer = StringBuffer()
        ..write(
            'slot=$slotIndex [$startLabel - $endLabel] pass=$passCount fail=$failCount total=$total');
      if (lines == null || lines.isEmpty) {
        buffer.write(' (no records)');
      } else {
        for (final entry in lines) {
          buffer.write('\n  - ');
          buffer.write(entry);
        }
      }
      developer.log(buffer.toString(), name: 'LCR_OUTPUT_BUCKET');
    }

    final outputTrend = LcrOutputTrend(
      categories: categoriesLabel,
      pass: outputPass,
      fail: outputFail,
      yieldRate: outputYr,
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
