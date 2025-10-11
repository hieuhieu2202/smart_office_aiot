import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_helper.dart';

class KanbanApiLog {
  static bool network = false;

  static void net(String Function() b) {
    if (network) print(b());
  }
}

class KanbanApi {
  KanbanApi._();

  // Base gốc cho toàn bộ kanban
  static const String _base = 'https://10.220.130.117/newweb/api/nvidia/kanban';
  static const Duration _timeout = Duration(seconds: 45);

  static Map<String, String> _headers() => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
  };

  // ============ Body chuẩn cho các API tracking (giữ nguyên) ============
  static Map<String, dynamic> buildBody({
    String modelSerial = 'SWITCH',
    required String date, // yyyy-MM-dd
    String shift = 'Day',
    String dateRange = 'string',
    List<String> groups = const ['699-1T363-0100-000'],
    String section = 'string',
    String station = 'string',
    String line = 'string',
    String customer = 'string',
    String nickName = 'string',
    String modelName = 'string',
  }) => {
    'modelSerial': modelSerial,
    'date': date,
    'shift': shift,
    'dateRange': dateRange,
    'groups': groups,
    'section': section,
    'station': station,
    'line': line,
    'customer': customer,
    'nickName': nickName,
    'modelName': modelName,
  };

  // ============ NEW: Lấy danh sách groups/models đúng endpoint ============
  /// POST: /Sfis/GetGroupsByShift
  /// Chỉ cần: modelSerial, date(yyyymmdd), shift. Các field khác để trống.
  /// Luôn gửi groups=[] để server trả full danh sách.
  static Future<List<String>> getGroupsByShift({
    required String modelSerial,
    required String dateYmd, // yyyy-MM-dd
    required String shift,
  }) async {
    final uri = Uri.parse('$_base/Sfis/GetGroupsByShift');

    final body = <String, dynamic>{
      'modelSerial': modelSerial,
      'date': dateYmd.replaceAll('-', ''), // yyyymmdd
      'shift': shift,
      'dateRange': 'string',
      'groups': <String>[], // quan trọng: rỗng để không bị lọc
      'section': 'string',
      'station': 'string',
      'line': 'string',
      'customer': 'string',
      'nickName': 'string',
      'modelName': 'string',
    };

    KanbanApiLog.net(() => '[KanbanApi] POST $uri');
    KanbanApiLog.net(() => '[KanbanApi] body => ${_safeBody(body)}');

    final res = await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
      timeout: _timeout,
    );
    _ensure200(res, 'GetGroupsByShift');

    return _parseStringList(res.body);
  }

  // ============ Output/Uph Tracking (giữ nguyên) ============
  static Future<KanbanOutputTracking> getOutputTrackingData({
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$_base/OutputTracking/GetOutputTrackingData');
    KanbanApiLog.net(() => '[KanbanApi] POST $uri');
    KanbanApiLog.net(() => '[KanbanApi] body => ${_safeBody(body)}');
    final res = await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
      timeout: _timeout,
    );
    _ensure200(res, 'GetOutputTrackingData');
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>)
      return KanbanOutputTracking.fromJson(data);
    throw Exception('GetOutputTrackingData: invalid payload');
  }

  static Future<KanbanUphTracking> getUphTrackingData({
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$_base/UphTracking/GetUphTrackingData');
    KanbanApiLog.net(() => '[KanbanApi] POST $uri');
    KanbanApiLog.net(() => '[KanbanApi] body => ${_safeBody(body)}');
    final res = await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
      timeout: _timeout,
    );
    _ensure200(res, 'GetUphTrackingData');
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) return KanbanUphTracking.fromJson(data);
    throw Exception('GetUphTrackingData: invalid payload');
  }

  // ============ Parsers ============
  static List<String> _parseStringList(String body) {
    final raw = jsonDecode(body);
    final out = <String>[];
    if (raw is List) {
      for (final e in raw) {
        final s = e.toString().trim();
        if (s.isNotEmpty) out.add(s);
      }
    } else if (raw is Map && raw['data'] is List) {
      for (final e in (raw['data'] as List)) {
        final s = e.toString().trim();
        if (s.isNotEmpty) out.add(s);
      }
    }
    final uniq =
        out.toSet().toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    KanbanApiLog.net(
      () => '[KanbanApi] GetGroupsByShift OK -> ${uniq.length} items',
    );
    return uniq;
  }
}

// ===== Models + helpers (giữ nguyên) =====
class KanbanOutputTracking {
  final List<String> section;
  final List<String> model;
  final List<KanbanOutputGroup> data;

  KanbanOutputTracking({
    required this.section,
    required this.model,
    required this.data,
  });

  factory KanbanOutputTracking.fromJson(Map<String, dynamic> j) =>
      KanbanOutputTracking(
        section:
            (j['section'] as List? ?? []).map((e) => e.toString()).toList(),
        model: (j['model'] as List? ?? []).map((e) => e.toString()).toList(),
        data:
            (j['data'] as List? ?? [])
                .whereType<Map<String, dynamic>>()
                .map(KanbanOutputGroup.fromJson)
                .toList(),
      );
}

class KanbanOutputGroup {
  final String groupName;
  final String modelName; // NEW
  final List<double> pass, fail, yr, rr;
  final int wip;

  KanbanOutputGroup({
    required this.groupName,
    required this.modelName,
    required this.pass,
    required this.fail,
    required this.yr,
    required this.rr,
    required this.wip,
  });

  factory KanbanOutputGroup.fromJson(Map<String, dynamic> j) =>
      KanbanOutputGroup(
        groupName: _readString(j, const ['grouP_NAME', 'group', 'groupName']),
        modelName: _readString(j, const ['modelName', 'MODEL_NAME', 'model']),
        pass: _readNumList(j, const ['pass']),
        fail: _readNumList(j, const ['fail']),
        yr: _readNumList(j, const ['yr', 'YR']),
        rr: _readNumList(j, const ['rr', 'RR']),
        wip: _readInt(j, const ['wip', 'WIP']),
      );
}

class KanbanUphTracking {
  final List<String> section;
  final List<String> model;
  final List<KanbanUphGroup> data;

  KanbanUphTracking({
    required this.section,
    required this.model,
    required this.data,
  });

  factory KanbanUphTracking.fromJson(Map<String, dynamic> j) =>
      KanbanUphTracking(
        section:
            (j['section'] as List? ?? []).map((e) => e.toString()).toList(),
        model: (j['model'] as List? ?? []).map((e) => e.toString()).toList(),
        data:
            (j['data'] as List? ?? [])
                .whereType<Map<String, dynamic>>()
                .map(KanbanUphGroup.fromJson)
                .toList(),
      );
}

class KanbanUphGroup {
  final String groupName;
  final List<double> pass, pr;
  final int wip;
  final double uph;

  KanbanUphGroup({
    required this.groupName,
    required this.pass,
    required this.pr,
    required this.wip,
    required this.uph,
  });

  factory KanbanUphGroup.fromJson(Map<String, dynamic> j) => KanbanUphGroup(
    groupName: _readString(j, const ['grouP_NAME', 'group', 'groupName']),
    pass: _readNumList(j, const ['pass']),
    pr: _readNumList(j, const ['pr', 'PR']),
    wip: _readInt(j, const ['wip', 'WIP']),
    uph: _readDouble(j, const ['uph', 'UPH']),
  );
}

void _ensure200(http.Response res, String apiName) {
  if (res.statusCode != 200) {
    throw Exception('$apiName failed: ${res.statusCode} ${res.body}');
  }
}

String _safeBody(Map<String, dynamic> body) {
  final copy = Map<String, dynamic>.from(body)..removeWhere(
    (k, v) => k.toLowerCase().contains('token') || v.toString().length > 500,
  );
  return copy.toString();
}

dynamic _valueFor(Map<String, dynamic> s, List<String> k) {
  for (final key in k) {
    if (s.containsKey(key)) {
      final v = s[key];
      if (v is String && v.trim().isEmpty) continue;
      if (v != null) return v;
    }
  }
  final lower = {for (final e in s.entries) e.key.toLowerCase(): e.value};
  for (final key in k) {
    final v = lower[key.toLowerCase()];
    if (v is String && v.trim().isEmpty) continue;
    if (v != null) return v;
  }
  return null;
}

int _readInt(Map<String, dynamic> s, List<String> k) {
  final v = _valueFor(s, k);
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim()) ?? 0;
}

double _readDouble(Map<String, dynamic> s, List<String> k) {
  final v = _valueFor(s, k);
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim()) ?? 0.0;
}

String _readString(Map<String, dynamic> s, List<String> k) {
  final v = _valueFor(s, k);
  return v == null ? '' : v.toString().trim();
}

List<double> _readNumList(Map<String, dynamic> s, List<String> k) {
  final v = _valueFor(s, k);
  if (v is! List) return const <double>[];
  return v
      .map(
        (e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 0.0,
      )
      .toList();
}
