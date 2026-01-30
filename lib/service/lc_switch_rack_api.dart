import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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

  static const String _base = 'https://10.220.130.117/api/nvidia/rack';
  static const Duration _timeout = Duration(seconds: 45);

  static Map<String, String> _headers() => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
  };

  // -------------------------- Location APIs --------------------------
  static Map<String, dynamic> _locationBody({
    String? factory,
    String? floor,
    String? room,
    String? model,
    String? nickName,
    String? group,
    String? dateRange,
  }) {
    String normalized(String? v, {bool allowAll = true}) {
      final trimmed = v?.trim() ?? '';
      if (trimmed.isEmpty && allowAll) return 'ALL';
      return trimmed;
    }

    return {
      'factory': normalized(factory),
      'floor': normalized(floor),
      'room': normalized(room),
      'model': normalized(model),
      'nickName': normalized(nickName, allowAll: false),
      'group': normalized(group),
      'dateRange': normalized(dateRange, allowAll: false),
    };
  }

  static Future<List<String>> getModels() async {
    final uri = Uri.parse('$_base/Location/GetModels');
    CuringApiLog.net(() => '[CuringApi] POST $uri');
    CuringApiLog.net(() => '[CuringApi] POST body => {}');
    final res = await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode({}),
      timeout: _timeout,
    );
    _logResponse('GetModels', res);
    _ensure200(res, 'GetModels');
    final data = jsonDecode(res.body);
    return data is List ? data.map((e) => e.toString()).toList() : <String>[];
  }

  static Future<List<String>> getGroups({
    String? factory,
    String? floor,
    String? room,
    String? model,
    String? nickName,
    String? group,
    String? dateRange,
  }) async {
    final uri = Uri.parse('$_base/Location/GetGroups');
    CuringApiLog.net(() => '[CuringApi] POST $uri');
    final body = _locationBody(
      factory: factory,
      floor: floor,
      room: room,
      model: model,
      nickName: nickName,
      group: group,
      dateRange: dateRange,
    );
    CuringApiLog.net(() => '[CuringApi] POST body => ${_safeBody(body)}');
    final res = await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
      timeout: _timeout,
    );
    _logResponse('GetGroups', res);
    _ensure200(res, 'GetGroups');
    final data = jsonDecode(res.body);
    return data is List ? data.map((e) => e.toString()).toList() : <String>[];
  }

  static Future<List<String>> getFactories({
    String? factory,
    String? floor,
    String? room,
    String? model,
    String? nickName,
    String? group,
    String? dateRange,
  }) async {
    final uri = Uri.parse('$_base/Location/GetFactories');
    CuringApiLog.net(() => '[CuringApi] POST $uri');
    final body = _locationBody(
      factory: factory,
      floor: floor,
      room: room,
      model: model,
      nickName: nickName,
      group: group,
      dateRange: dateRange,
    );
    CuringApiLog.net(() => '[CuringApi] POST body => ${_safeBody(body)}');
    final res = await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
      timeout: _timeout,
    );
    _logResponse('GetFactories', res);
    _ensure200(res, 'GetFactories');
    final data = jsonDecode(res.body);
    return data is List ? data.map((e) => e.toString()).toList() : <String>[];
  }

  static Future<List<String>> getFloors({
    String? factory,
    String? floor,
    String? room,
    String? model,
    String? nickName,
    String? group,
    String? dateRange,
  }) async {
    final uri = Uri.parse('$_base/Location/GetFloors');
    CuringApiLog.net(() => '[CuringApi] POST $uri');
    final body = _locationBody(
      factory: factory,
      floor: floor,
      room: room,
      model: model,
      nickName: nickName,
      group: group,
      dateRange: dateRange,
    );
    CuringApiLog.net(() => '[CuringApi] POST body => ${_safeBody(body)}');
    final res = await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
      timeout: _timeout,
    );
    _logResponse('GetFloors', res);
    _ensure200(res, 'GetFloors');
    final data = jsonDecode(res.body);
    return data is List ? data.map((e) => e.toString()).toList() : <String>[];
  }

  static Future<List<String>> getRooms({
    String? factory,
    String? floor,
    String? room,
    String? model,
    String? nickName,
    String? group,
    String? dateRange,
  }) async {
    final uri = Uri.parse('$_base/Location/GetRooms');
    CuringApiLog.net(() => '[CuringApi] POST $uri');
    final body = _locationBody(
      factory: factory,
      floor: floor,
      room: room,
      model: model,
      nickName: nickName,
      group: group,
      dateRange: dateRange,
    );
    CuringApiLog.net(() => '[CuringApi] POST body => ${_safeBody(body)}');
    final res = await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
      timeout: _timeout,
    );
    _logResponse('GetRooms', res);
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
    await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode({}),
      timeout: const Duration(seconds: 5),
    );
  }

  // -------------------------- Monitor (POST JSON) --------------------------
  static Map<String, dynamic> _monitorBody(Map<String, dynamic>? rawBody) {
    Map<String, dynamic> body = {...?rawBody};

    String _normalized(String? v, {bool allowAll = true}) {
      final trimmed = v?.trim() ?? '';
      if (trimmed.isEmpty && allowAll) return 'ALL';
      return trimmed.isEmpty ? '' : trimmed;
    }

    String _defaultDateRange() {
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd');
      final today = formatter.format(now);
      return '$today 07:30 - $today 19:30';
    }

    List<String> _ensureProductNames(dynamic value) {
      if (value is List) {
        final list = value.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        if (list.isNotEmpty) return list;
      } else if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty && trimmed != 'ALL') return [trimmed];
      }
      return const [];
    }

    final normalizedFactory = _normalized(body['factory']);
    final normalizedFloor = _normalized(body['floor']);
    final normalizedRoom = _normalized(body['room']);
    final normalizedGroup = _normalized(body['groupName'] ?? body['group']);
    final productNames = _ensureProductNames(body['productNames'] ?? body['model']);
    final productName = _normalized(body['productName'], allowAll: false);
    final dateRange = (body['dateRange']?.toString().trim() ?? '').isEmpty
        ? _defaultDateRange()
        : body['dateRange'].toString().trim();

    return {
      'factory': normalizedFactory,
      'floor': normalizedFloor,
      'room': normalizedRoom,
      'productNames': productNames,
      'productName': productName,
      'groupName': normalizedGroup,
      'dateRange': dateRange,
      'detailType': body['detailType']?.toString() ?? '',
      'slotName': body['slotName']?.toString() ?? '',
    };
  }

  static Future<GroupDataMonitoring> getDataMonitoring({
    Map<String, dynamic>? body,
  }) async {
    final normalizedBody = _monitorBody(body);
    final uri = Uri.parse('$_base/Monitor/GetDataMonitoring');
    CuringApiLog.net(() => '[CuringApi] POST $uri');
    CuringApiLog.net(() => '[CuringApi] POST body => ${_safeBody(normalizedBody)}');
    final res = await HttpHelper().post(
      uri,
      headers: _headers(),
      body: jsonEncode(normalizedBody),
      timeout: _timeout,
    );
    _logResponse('GetDataMonitoring', res);
    _ensure200(res, 'GetDataMonitoring');
    final data = _decodeJsonLoose(res.body);
    if (data is Map<String, dynamic>) return GroupDataMonitoring.fromJson(data);
    throw Exception('GetDataMonitoring: invalid payload');
  }

  static Future<GroupDataMonitoring> getGroupDataMonitoring({
    Map<String, dynamic>? body,
  }) {
    return getDataMonitoring(body: body);
  }

  static Future<GroupDataMonitoring> getByFactory({
    required String factory,
    Map<String, dynamic>? body,
  }) {
    final merged = {...?body, 'factory': factory.trim()};
    return getDataMonitoring(body: merged);
  }
}

void _ensure200(http.Response res, String apiName) {
  if (res.statusCode != 200) {
    throw Exception('$apiName failed: ${res.statusCode} ${res.body}');
  }
}

void _logResponse(String apiName, http.Response res) {
  CuringApiLog.net(() {
    final preview = res.body.length > 400
        ? '${res.body.substring(0, 400)}...(+${res.body.length - 400} chars)'
        : res.body;
    return '[CuringApi] $apiName response ${res.statusCode}: $preview';
  });
}

dynamic _decodeJsonLoose(String body) {
  dynamic first;
  try {
    first = jsonDecode(body);
  } catch (_) {
    return null;
  }

  if (first is String) {
    try {
      return jsonDecode(first);
    } catch (_) {
      return first;
    }
  }

  return first;
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
    factory: _readString(j, const ['factory', 'Factory']),
    floor: _readString(j, const ['floor', 'Floor']),
    room: _readString(j, const ['room', 'Room', 'Location']),
    group: _readString(j, const ['group', 'Group', 'groupName', 'GroupName']),
    model: _readString(
      j,
      const ['product', 'Product', 'productName', 'ProductName', 'model', 'Model'],
    ),
  );
}

class SlotStaticItem {
  final String status;
  final int value;

  SlotStaticItem({required this.status, required this.value});

  factory SlotStaticItem.fromJson(Map<String, dynamic> j) => SlotStaticItem(
    status: _readString(j, const ['status', 'slotStatus']),
    value: _readInt(j, const ['value', 'count']),
  );
}

class QuantitySummary {
  final double ut;
  final int wip;
  final int input;
  final int firstPass;
  final int secondPass;
  final int pass;
  final int rePass;
  final int totalPass;
  final int firstFail;
  final int secondFail;
  final int fail;
  final int repair;
  final int repairPass;
  final int repairFail;
  final int totalFail;
  final double fpr;
  final double spr;
  final double rr;
  final double yr;

  QuantitySummary({
    required this.ut,
    required this.wip,
    required this.input,
    required this.firstPass,
    required this.secondPass,
    required this.pass,
    required this.rePass,
    required this.totalPass,
    required this.firstFail,
    required this.secondFail,
    required this.fail,
    required this.repair,
    required this.repairPass,
    required this.repairFail,
    required this.totalFail,
    required this.fpr,
    required this.spr,
    required this.rr,
    required this.yr,
  });

  factory QuantitySummary.fromJson(Map<String, dynamic> j) {
    final qRaw = _valueFor(
      j,
      const ['quantitySummary', 'QuantitySummary', 'quantity_Summary'],
    );
    final q = (qRaw is Map<String, dynamic>) ? qRaw : j;
    return QuantitySummary(
      ut: _readDouble(q, const ['ut', 'UT']),
      wip: _readInt(q, const ['wip', 'WIP']),
      input: _readInt(q, const ['input', 'Input']),
      firstPass: _readInt(q, const ['firstPass', 'first_Pass', 'First_Pass']),
      secondPass: _readInt(q, const ['secondPass', 'second_Pass', 'Second_Pass']),
      pass: _readInt(q, const ['pass', 'Pass']),
      rePass: _readInt(q, const ['rePass', 're_Pass', 'Repair_Pass']),
      totalPass: _readInt(q, const ['totalPass', 'total_Pass', 'Total_Pass']),
      firstFail: _readInt(q, const ['firstFail', 'first_Fail', 'First_Fail']),
      secondFail: _readInt(q, const ['secondFail', 'second_Fail', 'Second_Fail']),
      fail: _readInt(q, const ['fail', 'Fail']),
      repair: _readInt(q, const ['repair', 'Repair']),
      repairPass: _readInt(q, const ['repairPass', 'repair_Pass', 'Repair_Pass']),
      repairFail: _readInt(q, const ['repairFail', 'repair_Fail', 'Repair_Fail']),
      totalFail: _readInt(q, const ['totalFail', 'total_Fail', 'Total_Fail']),
      fpr: _readDouble(q, const ['fpr', 'FPR']),
      spr: _readDouble(q, const ['spr', 'SPR']),
      rr: _readDouble(q, const ['rr', 'RR']),
      yr: _readDouble(q, const ['yr', 'YR']),
    );
  }
}

class SlotDetail {
  final String nickName;
  final String productName;
  final String slotNumber;
  final String slotName;
  final String modelName;
  final int wip;
  final int input;
  final int firstPass;
  final int secondPass;
  final int pass;
  final int rePass;
  final int totalPass;
  final int firstFail;
  final int secondFail;
  final int fail;
  final int repair;
  final int repairPass;
  final int repairFail;
  final int totalFail;
  final double fpr;
  final double spr;
  final double rr;
  final double yr;
  final String status;
  final double runtime;
  final double totalTime;

  SlotDetail({
    required this.nickName,
    required this.productName,
    required this.slotNumber,
    required this.slotName,
    required this.modelName,
    required this.wip,
    required this.input,
    required this.firstPass,
    required this.secondPass,
    required this.pass,
    required this.rePass,
    required this.totalPass,
    required this.firstFail,
    required this.secondFail,
    required this.fail,
    required this.repair,
    required this.repairPass,
    required this.repairFail,
    required this.totalFail,
    required this.fpr,
    required this.spr,
    required this.rr,
    required this.yr,
    required this.status,
    required this.runtime,
    required this.totalTime,
  });

  factory SlotDetail.fromJson(Map<String, dynamic> j) => SlotDetail(
    nickName: _readString(j, const ['nickName', 'nickname']),
    productName: _readString(j, const ['productName', 'ProductName', 'product']),
    slotNumber: _readString(j, const ['slotNumber', 'SlotNumber', 'slotNo', 'slot_No']),
    slotName: _readString(j, const ['slotName', 'SlotName', 'slot_name']),
    modelName: _readString(j, const ['modelName', 'ModelName', 'model']),
    wip: _readInt(j, const ['wip', 'WIP']),
    input: _readInt(j, const ['input', 'Input']),
    firstPass: _readInt(j, const ['firstPass', 'first_Pass', 'First_Pass']),
    secondPass: _readInt(j, const ['secondPass', 'second_Pass', 'Second_Pass']),
    pass: _readInt(j, const ['pass', 'Pass']),
    rePass: _readInt(j, const ['rePass', 're_Pass', 'Repair_Pass']),
    totalPass: _readInt(j, const ['totalPass', 'total_Pass', 'Total_Pass']),
    firstFail: _readInt(j, const ['firstFail', 'first_Fail', 'First_Fail']),
    secondFail: _readInt(j, const ['secondFail', 'second_Fail', 'Second_Fail']),
    fail: _readInt(j, const ['fail', 'Fail']),
    repair: _readInt(j, const ['repair', 'Repair']),
    repairPass: _readInt(j, const ['repairPass', 'repair_Pass', 'Repair_Pass']),
    repairFail: _readInt(j, const ['repairFail', 'repair_Fail', 'Repair_Fail']),
    totalFail: _readInt(j, const ['totalFail', 'total_Fail', 'Total_Fail']),
    fpr: _readDouble(j, const ['fpr', 'FPR']),
    spr: _readDouble(j, const ['spr', 'SPR']),
    rr: _readDouble(j, const ['rr', 'RR']),
    yr: _readDouble(j, const ['yr', 'YR']),
    status: _readString(j, const ['status', 'Status', 'slotStatus']),
    runtime: _readDouble(j, const ['runtime', 'Runtime']),
    totalTime: _readDouble(j, const ['totalTime', 'total_Time', 'TotalTime']),
  );
}

class RackDetail {
  final String nickName;
  final String productName;
  final String groupName;
  final String rackName;
  final String modelName;
  final double ut;
  final int wip;
  final int input;
  final int firstPass;
  final int secondPass;
  final int pass;
  final int rePass;
  final int totalPass;
  final int firstFail;
  final int secondFail;
  final int fail;
  final int repair;
  final int repairPass;
  final int repairFail;
  final int totalFail;
  final double fpr;
  final double spr;
  final double rr;
  final double yr;
  final double runtime;
  final double totalTime;
  final List<SlotDetail> slotDetails;

  RackDetail({
    required this.nickName,
    required this.productName,
    required this.groupName,
    required this.rackName,
    required this.modelName,
    required this.ut,
    required this.wip,
    required this.input,
    required this.firstPass,
    required this.secondPass,
    required this.pass,
    required this.rePass,
    required this.totalPass,
    required this.firstFail,
    required this.secondFail,
    required this.fail,
    required this.repair,
    required this.repairPass,
    required this.repairFail,
    required this.totalFail,
    required this.fpr,
    required this.spr,
    required this.rr,
    required this.yr,
    required this.runtime,
    required this.totalTime,
    required this.slotDetails,
  });

  factory RackDetail.fromJson(Map<String, dynamic> j) => RackDetail(
    nickName: _readString(j, const ['nickName', 'nickname']),
    productName: _readString(j, const ['productName', 'ProductName', 'product']),
    groupName: _readString(j, const ['groupName', 'GroupName']),
    rackName: _readString(j, const ['rackName', 'RackName', 'rack']),
    modelName: _readString(j, const ['modelName', 'ModelName', 'model']),
    ut: _readDouble(j, const ['ut', 'UT']),
    wip: _readInt(j, const ['wip', 'WIP']),
    input: _readInt(j, const ['input', 'Input']),
    firstPass: _readInt(j, const ['firstPass', 'first_Pass', 'First_Pass']),
    secondPass: _readInt(j, const ['secondPass', 'second_Pass', 'Second_Pass']),
    pass: _readInt(j, const ['pass', 'Pass']),
    rePass: _readInt(j, const ['rePass', 're_Pass', 'Repair_Pass']),
    totalPass: _readInt(j, const ['totalPass', 'total_Pass', 'Total_Pass']),
    firstFail: _readInt(j, const ['firstFail', 'first_Fail', 'First_Fail']),
    secondFail: _readInt(j, const ['secondFail', 'second_Fail', 'Second_Fail']),
    fail: _readInt(j, const ['fail', 'Fail']),
    repair: _readInt(j, const ['repair', 'Repair']),
    repairPass: _readInt(j, const ['repairPass', 'repair_Pass', 'Repair_Pass']),
    repairFail: _readInt(j, const ['repairFail', 'repair_Fail', 'Repair_Fail']),
    totalFail: _readInt(j, const ['totalFail', 'total_Fail', 'Total_Fail']),
    fpr: _readDouble(j, const ['fpr', 'FPR']),
    spr: _readDouble(j, const ['spr', 'SPR']),
    rr: _readDouble(j, const ['rr', 'RR']),
    yr: _readDouble(j, const ['yr', 'YR']),
    runtime: _readDouble(j, const ['runtime', 'Runtime']),
    totalTime: _readDouble(j, const ['totalTime', 'total_Time', 'TotalTime']),
    slotDetails: GroupDataMonitoring._asMapList(
      _valueFor(j, const ['slotDetails', 'SlotDetails', 'slot_Details', 'Slot_Details']),
    ).map(SlotDetail.fromJson).toList(),
  );
}

class ModelDetail {
  final String modelName;
  final int pass;
  final int totalPass;

  ModelDetail({
    required this.modelName,
    required this.pass,
    required this.totalPass,
  });

  factory ModelDetail.fromJson(Map<String, dynamic> j) {
    final model = _readString(
      j,
      const ['modelName', 'ModelName', 'model', 'modelSerial'],
    );
    final total = _readInt(j, const ['totalPass', 'TotalPass', 'total_Pass', 'output']);
    final pass = _readInt(j, const ['pass', 'Pass']);
    final derivedTotal = total != 0 ? total : pass;
    final derivedPass = pass != 0 ? pass : derivedTotal;
    return ModelDetail(
      modelName: model,
      pass: derivedPass,
      totalPass: derivedTotal,
    );
  }
}

class GroupDataMonitoring {
  final List<SlotStaticItem> slotStatic;
  final QuantitySummary quantitySummary;
  final List<RackDetail> rackDetails;
  final List<ModelDetail> modelDetails;

  GroupDataMonitoring({
    required this.slotStatic,
    required this.quantitySummary,
    required this.rackDetails,
    required this.modelDetails,
  });

  static List<Map<String, dynamic>> _asMapList(dynamic source) {
    dynamic raw = source;

    // Một số API trả về chuỗi JSON thay vì list object
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        // nếu decode thất bại thì coi như không có data
        raw = null;
      }
    }

    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }

    return const <Map<String, dynamic>>[];
  }

  factory GroupDataMonitoring.fromJson(Map<String, dynamic> j) {
    final slotSrc =
        _valueFor(j, const ['slotStatic', 'SlotStatic', 'slot_static']);
    final rackSrc =
        _valueFor(j, const ['rackDetails', 'RackDetails', 'rack_Details']);
    final modelSrc =
        _valueFor(j, const ['modelDetails', 'ModelDetails', 'model_Details']);

    return GroupDataMonitoring(
      slotStatic:
          _asMapList(slotSrc).map(SlotStaticItem.fromJson).toList(),
      quantitySummary: QuantitySummary.fromJson(j),
      rackDetails: _asMapList(rackSrc).map(RackDetail.fromJson).toList(),
      modelDetails: _asMapList(modelSrc).map(ModelDetail.fromJson).toList(),
    );
  }
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

dynamic _valueFor(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (source.containsKey(key)) {
      final value = source[key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      return value;
    }
  }
  if (source.isEmpty) return null;
  final lowerLookup = <String, dynamic>{};
  for (final entry in source.entries) {
    lowerLookup.putIfAbsent(entry.key.toLowerCase(), () => entry.value);
  }
  for (final key in keys) {
    final lowerKey = key.toLowerCase();
    if (lowerLookup.containsKey(lowerKey)) {
      final value = lowerLookup[lowerKey];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      return value;
    }
  }
  return null;
}

int _readInt(Map<String, dynamic> source, List<String> keys) {
  return _asInt(_valueFor(source, keys));
}

double _readDouble(Map<String, dynamic> source, List<String> keys) {
  return _asDouble(_valueFor(source, keys));
}

String _readString(Map<String, dynamic> source, List<String> keys) {
  final value = _valueFor(source, keys);
  if (value == null) return '';
  if (value is String) return value.trim();
  return value.toString().trim();
}
