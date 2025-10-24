import 'dart:async';
import 'package:get/get.dart';
import '../../../service/nvidia_lc_switch_dashboard_curing_monitoring_api.dart';

class CuringMonitoringController extends GetxController {
  // ===== FILTER =====
  final customer = 'NVIDIA'.obs;
  final factoryName = 'F16'.obs;
  final floor = '3F'.obs;
  final location = 'ROOM1'.obs;
  final modelSerial = 'SWITCH'.obs;

  // ===== RAW =====
  final rawJson = Rxn<Map<String, dynamic>>();

  // ===== STATES =====
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final lastFetchIso = ''.obs;

  Timer? _timer;

  // ===== LOG GATE =====
  bool _verbose = false; // Mặc định tắt log
  /// Bật/tắt log từ bên ngoài (ví dụ trong initState/dispose của màn hình)
  void enableVerbose(bool on) => _verbose = on;

  void _log(String Function() builder) {
    if (_verbose) {
      print(builder());
    }
  }

  // ===== GETTERS (UI) =====
  Map<String, dynamic> get _data =>
      (rawJson.value?['Data'] as Map<String, dynamic>?) ?? {};

  int get wip => int.tryParse('${_data['Wip'] ?? 0}') ?? 0;

  int get pass => int.tryParse('${_data['Pass'] ?? 0}') ?? 0;

  List<Map<String, dynamic>> get passDetails =>
      List<Map<String, dynamic>>.from(_data['PassDetails'] ?? const []);

  List<Map<String, dynamic>> get sensorDatas =>
      List<Map<String, dynamic>>.from(_data['SensorDatas'] ?? const []);

  List<Map<String, dynamic>> get rackDetails {
    final list = List<Map<String, dynamic>>.from(
      _data['RackDetails'] ?? const [],
    );

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

      final nameA = (a['Name'] ?? '').toString();
      final nameB = (b['Name'] ?? '').toString();

      if (sa.toLowerCase() == 'finished') {
        final tA = _parseToSeconds((a['Time'] ?? '').toString());
        final tB = _parseToSeconds((b['Time'] ?? '').toString());
        final absA = tA == null ? -1 : tA.abs();
        final absB = tB == null ? -1 : tB.abs();
        if (absA != absB) return absB.compareTo(absA); // DESC by abs

        final numA =
            (a['Number'] is num)
                ? (a['Number'] as num).toInt()
                : _extractNumberFromName(nameA);
        final numB =
            (b['Number'] is num)
                ? (b['Number'] as num).toInt()
                : _extractNumberFromName(nameB);
        if (numA != numB) return numA.compareTo(numB);

        return _naturalNameCompare(nameA, nameB);
      }

      if (sa.toLowerCase() == 'running') {
        final pA = _toPercent(a['Percent']) ?? -1;
        final pB = _toPercent(b['Percent']) ?? -1;
        if (pA != pB) return pB.compareTo(pA); // DESC

        final numA =
            (a['Number'] is num)
                ? (a['Number'] as num).toInt()
                : _extractNumberFromName(nameA);
        final numB =
            (b['Number'] is num)
                ? (b['Number'] as num).toInt()
                : _extractNumberFromName(nameB);
        if (numA != numB) return numA.compareTo(numB);

        return _naturalNameCompare(nameA, nameB);
      }

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
        factory: factoryName.value,
        floor: floor.value,
        room: location.value,
        modelSerial: modelSerial.value,
      );

      final normalized = _normalizePayload(res);
      rawJson.value = {
        'Data': normalized,
        '_raw': res,
      };
      lastFetchIso.value = DateTime.now().toIso8601String();
      update();

      final data = normalized;
      final racks = List<Map<String, dynamic>>.from(
        data['RackDetails'] ?? const [],
      );
      final passDetails = List<Map<String, dynamic>>.from(
        data['PassDetails'] ?? const [],
      );

      //  Log đã GATED
      _log(
        () =>
            '✅ [${DateTime.now()}] Nhận dữ liệu: '
            'Wip=${data['Wip']} | Pass=${data['Pass']} | rackCount=${racks.length} | passDetailCount=${passDetails.length}',
      );
    } catch (e) {
      errorMessage.value = e.toString();
      _log(() => '❌ Lỗi khi fetch API: $e');
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  void refreshAll() => fetchData(showLoading: true);

  Future<List<Map<String, dynamic>>> fetchTrayDetails(String tray) async {
    final trimmedTray = tray.trim();
    if (trimmedTray.isEmpty) {
      return const [];
    }

    try {
      final response = await CuringMonitoringApi.fetchTrayData(
        customer: customer.value,
        factory: factoryName.value,
        floor: floor.value,
        room: location.value,
        modelSerial: modelSerial.value,
        tray: trimmedTray,
      );

      final normalized = _normalizeTrayDetails(response, trimmedTray);
      _log(() =>
          'ℹ️ Tray "$trimmedTray" contains ${normalized.length} serials');
      return normalized;
    } catch (e) {
      _log(() => '❌ Lỗi khi fetch tray "$trimmedTray": $e');
      rethrow;
    }
  }

  Map<String, dynamic> _normalizePayload(Map<String, dynamic> payload) {
    if (payload.containsKey('Data') &&
        payload['Data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(
        payload['Data'] as Map<String, dynamic>,
      );
    }

    num? _asNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value);
      return null;
    }

    int _asInt(dynamic value) => _asNum(value)?.toInt() ?? 0;

    double _asDouble(dynamic value) => _asNum(value)?.toDouble() ?? 0;

    List<Map<String, dynamic>> _toList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e is Map<String, dynamic>
                ? Map<String, dynamic>.from(e)
                : <String, dynamic>{})
            .toList();
      }
      return <Map<String, dynamic>>[];
    }

    final passDetails = _toList(
      payload['passDetails'] ?? payload['PassDetails'],
    )
        .map((item) => {
              'ModelName': item['modelName'] ?? item['ModelName'] ?? '',
              'Qty': _asInt(item['qty'] ?? item['Qty']),
            })
        .toList();

    final rackDetails = _toList(
      payload['rackDetails'] ?? payload['RackDetails'],
    )
        .map((item) => {
              'Name': item['name'] ?? item['Name'] ?? '',
              'Time': item['time'] ?? item['Time'] ?? '',
              'ModelName': item['modelName'] ?? item['ModelName'] ?? '',
              'Number': _asInt(item['number'] ?? item['Number']),
              'Status': item['status'] ?? item['Status'] ?? '',
              'Percent': _asDouble(item['percent'] ?? item['Percent']),
            })
        .toList();

    final sensorDatas = _toList(
      payload['sensorDatas'] ?? payload['SensorDatas'],
    )
        .map((item) => {
              'Name': item['name'] ?? item['Name'] ?? '',
              'Status': item['status'] ?? item['Status'] ?? '',
              'Value': _asDouble(item['value'] ?? item['Value']),
            })
        .toList();

    return {
      'Wip': _asInt(payload['wip'] ?? payload['Wip']),
      'Pass': _asInt(payload['pass'] ?? payload['Pass']),
      'PassDetails': passDetails,
      'RackDetails': rackDetails,
      'SensorDatas': sensorDatas,
    };
  }

  List<Map<String, dynamic>> _normalizeTrayDetails(
    List<Map<String, dynamic>> payload,
    String fallbackTray,
  ) {
    String _string(dynamic value) => value?.toString() ?? '';

    return payload
        .map((item) => Map<String, dynamic>.from(item))
        .map((item) {
      final serial = _string(
        item['serialNumber'] ?? item['seriaL_NUMBER'],
      );
      final model = _string(
        item['modelName'] ?? item['modeL_NAME'],
      );
      final tray = _string(
        item['trayNo'] ?? item['traY_NO'] ?? fallbackTray,
      );
      final wipGroup = _string(
        item['wipGroup'] ?? item['wiP_GROUP'],
      );
      final timeRaw = _string(
        item['inStationTime'] ?? item['iN_STATION_TIME'],
      );
      final displayTime = timeRaw.contains('T')
          ? timeRaw.replaceFirst('T', ' ').replaceAll('Z', '')
          : timeRaw;

      return {
        'SerialNumber': serial,
        'ModelName': model,
        'TrayNo': tray,
        'WipGroup': wipGroup,
        'InStationTime': timeRaw,
        'DisplayTime': displayTime,
        '_raw': item,
      };
    }).toList();
  }

  // ===== AUTO REFRESH (Timer) =====
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      // _log(() => ' Gọi fetchData() từ Timer lúc ${DateTime.now()}'); // GATED
      fetchData(showLoading: false);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void onInit() {
    super.onInit();
    fetchData(showLoading: true);
    _startTimer();
  }

  @override
  void onClose() {
    _stopTimer();
    super.onClose();
  }
}
