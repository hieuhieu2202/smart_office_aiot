import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/pcba_line_api.dart';

class PcbaLinePoint {
  final DateTime date;
  final int pass;
  final int fail;
  PcbaLinePoint({required this.date, required this.pass, required this.fail});
}

class PcbaYieldPoint {
  final DateTime date;
  final double yieldRate;
  PcbaYieldPoint({required this.date, required this.yieldRate});
}

class PcbaLineDashboardController extends GetxController {
  // ===== FILTER STATE =====
  final rangeDateTime = ''.obs; // sẽ được set ở onInit()/màn hình
  final machineName = ''.obs;

  // ===== UI STATE =====
  final loading = false.obs;
  final errorMessage = RxnString();

  // ===== DATA SERIES (Daily) =====
  final passFailPoints = <PcbaLinePoint>[].obs;
  final yieldPoints = <PcbaYieldPoint>[].obs;
  final avgCycleTime = RxnDouble();

  // ===== KPI Tổng =====
  final totalPass = 0.obs;
  final totalFail = 0.obs;
  final totalYieldRate = 0.0.obs;

  // ===== Chi tiết theo máy =====
  final machineChartData = <Map<String, dynamic>>[].obs;

  String get formattedAvgCycleTime {
    final val = avgCycleTime.value;
    if (val == null) return '--';
    return '${NumberFormat('#,##0').format(val)} s';
  }

  String get formattedYieldRate {
    final val = totalYieldRate.value;
    return '${NumberFormat('#,##0.00').format(val)} %';
  }

  String _fmt(DateTime dt) => DateFormat('yyyy/MM/dd HH:mm').format(dt);

  /// end = hôm qua 19:30; start = end - 7 ngày 07:30 (8 ngày inclusive)
  void updateDefaultDateRange({bool force = true}) {
    if (!force && rangeDateTime.value.trim().isNotEmpty) return;

    final now = DateTime.now();
    final endDay = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final end = DateTime(endDay.year, endDay.month, endDay.day, 19, 30);
    final startDay = endDay.subtract(const Duration(days: 7));
    final start = DateTime(startDay.year, startDay.month, startDay.day, 7, 30);

    rangeDateTime.value = '${_fmt(start)} - ${_fmt(end)}';
  }

  @override
  void onInit() {
    super.onInit();
    updateDefaultDateRange(force: true);
    fetchAll();
  }

  Future<void> fetchAll() async {
    loading.value = true;
    errorMessage.value = null;

    try {
      final rawPF = await PcbaLineApi.fetchPassFailSeries(
        rangeDateTime: rangeDateTime.value,
        machineName: machineName.value,
      );

      final pfDaily = <PcbaLinePoint>[];
      int sumPass = 0, sumFail = 0;

      for (final dayList in rawPF) {
        final totalRec = dayList.firstWhere(
              (e) => e['Date'] != null,
          orElse: () => <String, dynamic>{},
        );
        if (totalRec.isNotEmpty) {
          final dateStr = totalRec['Date'] as String;
          final pass = (totalRec['Pass'] ?? 0) as int;
          final fail = (totalRec['Fail'] ?? 0) as int;

          final parts = dateStr.split('/');
          final dt = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );

          pfDaily.add(PcbaLinePoint(date: dt, pass: pass, fail: fail));
          sumPass += pass;
          sumFail += fail;
        }
      }

      final rawYield = await PcbaLineApi.fetchYieldRate(
        rangeDateTime: rangeDateTime.value,
        machineName: machineName.value,
      );

      final yDaily = <PcbaYieldPoint>[];
      for (final m in rawYield) {
        final dateStr = m['Date'] as String?;
        if (dateStr == null) continue;

        final parts = dateStr.split('/');
        final dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        final y = double.tryParse(m['Yield']?.toString() ?? '0') ?? 0;
        yDaily.add(PcbaYieldPoint(date: dt, yieldRate: y));
      }

      final avg = await PcbaLineApi.fetchAvgCycleTime(
        rangeDateTime: rangeDateTime.value,
        machineName: machineName.value,
      );

      pfDaily.sort((a, b) => a.date.compareTo(b.date));
      yDaily.sort((a, b) => a.date.compareTo(b.date));

      passFailPoints.assignAll(pfDaily);
      yieldPoints.assignAll(yDaily);
      avgCycleTime.value = avg;

      totalPass.value = sumPass;
      totalFail.value = sumFail;
      final denom = sumPass + sumFail;
      totalYieldRate.value = denom == 0 ? 0 : (sumPass / denom) * 100;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> fetchMachineChartDataForDate(DateTime date) async {
    try {
      final raw = await PcbaLineApi.fetchPassFailSeries(
        rangeDateTime: rangeDateTime.value,
        machineName: '',
      );

      final flat = raw.expand((e) => e).toList();

      final machineRecords = flat.where((e) {
        if (e['Date'] != null) return false;
        final dStr = e['CreateDate']?.toString() ?? '';
        if (dStr.isEmpty) return false;
        final dt = DateTime.tryParse(dStr);
        if (dt == null) return false;
        return dt.year == date.year && dt.month == date.month && dt.day == date.day;
      }).toList();

      machineChartData.assignAll(machineRecords);
    } catch (_) {
      machineChartData.clear();
    }
  }

  void applyRange(String newRange) {
    rangeDateTime.value = newRange;
    fetchAll();
  }

  void applyMachine(String name) {
    machineName.value = name;
    fetchAll();
  }

  void refreshAll() => fetchAll();
}
