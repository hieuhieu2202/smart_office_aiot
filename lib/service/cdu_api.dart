import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return host == '10.220.130.117'; // chỉ trust đúng host này
    };
    return client;
  }
}

// IOClient dùng cho mobile/desktop. Flutter Web không bypass được self-signed.
final IOClient _ioClient = IOClient(
  HttpClient()..badCertificateCallback = (cert, host, port) => host == '10.220.130.117',
);

class CduApi {
  CduApi._();

  static const String _base =
      'https://10.220.130.117/api/nvidia/dashboard/CduMonitor';

  static Map<String, String> _headers() => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  // ======================================================
  // RAW API
  // ======================================================

  static Future<List<dynamic>> fetchLatestDatas({
    required String factory,
    required String floor,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final res = await _ioClient
        .post(
      Uri.parse('$_base/GetLastestDatas'),
      headers: _headers(),
      body: jsonEncode({'factory': factory, 'floor': floor}),
    )
        .timeout(timeout);

    _log(res, 'GetLastestDatas');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }
    throw Exception('GetLastestDatas failed ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> fetchLatestLayout({
    required String factory,
    required String floor,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final res = await _ioClient
        .post(
      Uri.parse('$_base/GetLastestLayout'),
      headers: _headers(),
      body: jsonEncode({'factory': factory, 'floor': floor}),
    )
        .timeout(timeout);

    _log(res, 'GetLastestLayout');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('GetLastestLayout failed ${res.statusCode}');
  }

  static Future<List<dynamic>> fetchHistoryWarningDatas({
    required String factory,
    required String floor,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final res = await _ioClient
        .post(
      Uri.parse('$_base/GetHistoryWarningDatas'),
      headers: _headers(),
      body: jsonEncode({'factory': factory, 'floor': floor}),
    )
        .timeout(timeout);

    _log(res, 'GetHistoryWarningDatas');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }
    throw Exception('GetHistoryWarningDatas failed ${res.statusCode}');
  }

  // ======================================================
  // DASHBOARD (FLUTTER USE)
  // ======================================================

  static Future<Map<String, dynamic>> fetchDashboard({
    required String factory,
    required String floor,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final layout =
    await fetchLatestLayout(factory: factory, floor: floor, timeout: timeout);
    final monitors =
    await fetchLatestDatas(factory: factory, floor: floor, timeout: timeout);

    // ---------- Parse layout data ----------
    final raw = layout['data'];
    final List<dynamic> layoutList =
    raw is String ? jsonDecode(raw) : (raw ?? []);

    // ---------- Dedup monitors theo (ip, cdu, model, host) & chọn bản mới nhất ----------
    final Map<String, Map<String, dynamic>> latestByKey = {};
    for (final m in monitors) {
      if (m is! Map) continue;
      final map = Map<String, dynamic>.from(m);
      final ip = map['ipAdress']?.toString().toLowerCase() ?? '';
      final cdu = map['cduName']?.toString().toUpperCase() ?? '';
      final model = map['modelName']?.toString() ?? '';
      final host = map['hostName']?.toString().toLowerCase() ?? '';
      final key = '$ip|$cdu|$model|$host';
      _updateLatestByDatetimeAndId(latestByKey, key, map);
    }

    // Xây chỉ mục phục vụ ghép layout
    final Map<String, List<Map<String, dynamic>>> byIpCdu = {};
    final Map<String, List<Map<String, dynamic>>> byIp = {};
    final Map<String, List<Map<String, dynamic>>> byHost = {};
    final Map<String, List<Map<String, dynamic>>> byCdu = {};

    void addIndex(Map<String, List<Map<String, dynamic>>> idx, String? key, Map<String, dynamic> v) {
      if (key == null || key.isEmpty) return;
      (idx[key] ??= []).add(v);
    }

    for (final map in latestByKey.values) {
      final ip = map['ipAdress']?.toString().toLowerCase();
      final cdu = map['cduName']?.toString().toUpperCase();
      final host = map['hostName']?.toString().toLowerCase();
      addIndex(byIpCdu, '${ip}_$cdu', map);
      addIndex(byIp, ip, map);
      addIndex(byHost, host, map);
      addIndex(byCdu, cdu, map);
    }

    Map<String, dynamic>? pickBest(List<Map<String, dynamic>> list) {
      if (list.isEmpty) return null;
      list.sort((a, b) => _compareDatetimeIdDesc(a, b));
      return list.first;
    }

    // ---------- Merge layout + data ----------
    final List<Map<String, dynamic>> devices = [];

    for (final li in layoutList) {
      if (li is! Map) continue;
      final item = Map<String, dynamic>.from(li);

      final cduName = item['CDUName']?.toString().toUpperCase();
      final ip = item['IPAddress']?.toString().toLowerCase();
      final host = item['HostName']?.toString().toLowerCase();

      Map<String, dynamic>? mon;
      mon ??= pickBest(byIpCdu['${ip}_$cduName'] ?? []);
      mon ??= pickBest(byIp[ip] ?? []);
      mon ??= pickBest(byHost[host] ?? []);
      mon ??= pickBest(byCdu[cduName] ?? []);

      Map<String, dynamic>? dataMonitor;
      if (mon != null) {
        dataMonitor = {
          // Alias snake_case (UI đang dùng)
          'amb_temp_t4': mon['ambTempT4'],
          'tcs_temp_t1': mon['tcsSupplyTempT11'],
          'tcs_temp_t1_1': mon['tcsSupplyTempT11'],
          'tcs_temp_t1_2': mon['tcsSupplyTempT12'],
          'tcs_temp_t2': mon['tcsReturnTempT2'],
          'tcs_flow_f1': mon['tcsFlowF1'],
          'pressure_p1': mon['tcsSupplyPressureP1'],
          'pressure_p2': mon['tcsReturnPressureP2'],
          'liquid_storage': mon['liquidStorage'],
          'run_status': mon['runStatus'],
          'tool_status': 'ON',
          'update_time': mon['datetime'],
          'datetime': mon['datetime'],

          // Alias theo tên gốc API (phòng khi UI đọc trực tiếp)
          'ambTempT4': mon['ambTempT4'],
          'tcsSupplyTempT11': mon['tcsSupplyTempT11'],
          'tcsSupplyTempT12': mon['tcsSupplyTempT12'],
          'tcsReturnTempT2': mon['tcsReturnTempT2'],
          'tcsFlowF1': mon['tcsFlowF1'],
          'tcsSupplyPressureP1': mon['tcsSupplyPressureP1'],
          'tcsReturnPressureP2': mon['tcsReturnPressureP2'],
          'liquidStorage': mon['liquidStorage'],
          'runStatus': mon['runStatus'],
          // info bổ sung
          'ip_adress': mon['ipAdress'],
          'cdu_name': mon['cduName'],
          'host_name': mon['hostName'],
          'model_name': mon['modelName'],
        };
      }

      devices.add({
        'CDUName': cduName,
        'IPAddress': item['IPAddress'],
        'HostName': item['HostName'],
        'Top': item['Top'] ?? 0,
        'Left': item['Left'] ?? 0,
        'Width': item['Width'] ?? 5,
        'Height': item['Height'] ?? 5,
        'DataMonitor': dataMonitor,
      });
    }

    // ---------- Summary (Warning / Running / Offline) ----------
    int running = 0, warning = 0, offline = 0;

    for (final d in devices) {
      final m = d['DataMonitor'] as Map<String, dynamic>?;
      if (m == null) {
        offline++;
        continue;
      }

      final bool liquid = m['liquid_storage'] == true;
      final String run = (m['run_status'] ?? '').toString().toUpperCase();

      if (liquid) {
        warning++;
      } else if (run == 'ON') {
        running++;
      } else {
        offline++;
      }
    }

    final summary = {
      'Total': devices.length,
      'Running': running,
      'Warning': warning,
      'Abnormal': offline, // hoặc đổi label thành Offline ở UI
    };

    return {
      'Data': {
        'Image': layout['image'] ?? '',
        'Data': devices,
        'Summary': summary,
      }
    };
  }

  static Future<Map<String, dynamic>> fetchDetailHistory({
    required String factory,
    required String floor,
  }) async {
    final list =
    await fetchHistoryWarningDatas(factory: factory, floor: floor);
    return {'Data': list};
  }

  static String webDashboardUrl({
    required String factory,
    required String floor,
  }) {
    return 'https://10.220.130.117/NVIDIA/CDU/DashBoard'
        '?Factory=$factory&Floor=$floor';
  }

  // Helpers
  static void _log(http.Response res, String label) {
    // ignore: avoid_print
    print('[$label] status=${res.statusCode} body=${utf8.decode(res.bodyBytes)}');
  }

  static void _updateLatestByDatetimeAndId(
      Map<String, Map<String, dynamic>> map,
      String key,
      Map<String, dynamic> record,
      ) {
    final current = map[key];
    if (current == null) {
      map[key] = record;
      return;
    }
    if (_compareDatetimeIdDesc(record, current) < 0) {
      map[key] = record;
    }
  }

  // Comparator: newer first (datetime DESC, id DESC)
  static int _compareDatetimeIdDesc(Map<String, dynamic> a, Map<String, dynamic> b) {
    final da = _parseDt(a['datetime']);
    final db = _parseDt(b['datetime']);
    if (da != null && db != null && da.isAfter(db)) return -1;
    if (da != null && db != null && da.isBefore(db)) return 1;
    final ia = _parseInt(a['id']);
    final ib = _parseInt(b['id']);
    if (ia != null && ib != null && ia > ib) return -1;
    if (ia != null && ib != null && ia < ib) return 1;
    return 0;
  }

  static DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    return int.tryParse(v.toString());
  }
}