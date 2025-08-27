import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/pcba_line_api.dart';

class PcbaLinePoint {
  final DateTime date; // yyyy/MM/dd
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
  // ===== Filter state =====
  final rangeDateTime = '2025/08/12 07:30 - 2025/08/19 19:30'.obs;
  final machineName = ''.obs;

  // ===== UI state =====
  final loading = false.obs;
  final errorMessage = RxnString();

  // ===== Data series =====
  final passFailPoints = <PcbaLinePoint>[].obs;   // cho bar chart + card list
  final yieldPoints = <PcbaYieldPoint>[].obs;     // cho line chart
  final avgCycleTime = RxnDouble();               // KPI header

  // ===== KPI tổng =====
  final totalPass = 0.obs;
  final totalFail = 0.obs;
  final totalYieldRate = 0.0.obs; // % tổng = pass / (pass+fail) * 100

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      // 1) Pass/Fail
      final rawPF = await PcbaLineApi.fetchPassFailSeries(
        rangeDateTime: rangeDateTime.value,
        machineName: machineName.value,
      );

      // Lấy record có Date != null làm daily total
      final pfDaily = <PcbaLinePoint>[];
      int sumPass = 0, sumFail = 0;

      for (final dayList in rawPF) {
        final totalRec = dayList.firstWhere(
              (e) => e['Date'] != null,
          orElse: () => {},
        );
        if (totalRec.isNotEmpty) {
          final dateStr = totalRec['Date'] as String;
          final pass = (totalRec['Pass'] ?? 0) as int;
          final fail = (totalRec['Fail'] ?? 0) as int;

          final parts = dateStr.split('/');
          // "yyyy/MM/dd"
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

      // 2) Yield
      final rawYield = await PcbaLineApi.fetchYieldRate(
        rangeDateTime: rangeDateTime.value,
        machineName: machineName.value,
      );
      final yDaily = <PcbaYieldPoint>[];
      for (final m in rawYield) {
        final dateStr = m['Date'] as String?;
        final yieldStr = m['Yield']?.toString() ?? '0';
        if (dateStr == null) continue;

        final parts = dateStr.split('/');
        final dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final y = double.tryParse(yieldStr) ?? 0;
        yDaily.add(PcbaYieldPoint(date: dt, yieldRate: y));
      }

      // 3) Avg Cycle
      final avg = await PcbaLineApi.fetchAvgCycleTime(
        rangeDateTime: rangeDateTime.value,
        machineName: machineName.value,
      );

      // Cập nhật state
      passFailPoints.assignAll(pfDaily..sort((a, b) => a.date.compareTo(b.date)));
      yieldPoints.assignAll(yDaily..sort((a, b) => a.date.compareTo(b.date)));
      avgCycleTime.value = avg;

      totalPass.value = sumPass;
      totalFail.value = sumFail;
      final denom = (sumPass + sumFail);
      totalYieldRate.value = denom == 0 ? 0 : (sumPass / denom) * 100;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      loading.value = false;
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
