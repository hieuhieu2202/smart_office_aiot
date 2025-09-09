import 'dart:async';
import 'package:get/get.dart';
import '../../../service/nvidia_lc_switch_dashboard_curing_monitoring_api.dart';

class CuringMonitoringController extends GetxController {
  // ===== FILTER =====
  final customer    = 'NVIDIA'.obs;
  final factoryName = 'F16'.obs;
  final floor       = '3F'.obs;
  final location    = 'ROOM1'.obs;
  final modelSerial = 'SWITCH'.obs;

  // ===== RAW =====
  final rawJson = Rxn<Map<String, dynamic>>();

  // ===== STATES =====
  final isLoading      = false.obs;
  final errorMessage   = ''.obs;
  final lastFetchIso   = ''.obs;

  Timer? _timer;

  // ===== GETTERS (UI) =====
  Map<String, dynamic> get _data =>
      (rawJson.value?['Data'] as Map<String, dynamic>?) ?? {};

  int get wip  => int.tryParse('${_data['Wip'] ?? 0}') ?? 0;
  int get pass => int.tryParse('${_data['Pass'] ?? 0}') ?? 0;

  List<Map<String, dynamic>> get passDetails =>
      List<Map<String, dynamic>>.from(_data['PassDetails'] ?? const []);

  List<Map<String, dynamic>> get sensorDatas =>
      List<Map<String, dynamic>>.from(_data['SensorDatas'] ?? const []);


  List<Map<String, dynamic>> get rackDetails {
    final list = List<Map<String, dynamic>>.from(_data['RackDetails'] ?? const []);

    int _statusPriority(String s) {
      switch (s.toLowerCase()) {
        case 'finished':
          return 0;
        case 'running':
          return 1;
        default:
          return 2;
      }
    }

    int? _parseToSeconds(String? t) {
      if (t == null || t.isEmpty) return null;
      final neg = t.startsWith('-');
      final s = t.replaceFirst('-', '');
      final parts = s.split(':');
      if (parts.length != 2) return null;
      final mm = int.tryParse(parts[0]) ?? 0;
      final ss = int.tryParse(parts[1]) ?? 0;
      final total = mm * 60 + ss;
      return neg ? -total : total;
    }

    double? _toPercent(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int _extractNumberFromName(String name) {
      final m = RegExp(r'(\d+)$').firstMatch(name);
      return m != null ? int.tryParse(m.group(1)!) ?? 0 : 0;
    }

    int _naturalNameCompare(String a, String b) {
      final na = _extractNumberFromName(a);
      final nb = _extractNumberFromName(b);
      if (na != nb) return na.compareTo(nb);
      return a.compareTo(b);
    }

    list.sort((a, b) {
      final sa = (a['Status'] ?? '').toString();
      final sb = (b['Status'] ?? '').toString();

      final pa = _statusPriority(sa);
      final pb = _statusPriority(sb);
      if (pa != pb) return pa.compareTo(pb); // finished < running < others

      // Cùng nhóm
      final nameA = (a['Name'] ?? '').toString();
      final nameB = (b['Name'] ?? '').toString();

      if (sa.toLowerCase() == 'finished') {
        // |Time| GIẢM dần
        final tA = _parseToSeconds((a['Time'] ?? '').toString());
        final tB = _parseToSeconds((b['Time'] ?? '').toString());
        final absA = tA == null ? -1 : tA.abs();
        final absB = tB == null ? -1 : tB.abs();
        if (absA != absB) return absB.compareTo(absA); // DESC by abs

        final numA = (a['Number'] is num)
            ? (a['Number'] as num).toInt()
            : _extractNumberFromName(nameA);
        final numB = (b['Number'] is num)
            ? (b['Number'] as num).toInt()
            : _extractNumberFromName(nameB);
        if (numA != numB) return numA.compareTo(numB);

        return _naturalNameCompare(nameA, nameB);
      }

      if (sa.toLowerCase() == 'running') {
        // Percent GIẢM dần
        final pA = _toPercent(a['Percent']) ?? -1;
        final pB = _toPercent(b['Percent']) ?? -1;
        if (pA != pB) return pB.compareTo(pA); // DESC

        final numA = (a['Number'] is num)
            ? (a['Number'] as num).toInt()
            : _extractNumberFromName(nameA);
        final numB = (b['Number'] is num)
            ? (b['Number'] as num).toInt()
            : _extractNumberFromName(nameB);
        if (numA != numB) return numA.compareTo(numB);

        return _naturalNameCompare(nameA, nameB);
      }

      // others
      return _naturalNameCompare(nameA, nameB);
    });

    return list;
  }

  // ===== METHODS =====
  Future<void> fetchData({bool showLoading = false}) async {
    try {
      if (showLoading) isLoading.value = true;
      errorMessage.value = '';

      final res = await CuringMonitoringApi.fetch(
        customer: customer.value,
        factory:  factoryName.value,
        floor:    floor.value,
        location: location.value,
        modelSerial: modelSerial.value,
      );

      rawJson.value = res;                             // notify Obx
      lastFetchIso.value = DateTime.now().toIso8601String();
      update();                                        // ✅ nếu có GetBuilder ở đâu đó

      final data = res['Data'] ?? {};
      final racks = List<Map<String, dynamic>>.from(data['RackDetails'] ?? const []);
      final passDetails = List<Map<String, dynamic>>.from(data['PassDetails'] ?? const []);
      print('✅ [${DateTime.now()}] Nhận dữ liệu: Wip=${data['Wip']} | Pass=${data['Pass']} '
          '| rackCount=${racks.length} | passDetailCount=${passDetails.length}');
    } catch (e) {
      errorMessage.value = e.toString();
      print('❌ Lỗi khi fetch API: $e');
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  void refreshAll() => fetchData(showLoading: true);

  @override
  void onInit() {
    super.onInit();
    fetchData(showLoading: true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      print(' Gọi fetchData() từ Timer lúc ${DateTime.now()}');
      fetchData(showLoading: false);
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
