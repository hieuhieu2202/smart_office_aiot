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

  static Future<KanbanOutputTrackingDetail> getOutputTrackingDataDetail({
    required String modelSerial,
    required String date,
    required String shift,
    required List<String> groups,
    required String station,
    required String section,
  }) async {
    final uri = Uri.parse('$_base/OutputTracking/GetOutputTrackingDataDetail');
    final body = <String, dynamic>{
      'modelSerial': modelSerial,
      'date': date,
      'shift': shift,
      'groups': groups,
      'model': groups,
      'section': section,
      'station': station,
      'dateRange': 'string',
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

    _ensure200(res, 'GetOutputTrackingDataDetail');
    final data = jsonDecode(res.body);
    return KanbanOutputTrackingDetail.fromAny(data);
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

class KanbanOutputTrackingDetail {
  KanbanOutputTrackingDetail({
    required this.errorDetails,
    required this.testerDetails,
  });

  final List<KanbanErrorDetail> errorDetails;
  final List<KanbanTesterDetail> testerDetails;

  factory KanbanOutputTrackingDetail.fromAny(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['value'] is Map<String, dynamic>) {
        return KanbanOutputTrackingDetail.fromJson(
          Map<String, dynamic>.from(raw['value'] as Map),
        );
      }
      if (raw['data'] is Map<String, dynamic>) {
        return KanbanOutputTrackingDetail.fromJson(
          Map<String, dynamic>.from(raw['data'] as Map),
        );
      }
      return KanbanOutputTrackingDetail.fromJson(raw);
    }
    throw Exception('GetOutputTrackingDataDetail: invalid payload');
  }

  factory KanbanOutputTrackingDetail.fromJson(Map<String, dynamic> json) {
    List<dynamic> readList(String key) {
      final value = json[key];
      if (value is List) return value;
      if (value is Map<String, dynamic> && value['data'] is List) {
        return List<dynamic>.from(value['data'] as List);
      }
      return const <dynamic>[];
    }

    return KanbanOutputTrackingDetail(
      errorDetails: readList('errorDetails')
          .whereType<Map<String, dynamic>>()
          .map(KanbanErrorDetail.fromJson)
          .toList(),
      testerDetails: readList('testerDetails')
          .whereType<Map<String, dynamic>>()
          .map(KanbanTesterDetail.fromJson)
          .toList(),
    );
  }
}

class KanbanErrorDetail {
  KanbanErrorDetail({
    required this.code,
    required this.failQty,
  });

  final String code;
  final int failQty;

  factory KanbanErrorDetail.fromJson(Map<String, dynamic> json) {
    String readCode() {
      for (final key in ['ERROR_CODE', 'errorCode', 'code']) {
        final value = json[key];
        if (value != null) return value.toString();
      }
      return '';
    }

    int readQty() {
      for (final key in ['FAIL_QTY', 'failQty', 'qty']) {
        final value = json[key];
        if (value == null) continue;
        if (value is num) return value.round();
        final text = value.toString().trim();
        if (text.isEmpty) continue;
        final parsedInt = int.tryParse(text);
        if (parsedInt != null) return parsedInt;
        final parsedDouble = double.tryParse(text);
        if (parsedDouble != null) return parsedDouble.round();
      }
      return 0;
    }

    return KanbanErrorDetail(
      code: readCode(),
      failQty: readQty(),
    );
  }
}

class KanbanTesterDetail {
  KanbanTesterDetail({
    required this.stationName,
    required this.failQty,
  });

  final String stationName;
  final int failQty;

  factory KanbanTesterDetail.fromJson(Map<String, dynamic> json) {
    String readStation() {
      for (final key in ['STATION_NAME', 'stationName', 'station']) {
        final value = json[key];
        if (value != null) return value.toString();
      }
      return '';
    }

    int readQty() {
      for (final key in ['FAIL_QTY', 'failQty', 'qty']) {
        final value = json[key];
        if (value == null) continue;
        if (value is num) return value.round();
        final text = value.toString().trim();
        if (text.isEmpty) continue;
        final parsedInt = int.tryParse(text);
        if (parsedInt != null) return parsedInt;
        final parsedDouble = double.tryParse(text);
        if (parsedDouble != null) return parsedDouble.round();
      }
      return 0;
    }

    return KanbanTesterDetail(
      stationName: readStation(),
      failQty: readQty(),
    );
  }
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
