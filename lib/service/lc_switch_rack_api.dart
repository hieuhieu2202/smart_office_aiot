import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_helper.dart';

/// ===== LOG GATE cho service (tùy chọn bật/tắt từ controller/màn hình) =====
class CuringApiLog {
  static bool network = false; // bật/tắt log network
  static void net(String Function() b) {
    if (network) print(b());
  }
}

class RackMonitorApi {
  RackMonitorApi._();

  static const String _base = 'https://10.220.130.117/newweb/api/nvidia/rack';
  static const Duration _timeout = Duration(seconds: 45);

  static Map<String, String> _headers() => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
  };

  // -------------------------- Location APIs --------------------------
  static Future<List<String>> getModels() async {
    final uri = Uri.parse('$_base/Location/GetModels');
    CuringApiLog.net(() => '[CuringApi] GET $uri');
    final res = await HttpHelper().get(
      uri,
      headers: _headers(),
      timeout: _timeout,
    );
    _ensure200(res, 'GetModels');
    final data = jsonDecode(res.body);
    return data is List ? data.map((e) => e.toString()).toList() : <String>[];
  }

  static Future<List<String>> getGroups() async {
    final uri = Uri.parse('$_base/Location/GetGroups');
    CuringApiLog.net(() => '[CuringApi] GET $uri');
    final res = await HttpHelper().get(
      uri,
      headers: _headers(),
      timeout: _timeout,
    );
    _ensure200(res, 'GetGroups');
    final data = jsonDecode(res.body);
    return data is List ? data.map((e) => e.toString()).toList() : <String>[];
  }

  static Future<List<String>> getFactories() async {
    final uri = Uri.parse('$_base/Location/GetFactories');
    CuringApiLog.net(() => '[CuringApi] GET $uri');
    final res = await HttpHelper().get(
      uri,
      headers: _headers(),
      timeout: _timeout,
    );
    _ensure200(res, 'GetFactories');
    final data = jsonDecode(res.body);
    return data is List ? data.map((e) => e.toString()).toList() : <String>[];
  }

  static Future<List<String>> getFloors() async {
    final uri = Uri.parse('$_base/Location/GetFloors');
    CuringApiLog.net(() => '[CuringApi] GET $uri');
    final res = await HttpHelper().get(
      uri,
      headers: _headers(),
      timeout: _timeout,
    );
    _ensure200(res, 'GetFloors');
    final data = jsonDecode(res.body);
    return data is List ? data.map((e) => e.toString()).toList() : <String>[];
  }

  static Future<List<String>> getRooms() async {
    final uri = Uri.parse('$_base/Location/GetRooms');
    CuringApiLog.net(() => '[CuringApi] GET $uri');
    final res = await HttpHelper().get(
      uri,
      headers: _headers(),
      timeout: _timeout,
    );
    _ensure200(res, 'GetRooms');
    final data = jsonDecode(res.body);
    return data is List ? data.map((e) => e.toString()).toList() : <String>[];
  }

  static Future<List<LocationEntry>> getLocations() async {
    final uri = Uri.parse('$_base/Location/GetLocations');
    CuringApiLog.net(() => '[CuringApi] GET $uri');
    final res = await HttpHelper().get(
      uri,
      headers: _headers(),
      timeout: _timeout,
    );
    _ensure200(res, 'GetLocations');
    final data = jsonDecode(res.body);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(LocationEntry.fromJson)
          .toList();
    }
    return const <LocationEntry>[];
  }

  /// Gom option cho dropdown; nếu API lẻ trống → fallback từ GetLocations
  static Future<
    ({
      List<String> models,
      List<String> groups,
      List<String> factories,
      List<String> floors,
      List<String> rooms,
    })
  >
  getAllFilters() async {
    List<String> models = [],
        groups = [],
        factories = [],
        floors = [],
        rooms = [];
    try {
      models = await getModels();
    } catch (_) {}
    try {
      groups = await getGroups();
    } catch (_) {}
    try {
      factories = await getFactories();
    } catch (_) {}
    try {
      floors = await getFloors();
    } catch (_) {}
    try {
      rooms = await getRooms();
    } catch (_) {}

    if ([models, groups, factories, floors, rooms].any((l) => l.isEmpty)) {
      try {
        final locs = await getLocations();
        if (models.isEmpty) models = {for (final e in locs) e.model}.toList();
        if (groups.isEmpty) groups = {for (final e in locs) e.group}.toList();
        if (factories.isEmpty)
          factories = {for (final e in locs) e.factory}.toList();
        if (floors.isEmpty) floors = {for (final e in locs) e.floor}.toList();
        if (rooms.isEmpty) rooms = {for (final e in locs) e.room}.toList();
      } catch (_) {}
    }

    int _cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    models.sort(_cmp);
    groups.sort(_cmp);
    factories.sort(_cmp);
    floors.sort(_cmp);
    rooms.sort(_cmp);
    return (
      models: models,
      groups: groups,
      factories: factories,
      floors: floors,
      rooms: rooms,
    );
  }

  // -------------------------- Quick ping --------------------------
  static Future<void> quickPing() async {
    final uri = Uri.parse('$_base/Location/GetModels');
    CuringApiLog.net(() => '[CuringApi] quickPing $uri');
    await HttpHelper().get(
      uri,
      headers: _headers(),
      timeout: const Duration(seconds: 5),
    );
  }

  // -------------------------- Monitor (POST JSON) --------------------------
  static Future<GroupDataMonitoring> getGroupDataMonitoring({
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_base/Monitor/GetGroupDataMonitoring');
    CuringApiLog.net(() => '[CuringApi] POST $uri');
    CuringApiLog.net(() => '[CuringApi] POST body => ${_safeBody(body ?? {})}');
    final res = await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode(body ?? {}),
      timeout: _timeout,
    );
    _ensure200(res, 'GetGroupDataMonitoring');
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) return GroupDataMonitoring.fromJson(data);
    throw Exception('GetGroupDataMonitoring: invalid payload');
  }

  static Future<GroupDataMonitoring> getGroupDataMonitoring1({
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_base/Monitor/GetGroupDataMonitoring1');
    CuringApiLog.net(() => '[CuringApi] POST $uri');
    CuringApiLog.net(() => '[CuringApi] POST body => ${_safeBody(body ?? {})}');
    final res = await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode(body ?? {}),
      timeout: _timeout,
    );
    _ensure200(res, 'GetGroupDataMonitoring1');
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) return GroupDataMonitoring.fromJson(data);
    throw Exception('GetGroupDataMonitoring1: invalid payload');
  }

  static Future<GroupDataMonitoring> getByTower({
    required Tower tower,
    Map<String, dynamic>? body,
  }) {
    return tower == Tower.f17
        ? getGroupDataMonitoring1(body: body)
        : getGroupDataMonitoring(body: body);
  }

  static Future<GroupDataMonitoring> getByFactory({
    required String factory,
    Map<String, dynamic>? body,
  }) {
    final isF17 = factory.trim().toUpperCase() == 'F17';
    final merged = {...?body, 'factory': isF17 ? 'F17' : 'F16'};
    return getByTower(tower: isF17 ? Tower.f17 : Tower.f16, body: merged);
  }
}

enum Tower { f16, f17 }

void _ensure200(http.Response res, String apiName) {
  if (res.statusCode != 200) {
    throw Exception('$apiName failed: ${res.statusCode} ${res.body}');
  }
}

// -------------------------- Safe body logger --------------------------
String _safeBody(Map<String, dynamic> body) {
  final Map<String, dynamic> copy = Map.from(body);
  // Loại bỏ token hoặc chuỗi quá dài nếu có
  copy.removeWhere(
    (k, v) => k.toLowerCase().contains('token') || v.toString().length > 500,
  );
  return copy.toString();
}

// -------------------------- Models --------------------------
class LocationEntry {
  final String factory;
  final String floor;
  final String room;
  final String group;
  final String model;

  LocationEntry({
    required this.factory,
    required this.floor,
    required this.room,
    required this.group,
    required this.model,
  });

  factory LocationEntry.fromJson(Map<String, dynamic> j) => LocationEntry(
    factory: j['factory']?.toString() ?? '',
    floor: j['floor']?.toString() ?? '',
    room: j['room']?.toString() ?? '',
    group: j['group']?.toString() ?? '',
    model: j['model']?.toString() ?? '',
  );
}

class SlotStaticItem {
  final String status;
  final int value;

  SlotStaticItem({required this.status, required this.value});

  factory SlotStaticItem.fromJson(Map<String, dynamic> j) => SlotStaticItem(
    status: j['status']?.toString() ?? '',
    value: _asInt(j['value']),
  );
}

class QuantitySummary {
  final double ut;
  final int input;
  final int firstPass;
  final int secondPass;
  final int pass;
  final int rePass;
  final int totalPass;
  final int firstFail;
  final int fail;
  final double fpr;
  final double yr;
  final int wip;

  QuantitySummary({
    required this.ut,
    required this.input,
    required this.firstPass,
    required this.secondPass,
    required this.pass,
    required this.rePass,
    required this.totalPass,
    required this.firstFail,
    required this.fail,
    required this.fpr,
    required this.yr,
    required this.wip,
  });

  factory QuantitySummary.fromJson(Map<String, dynamic> j) {
    final q =
        (j['quantitySummary'] is Map<String, dynamic>)
            ? (j['quantitySummary'] as Map<String, dynamic>)
            : j;
    return QuantitySummary(
      ut: _asDouble(q['ut']),
      input: _asInt(q['input']),
      firstPass: _asInt(q['first_Pass']),
      secondPass: _asInt(q['second_Pass']),
      pass: _asInt(q['pass']),
      rePass: _asInt(q['re_Pass']),
      totalPass: _asInt(q['total_Pass']),
      firstFail: _asInt(q['first_Fail']),
      fail: _asInt(q['fail']),
      fpr: _asDouble(q['fpr']),
      yr: _asDouble(q['yr']),
      wip: _asInt(q['wip']),
    );
  }
}

class SlotDetail {
  final String nickName;
  final String slotNumber;
  final String slotName;
  final String modelName;
  final int input;
  final int firstPass;
  final int secondPass;
  final int pass;
  final int rePass;
  final int totalPass;
  final int firstFail;
  final int fail;
  final double fpr;
  final double yr;
  final String status;
  final double runtime;
  final double totalTime;

  SlotDetail({
    required this.nickName,
    required this.slotNumber,
    required this.slotName,
    required this.modelName,
    required this.input,
    required this.firstPass,
    required this.secondPass,
    required this.pass,
    required this.rePass,
    required this.totalPass,
    required this.firstFail,
    required this.fail,
    required this.fpr,
    required this.yr,
    required this.status,
    required this.runtime,
    required this.totalTime,
  });

  factory SlotDetail.fromJson(Map<String, dynamic> j) => SlotDetail(
    nickName: j['nickName']?.toString() ?? '',
    slotNumber: j['slotNumber']?.toString() ?? '',
    slotName: j['slotName']?.toString() ?? '',
    modelName: j['modelName']?.toString() ?? '',
    input: _asInt(j['input']),
    firstPass: _asInt(j['first_Pass']),
    secondPass: _asInt(j['second_Pass']),
    pass: _asInt(j['pass']),
    rePass: _asInt(j['re_Pass']),
    totalPass: _asInt(j['total_Pass']),
    firstFail: _asInt(j['first_Fail']),
    fail: _asInt(j['fail']),
    fpr: _asDouble(j['fpr']),
    yr: _asDouble(j['yr']),
    status: j['status']?.toString() ?? '',
    runtime: _asDouble(j['runtime']),
    totalTime: _asDouble(j['totalTime']),
  );
}

class RackDetail {
  final String nickName;
  final String groupName;
  final String rackName;
  final String modelName;
  final double ut;
  final int input;
  final int firstPass;
  final int secondPass;
  final int pass;
  final int rePass;
  final int totalPass;
  final int firstFail;
  final int fail;
  final double fpr;
  final double yr;
  final double runtime;
  final double totalTime;
  final List<SlotDetail> slotDetails;

  RackDetail({
    required this.nickName,
    required this.groupName,
    required this.rackName,
    required this.modelName,
    required this.ut,
    required this.input,
    required this.firstPass,
    required this.secondPass,
    required this.pass,
    required this.rePass,
    required this.totalPass,
    required this.firstFail,
    required this.fail,
    required this.fpr,
    required this.yr,
    required this.runtime,
    required this.totalTime,
    required this.slotDetails,
  });

  factory RackDetail.fromJson(Map<String, dynamic> j) => RackDetail(
    nickName: j['nickName']?.toString() ?? '',
    groupName: j['groupName']?.toString() ?? '',
    rackName: j['rackName']?.toString() ?? '',
    modelName: j['modelName']?.toString() ?? '',
    ut: _asDouble(j['ut']),
    input: _asInt(j['input']),
    firstPass: _asInt(j['first_Pass']),
    secondPass: _asInt(j['second_Pass']),
    pass: _asInt(j['pass']),
    rePass: _asInt(j['re_Pass']),
    totalPass: _asInt(j['total_Pass']),
    firstFail: _asInt(j['first_Fail']),
    fail: _asInt(j['fail']),
    fpr: _asDouble(j['fpr']),
    yr: _asDouble(j['yr']),
    runtime: _asDouble(j['runtime']),
    totalTime: _asDouble(j['totalTime']),
    slotDetails:
        (j['slotDetails'] is List)
            ? (j['slotDetails'] as List)
                .whereType<Map<String, dynamic>>()
                .map(SlotDetail.fromJson)
                .toList()
            : const <SlotDetail>[],
  );
}

class GroupDataMonitoring {
  final List<SlotStaticItem> slotStatic;
  final QuantitySummary quantitySummary;
  final List<RackDetail> rackDetails;

  GroupDataMonitoring({
    required this.slotStatic,
    required this.quantitySummary,
    required this.rackDetails,
  });

  factory GroupDataMonitoring.fromJson(Map<String, dynamic> j) =>
      GroupDataMonitoring(
        slotStatic:
            (j['slotStatic'] is List)
                ? (j['slotStatic'] as List)
                    .whereType<Map<String, dynamic>>()
                    .map(SlotStaticItem.fromJson)
                    .toList()
                : const <SlotStaticItem>[],
        quantitySummary: QuantitySummary.fromJson(j),
        rackDetails:
            (j['rackDetails'] is List)
                ? (j['rackDetails'] as List)
                    .whereType<Map<String, dynamic>>()
                    .map(RackDetail.fromJson)
                    .toList()
                : const <RackDetail>[],
      );
}

// -------------------------- Helpers --------------------------
int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is num) return v.toInt();
  if (v is String) {
    final n = num.tryParse(v.trim());
    return n == null ? 0 : n.toInt();
  }
  return 0;
}

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) {
    final n = num.tryParse(v.trim());
    return n == null ? 0.0 : n.toDouble();
  }
  return 0.0;
}
