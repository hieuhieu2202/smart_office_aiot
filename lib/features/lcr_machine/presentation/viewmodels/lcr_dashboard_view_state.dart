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

    // 🔹 Ca bắt đầu 07:30, kết thúc 19:30 → 12 ca
    const startHour = 7;
    const startMinute = 30;
    const slotCount = 12;
    final Map<int, _SlotTotals> bySlot = {};
    final Map<int, List<String>> slotLogs = {};

    int _resolveQuantity(int? primary, int? secondary) {
      if (primary != null && primary > 0) return primary;
      if (secondary != null && secondary > 0) return secondary;
      return 1;
    }

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

      // ✅ Quy tắc chia ca chuẩn web
      final dt = record.dateTime;
      int slotIndex = dt.hour - startHour;
      if (dt.minute >= 30) slotIndex += 1;
      if (slotIndex < 0 || slotIndex >= slotCount) continue;

      final resolvedQty = record.status
          ? _resolveQuantity(record.qty, record.extQty)
          : _resolveQuantity(record.extQty, record.qty);
      final bucket = bySlot.putIfAbsent(slotIndex, () => _SlotTotals());
      if (record.status) {
        bucket.pass += 1;
      } else {
        bucket.fail += 1;
      }

      // logging cho từng record
      final statusLabel = record.status ? 'PASS' : 'FAIL';
      final serial =
      (record.serialNumber?.isNotEmpty ?? false) ? record.serialNumber! : '-';
      final logLine =
          'serial=$serial machine=${record.machineNo} status=$statusLabel qty=$resolvedQty '
          '(qty=${record.qty ?? '-'}, extQty=${record.extQty ?? '-'}) '
          'time=${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} (${dt.toIso8601String()})';
      slotLogs.putIfAbsent(slotIndex, () => []).add(logLine);
    }

    // ✅ Xử lý biểu đồ các nhóm
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

    // ✅ Biểu đồ Output
    final outputPass = <int>[];
    final outputFail = <int>[];
    final outputYr = <double>[];
    final categoriesLabel = <String>[];

    for (var slotIndex = 0; slotIndex < slotCount; slotIndex++) {
      final bucket = bySlot[slotIndex];
      final passCount = bucket?.pass ?? 0;
      final failCount = bucket?.fail ?? 0;
      outputPass.add(passCount);
      outputFail.add(failCount);
      final total = passCount + failCount;
      final yr = total == 0 ? 0 : passCount / total * 100;
      outputYr.add(double.parse(yr.toStringAsFixed(2)));

      // tạo label giờ
      final start =
      DateTime(0, 1, 1, startHour, startMinute).add(Duration(hours: slotIndex));
      final end = start.add(const Duration(hours: 1));
      final startLabel =
          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
      final endLabel =
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
      categoriesLabel.add('$startLabel - $endLabel');

      // log output
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

    // ✅ Gauge máy
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

    // Bổ sung máy trống nếu thiếu
    const expectedMachineCount = 4;
    for (var m = 1; m <= expectedMachineCount; m++) {
      if (!machineGauges.any((g) => g.machineNo == m)) {
        machineGauges.add(LcrMachineGauge(machineNo: m, total: 0, pass: 0, fail: 0));
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
