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
    final Map<DateTime, List<LcrRecord>> byHour = <DateTime, List<LcrRecord>>{};

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

      final hourKey = DateTime(record.dateTime.year, record.dateTime.month,
          record.dateTime.day, record.dateTime.hour);
      byHour.putIfAbsent(hourKey, () => <LcrRecord>[]).add(record);
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

    final outputCategories = byHour.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    final outputPass = <int>[];
    final outputFail = <int>[];
    final outputYr = <double>[];
    for (final hour in outputCategories) {
      final list = byHour[hour] ?? const <LcrRecord>[];
      final passCount = list.where((e) => e.status).length;
      final failCount = list.length - passCount;
      outputPass.add(passCount);
      outputFail.add(failCount);
      final yr = list.isEmpty ? 0 : passCount / list.length * 100;
      outputYr.add(double.parse(yr.toStringAsFixed(2)));
    }

    final categoriesLabel = outputCategories
        .map((dt) => '${dt.hour.toString().padLeft(2, '0')}:00')
        .toList();

    final outputTrend = LcrOutputTrend(
      categories: categoriesLabel,
      pass: outputPass,
      fail: outputFail,
      yieldRate: outputYr,
    );

    final machineGauges = byMachine.entries.map((entry) {
      final total = entry.value.length;
      final passCount = entry.value.where((e) => e.status).length;
      final failCount = total - passCount;
      return LcrMachineGauge(
        machineNo: entry.key,
        total: total,
        pass: passCount,
        fail: failCount,
      );
    }).toList()
      ..sort((a, b) => a.machineNo.compareTo(b.machineNo));

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
