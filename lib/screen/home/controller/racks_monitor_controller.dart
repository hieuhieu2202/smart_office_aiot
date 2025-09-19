import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../service/lc_switch_rack_api.dart';

// ======================= Helpers (TOP-LEVEL) =======================
final RegExp _saRe = RegExp(r'(SA0+\d+|SA\d{6,})', caseSensitive: false);

String _extractSA(String? s) {
  if (s == null) return '';
  final m = _saRe.firstMatch(s);
  return (m?.group(0) ?? '').toUpperCase();
}

bool _diffAtMostOneChar(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      diff++;
      if (diff > 1) return false;
    }
  }
  return diff == 1;
}

class _Agg {
  int pass = 0;
  int totalPass = 0;
}

class ModelPass {
  final String model;
  final int pass;
  final int totalPass;

  ModelPass(this.model, this.pass, this.totalPass);
}

Map<String, _Agg> _mergeNearCodes(
  Map<String, _Agg> src,
  Set<String> rackSAs, {
  bool log = false,
}) {
  final m = Map<String, _Agg>.from(src);
  final keys = m.keys.toList()..sort();
  final visited = <String>{};

  for (var i = 0; i < keys.length; i++) {
    final a = keys[i];
    if (!m.containsKey(a) || visited.contains(a)) continue;

    for (var j = i + 1; j < keys.length; j++) {
      final b = keys[j];
      if (!m.containsKey(b) || visited.contains(b)) continue;
      if (!_diffAtMostOneChar(a, b)) continue;

      String canon;
      final aRack = rackSAs.contains(a), bRack = rackSAs.contains(b);
      if (aRack && !bRack)
        canon = a;
      else if (bRack && !aRack)
        canon = b;
      else
        canon = (m[a]!.pass >= m[b]!.pass) ? a : b;

      final other = (canon == a) ? b : a;
      if (log)
        debugPrint(
          '↪ MERGE NEAR: $other -> $canon (other=${m[other]!.pass}, canon=${m[canon]!.pass})',
        );
      m[canon]!.pass += m[other]!.pass;
      m[canon]!.totalPass += m[other]!.totalPass;
      m.remove(other);
      visited
        ..add(canon)
        ..add(other);
    }
  }
  return m;
}

// ======================= Controller =======================
class GroupMonitorController extends GetxController {
  // ========= Log control =========
  final _verbose = false.obs;

  void enableVerbose(bool on) => _verbose.value = on;

  void vlog(String Function() builder) {
    if (_verbose.value) debugPrint(builder());
  }

  // ========= Filters =========
  List<LocationEntry> _allLocs = const <LocationEntry>[];

  final factories = <String>['F16', 'F17'].obs;
  final floors = <String>['ALL'].obs;
  final rooms = <String>['ALL'].obs;
  final groups = <String>['ALL'].obs;
  final models = <String>['ALL'].obs;

  final selFactory = 'F16'.obs;
  final selFloor = '3F'.obs;
  final selRoom = 'ALL'.obs;
  final selGroup = 'J_TAG'.obs;
  final selModel = 'ALL'.obs;

  final showOfflineRack = true.obs;
  final showAnimation = false.obs;

  final data = Rxn<GroupDataMonitoring>();
  final isLoading = false.obs;
  final error = RxnString();

  final autoRefresh = true.obs;
  final intervalSec = 10.obs;
  Timer? _timer;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadFilterSources();
    await refresh();

    debounce(intervalSec, (_) => _restartTimer());
    ever(autoRefresh, (_) => _restartTimer());
    _restartTimer();

    ever(selFactory, (_) {
      selFloor.value = 'ALL';
      selRoom.value = 'ALL';
      selGroup.value = 'ALL';
      selModel.value = 'ALL';
      _rebuildDependentOptions();
      refresh();
    });

    ever(selFloor, (_) {
      _rebuildDependentOptions();
      refresh();
    });
    ever(selRoom, (_) {
      _rebuildDependentOptions();
      refresh();
    });
    ever(selGroup, (_) {
      _rebuildDependentOptions();
      refresh();
    });
    ever(selModel, (_) => refresh());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (autoRefresh.value) {
      _timer = Timer.periodic(
        Duration(seconds: intervalSec.value),
        (_) => refresh(),
      );
    }
  }

  // ========= Filter options =========
  Future<void> _loadFilterSources() async {
    try {
      _allLocs = await RackMonitorApi.getLocations();

      final fset = {for (final e in _allLocs) e.factory.trim()}
        ..removeWhere((e) => e.isEmpty);

      if (fset.isNotEmpty) {
        factories
          ..clear()
          ..addAll(fset.toList()..sort());
        if (!factories.contains(selFactory.value))
          selFactory.value = factories.first;
      }

      _rebuildDependentOptions();
    } catch (e) {
      error.value = 'Load filters failed: $e';
      _allLocs = const <LocationEntry>[];
      factories
        ..clear()
        ..addAll(['F16', 'F17']);
      floors
        ..clear()
        ..addAll(['ALL', '3F']);
      rooms
        ..clear()
        ..addAll(['ALL', 'ROOM1', 'ROOM2']);
      groups
        ..clear()
        ..addAll(['ALL', 'CTO', 'FT', 'J_TAG']);
      models
        ..clear()
        ..addAll(['ALL', 'GB200', 'GB300']);
    }
  }

  List<String> _mkOpts(Iterable<String> vals) {
    final s = <String>{};
    for (final v in vals) {
      final t = v.trim();
      if (t.isNotEmpty) s.add(t);
    }
    final list =
        s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['ALL', ...list];
  }

  void _rebuildDependentOptions() {
    final fact = selFactory.value.trim();
    final floor = selFloor.value.trim();
    final room = selRoom.value.trim();
    final group = selGroup.value.trim();

    final newFloors = _mkOpts(
      _allLocs.where((e) => e.factory == fact).map((e) => e.floor),
    );
    floors
      ..clear()
      ..addAll(newFloors);
    if (!floors.contains(selFloor.value)) selFloor.value = 'ALL';

    Iterable<LocationEntry> qRoom = _allLocs.where((e) => e.factory == fact);
    if (selFloor.value != 'ALL') qRoom = qRoom.where((e) => e.floor == floor);
    final newRooms = _mkOpts(qRoom.map((e) => e.room));
    rooms
      ..clear()
      ..addAll(newRooms);
    if (!rooms.contains(selRoom.value)) selRoom.value = 'ALL';

    Iterable<LocationEntry> qGroup = qRoom;
    if (selRoom.value != 'ALL') qGroup = qGroup.where((e) => e.room == room);
    final newGroups = _mkOpts(qGroup.map((e) => e.group));
    groups
      ..clear()
      ..addAll(newGroups);
    if (!groups.contains(selGroup.value)) selGroup.value = 'ALL';

    Iterable<LocationEntry> qModel = qGroup;
    if (selGroup.value != 'ALL') qModel = qModel.where((e) => e.group == group);
    final newModels = _mkOpts(qModel.map((e) => e.model));
    models
      ..clear()
      ..addAll(newModels);
    if (!models.contains(selModel.value)) selModel.value = 'ALL';

    vlog(
      () =>
          'FILTER OPTIONS REBUILD: '
          'Factory=$fact, Floor=$floor, Room=$room, Group=$group\n'
          'Floors=${floors.join(", ")}\n'
          'Rooms=${rooms.join(", ")}\n'
          'Groups=${groups.join(", ")}\n'
          'Models=${models.join(", ")}',
    );
  }

  Map<String, dynamic> _buildBody({required bool isF17}) {
    String? _nv(String s) => s == 'ALL' ? null : s;

    if (isF17) {
      final Map<String, dynamic> b = {
        'Factory': selFactory.value,
        if (_nv(selFloor.value) != null) 'Floor': _nv(selFloor.value),
        if (_nv(selRoom.value) != null) 'Location': _nv(selRoom.value),
        if (_nv(selGroup.value) != null) 'GroupName': _nv(selGroup.value),
        if (_nv(selModel.value) != null) 'ModelSerial': _nv(selModel.value),
      };
      vlog(() => ' GỬI BODY F17(web): $b');
      return b;
    } else {
      final Map<String, dynamic> b = {
        'factory': selFactory.value,
        if (_nv(selFloor.value) != null) 'floor': _nv(selFloor.value),
        if (_nv(selRoom.value) != null) 'room': _nv(selRoom.value),
        if (_nv(selGroup.value) != null) 'groupName': _nv(selGroup.value),
        if (_nv(selModel.value) != null) 'modelSerial': _nv(selModel.value),
        'nickName': '',
        'rangeDateTime': '',
        'rackNames': <Map<String, dynamic>>[],
      };
      vlog(() => ' GỬI BODY F16(app): $b');
      return b;
    }
  }

  Future<void> refresh() async {
    try {
      isLoading.value = true;
      error.value = null;

      await RackMonitorApi.quickPing();

      final isF17 = selFactory.value.trim().toUpperCase() == 'F17';
      final tower = isF17 ? Tower.f17 : Tower.f16;

      final res = await RackMonitorApi.getByTower(
        tower: tower,
        body: _buildBody(isF17: isF17),
      );
      data.value = res;

      _logSnapshot();
    } catch (e) {
      error.value = 'Refresh failed: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void clearFiltersKeepFactory() {
    selFloor.value = 'ALL';
    selRoom.value = 'ALL';
    selGroup.value = 'ALL';
    selModel.value = 'ALL';
    _rebuildDependentOptions();
  }

  double get kpiUT => data.value?.quantitySummary.ut ?? 0.0;

  int get kpiInput => data.value?.quantitySummary.input ?? 0;

  int get kpiPass => data.value?.quantitySummary.pass ?? 0;

  int get kpiRePass => data.value?.quantitySummary.rePass ?? 0;

  int get kpiFail => data.value?.quantitySummary.fail ?? 0;

  double get kpiFpr => data.value?.quantitySummary.fpr ?? 0.0;

  double get kpiYr => data.value?.quantitySummary.yr ?? 0.0;

  int get kpiWip => data.value?.quantitySummary.wip ?? 0;

  List<ModelPass> get passByModelAgg {
    final agg = <String, _Agg>{};
    final racks = data.value?.rackDetails ?? const <RackDetail>[];
    final rackSAs = <String>{};

    for (final r in racks) {
      final rackSA = _extractSA(r.modelName);
      if (rackSA.isNotEmpty) rackSAs.add(rackSA);

      if (r.slotDetails.isEmpty) {
        if (rackSA.isEmpty) continue;
        final a = agg.putIfAbsent(rackSA, () => _Agg());
        a.pass += r.totalPass;
        a.totalPass += r.totalPass;
        continue;
      }

      for (final s in r.slotDetails) {
        String slotSA = _extractSA(s.modelName);

        if (slotSA.isEmpty && rackSA.isNotEmpty) {
          vlog(
            () =>
                '↪ NORMALIZE: ${r.rackName}/${s.slotNumber} slotSA="" -> rackSA=$rackSA (total=${s.totalPass})',
          );
          slotSA = rackSA;
        }

        if (slotSA.isNotEmpty &&
            rackSA.isNotEmpty &&
            slotSA != rackSA &&
            _diffAtMostOneChar(slotSA, rackSA)) {
          vlog(
            () =>
                '↪ NORMALIZE: ${r.rackName}/${s.slotNumber} slotSA=$slotSA ~ rackSA=$rackSA -> use rackSA (total=${s.totalPass})',
          );
          slotSA = rackSA;
        }

        if (slotSA.isEmpty) continue;

        final a = agg.putIfAbsent(slotSA, () => _Agg());
        a.pass += s.totalPass;
        a.totalPass += s.totalPass;
      }
    }

    final merged = _mergeNearCodes(agg, rackSAs, log: _verbose.value);

    final list =
        merged.entries
            .map((e) => ModelPass(e.key, e.value.pass, e.value.totalPass))
            .toList()
          ..sort((a, b) => b.pass.compareTo(a.pass));
    return list;
  }

  void _logSnapshot() {
    if (!_verbose.value) return;
    final qs = data.value?.quantitySummary;
    if (qs == null) return;

    vlog(() => '===== SNAPSHOT =====');
    vlog(
      () =>
          'Factory=${selFactory.value}  Floor=${selFloor.value}  Room=${selRoom.value}  Group=${selGroup.value}  Model=${selModel.value}',
    );
    vlog(
      () =>
          'UT=${qs.ut.toStringAsFixed(2)}%  INPUT=${qs.input}  FAIL=${qs.fail}  PASS=${qs.pass}  RE-PASS=${qs.rePass}  TOTAL_PASS=${qs.totalPass}',
    );

    for (final r in data.value?.rackDetails ?? const <RackDetail>[]) {
      for (final s in r.slotDetails) {
        final sa = _extractSA(
          s.modelName.isNotEmpty ? s.modelName : r.modelName,
        );
        vlog(
          () =>
              '· SLOT ${r.rackName}/${s.slotNumber}  SA=$sa  pass=${s.pass}  total=${s.totalPass}',
        );
      }
    }

    final agg = passByModelAgg;
    vlog(() => '--- PASS BY MODEL (Output = totalPass, merged) ---');
    for (final it in agg) {
      vlog(() => 'SA=${it.model}  Output=${it.pass}');
    }
    vlog(() => '====================\n');
  }

  Map<String, int> get slotStatusCount {
    final m = <String, int>{};
    for (final s in data.value?.slotStatic ?? const <SlotStaticItem>[]) {
      m[s.status] = (m[s.status] ?? 0) + s.value;
    }
    return m;
  }

  List<RackDetail> get racks => data.value?.rackDetails ?? const <RackDetail>[];

  List<SlotDetail> slotsOfRack(int i) {
    final rs = racks;
    if (i < 0 || i >= rs.length) return const <SlotDetail>[];
    return rs[i].slotDetails;
  }
}
