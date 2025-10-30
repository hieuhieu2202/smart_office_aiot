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

    final Map<String, List<LcrRecord>> byFactory = {};
    final Map<String, List<LcrRecord>> byDepartment = {};
    final Map<String, List<LcrRecord>> byType = {};
    final Map<String, List<LcrRecord>> byEmployee = {};
    final Map<int, List<LcrRecord>> byMachine = {};
    final Map<String, List<LcrRecord>> byError = {};

    const slotCount = 12; // 12 ca từ 07:30–19:30
    final Map<int, _SlotTotals> bySlot = {};
    final Map<int, List<String>> slotLogs = {};


    for (final record in records) {
      final factoryKey = record.factory.isEmpty ? 'UNKNOWN' : record.factory;
      byFactory.putIfAbsent(factoryKey, () => []).add(record);

      final departmentKey =
      (record.department ?? '').isEmpty ? 'UNKNOWN' : record.department!;
      byDepartment.putIfAbsent(departmentKey, () => []).add(record);

      final typeKey = (record.materialType ?? '').isEmpty
          ? (record.description ?? 'UNKNOWN')
          : record.materialType!;
      byType.putIfAbsent(typeKey, () => []).add(record);

      final employeeKey =
      (record.employeeId ?? '').isEmpty ? 'UNKNOWN' : record.employeeId!;
      byEmployee.putIfAbsent(employeeKey, () => []).add(record);

      byMachine.putIfAbsent(record.machineNo, () => []).add(record);

      final errorKey =
      (record.description ?? '').isEmpty ? 'NO ERROR' : record.description!;
      byError.putIfAbsent(errorKey, () => []).add(record);


      final dt = record.dateTime;
      int section = dt.minute > 0 ? dt.hour + 1 : dt.hour;
      if (section >= 24) section = 0;


      final startSection = 8;
      final slotIndex = section - startSection;
      if (slotIndex < 0 || slotIndex >= slotCount) continue;

      final bucket = bySlot.putIfAbsent(slotIndex, () => _SlotTotals());
      if (record.status) {
        bucket.pass += 1;
      } else {
        bucket.fail += 1;
      }

      final statusLabel = record.status ? 'PASS' : 'FAIL';
      final serial = (record.serialNumber?.isNotEmpty ?? false)
          ? record.serialNumber!
          : '-';
      final logLine =
          'serial=$serial machine=${record.machineNo} status=$statusLabel time=${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} (${dt.toIso8601String()})';
      slotLogs.putIfAbsent(slotIndex, () => []).add(logLine);
    }

    // 🔹 Nhóm dạng Pie & Stacked
    List<LcrPieSlice> _buildPie(Map<String, List<LcrRecord>> map,
        {bool includeZero = false}) {
      return map.entries
          .map((e) => LcrPieSlice(label: e.key, value: e.value.length))
          .where((s) => includeZero || s.value > 0)
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

    // Biểu đồ Output
    final outputPass = <int>[];
    final outputFail = <int>[];
    final outputYr = <double>[];
    final categoriesLabel = <String>[];

    for (var i = 0; i < slotCount; i++) {
      final section = (8 + i) % 24;
      final startHour = (section + 23) % 24;
      final endHour = section % 24;
      final startLabel = '${startHour.toString().padLeft(2, '0')}:30';
      final endLabel = '${endHour.toString().padLeft(2, '0')}:30';
      categoriesLabel.add('$startLabel - $endLabel');

      final bucket = bySlot[i];
      final passCount = bucket?.pass ?? 0;
      final failCount = bucket?.fail ?? 0;
      final total = passCount + failCount;
      final yr = total == 0 ? 0 : (passCount / total * 100);
      outputPass.add(passCount);
      outputFail.add(failCount);
      outputYr.add(double.parse(yr.toStringAsFixed(2)));

      // Log chi tiết từng slot
      final lines = slotLogs[i];
      final buffer = StringBuffer()
        ..write(
            'slot=$i [$startLabel - $endLabel] pass=$passCount fail=$failCount total=$total');
      if (lines != null && lines.isNotEmpty) {
        for (final line in lines) buffer.write('\n  - $line');
      }
      developer.log(buffer.toString(), name: 'LCR_OUTPUT_SLOT');
    }

    final outputTrend = LcrOutputTrend(
      categories: categoriesLabel,
      pass: outputPass,
      fail: outputFail,
      yieldRate: outputYr,
    );

    // ✅ Gauge theo máy
    final machineGauges = byMachine.entries.map((entry) {
      var passTotal = 0;
      var failTotal = 0;
      for (final record in entry.value) {
        if (record.status) {
          passTotal += record.qty ?? 1;
        } else {
          failTotal += record.extQty ?? 1;
        }
      }
      final total = passTotal + failTotal;
      return LcrMachineGauge(
        machineNo: entry.key,
        total: total,
        pass: passTotal,
        fail: failTotal,
      );
    }).toList();

    const expectedMachineCount = 4;
    for (var m = 1; m <= expectedMachineCount; m++) {
      if (!machineGauges.any((g) => g.machineNo == m)) {
        machineGauges.add(
            const LcrMachineGauge(machineNo: 0, total: 0, pass: 0, fail: 0));
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
