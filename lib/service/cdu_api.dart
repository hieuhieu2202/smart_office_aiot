import 'dart:convert';
import 'package:http/http.dart' as http;

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
    final res = await http
        .post(
      Uri.parse('$_base/GetLastestDatas'),
      headers: _headers(),
      body: jsonEncode({'factory': factory, 'floor': floor}),
    )
        .timeout(timeout);

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
    final res = await http
        .post(
      Uri.parse('$_base/GetLastestLayout'),
      headers: _headers(),
      body: jsonEncode({'factory': factory, 'floor': floor}),
    )
        .timeout(timeout);

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
    final res = await http
        .post(
      Uri.parse('$_base/GetHistoryWarningDatas'),
      headers: _headers(),
      body: jsonEncode({'factory': factory, 'floor': floor}),
    )
        .timeout(timeout);

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
    final layout = await fetchLatestLayout(
        factory: factory, floor: floor, timeout: timeout);
    final monitors = await fetchLatestDatas(
        factory: factory, floor: floor, timeout: timeout);

    // ---------- Parse layout data ----------
    final raw = layout['data'];
    final List<dynamic> layoutList =
    raw is String ? jsonDecode(raw) : (raw ?? []);

    // ---------- Build monitor maps ----------
    final Map<String, Map<String, dynamic>> byCdu = {};
    final Map<String, Map<String, dynamic>> byIp = {};
    final Map<String, Map<String, dynamic>> byHost = {};

    for (final m in monitors) {
      if (m is! Map) continue;
      final map = Map<String, dynamic>.from(m);

      final cdu = map['cduName']?.toString().toUpperCase();
      final ip = map['ipAdress']?.toString().toLowerCase();
      final host = map['hostName']?.toString().toLowerCase();

      if (cdu != null) byCdu[cdu] = map;
      if (ip != null) byIp[ip] = map;
      if (host != null) byHost[host] = map;
    }

    // ---------- Merge layout + data ----------
    final List<Map<String, dynamic>> devices = [];

    for (final li in layoutList) {
      if (li is! Map) continue;
      final item = Map<String, dynamic>.from(li);

      final cduName = item['CDUName']?.toString().toUpperCase();
      final ip = item['IPAddress']?.toString().toLowerCase();
      final host = item['HostName']?.toString().toLowerCase();

      final mon =
          byCdu[cduName] ?? byIp[ip] ?? byHost[host];

      Map<String, dynamic>? dataMonitor;
      if (mon != null) {
        dataMonitor = {
          // ===== Tooltip fields (MATCH WEB) =====
          'amb_temp_t4': mon['ambTempT4'],
          'tcs_supply_temp_t1_1': mon['tcsSupplyTempT11'],
          'tcs_supply_temp_t1_2': mon['tcsSupplyTempT12'],
          'tcs_return_temp_t2': mon['tcsReturnTempT2'],
          'tcs_flow_f1': mon['tcsFlowF1'],
          'tcs_supply_pressure_p1': mon['tcsSupplyPressureP1'],
          'tcs_return_pressure_p2': mon['tcsReturnPressureP2'],
          'liquid_storage': mon['liquidStorage'],

          // ===== Status fields =====
          'run_status': mon['runStatus'],
          'tool_status': 'ON',
          'DateTime': mon['datetime'],
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

    // ---------- Summary (SAME AS WEB) ----------
    int running = 0, warning = 0, abnormal = 0;

    for (final d in devices) {
      final m = d['DataMonitor'] as Map<String, dynamic>?;
      if (m == null) continue;

      final bool liquid = m['liquid_storage'] == true;
      final String run = (m['run_status'] ?? '').toString().toUpperCase();

      if (liquid) {
        warning++;
      } else if (run != 'ON') {
        abnormal++;
      } else {
        running++;
      }
    }

    final summary = {
      'Total': devices.length,
      'Running': running,
      'Warning': warning,
      'Abnormal': abnormal,
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

}
