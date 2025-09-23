import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../service/lc_switch_rack_api.dart';

// ======================= Helpers (TOP-LEVEL) =======================
final RegExp _saRe = RegExp(r'(SA0+\d+|SA\d{6,})', caseSensitive: false);

const String _allOptionLabel = 'ALL';

bool _isAllLabel(String value) => value.trim().toUpperCase() == _allOptionLabel;

String _normalizeFilterValue(String value) {
  final trimmed = value.trim();
  return _isAllLabel(trimmed) ? '' : trimmed;
}

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
  final floors = <String>[].obs;
  final rooms = <String>[].obs;
  final groups = <String>[].obs;
  final models = <String>[].obs;

  final selFactory = 'F16'.obs;
  final selFloor = ''.obs;
  final selRoom = ''.obs;
  final selGroup = ''.obs;
  final selModel = ''.obs;

  bool _isSyncingFilters = false;

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
      if (_isSyncingFilters) return;
      _withFilterSync(() {
        selFloor.value = '';
        selRoom.value = '';
        selGroup.value = '';
        selModel.value = '';
      });
      _rebuildDependentOptions();
      refresh();
    });

    ever(selFloor, (_) {
      if (_isSyncingFilters) return;
      _rebuildDependentOptions();
      refresh();
    });
    ever(selRoom, (_) {
      if (_isSyncingFilters) return;
      _rebuildDependentOptions();
      refresh();
    });
    ever(selGroup, (_) {
      if (_isSyncingFilters) return;
      _rebuildDependentOptions();
      refresh();
    });
    ever(selModel, (_) {
      if (_isSyncingFilters) return;
      refresh();
    });
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
        ..addAll(['3F']);
      rooms
        ..clear()
        ..addAll([_allOptionLabel, 'ROOM1', 'ROOM2']);
      groups
        ..clear()
        ..addAll(['CTO', 'FT', 'J_TAG']);
      models
        ..clear()
        ..addAll([_allOptionLabel, 'GB200', 'GB300']);
      _withFilterSync(() {
        selFloor.value = floors.isNotEmpty ? floors.first : '';
        selRoom.value = rooms.isNotEmpty ? rooms.first : '';
        selGroup.value = groups.isNotEmpty ? groups.first : '';
        selModel.value = models.isNotEmpty ? models.first : '';
      });
    }
  }

  List<String> _mkOpts(
    Iterable<String> vals, {
    bool includeAll = false,
  }) {
    final s = <String>{};
    for (final v in vals) {
      final t = v.trim();
      if (t.isNotEmpty) s.add(t);
    }
    final list = s.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (includeAll) {
      list.removeWhere(_isAllLabel);
      list.insert(0, _allOptionLabel);
    }
    return list;
  }

  String _resolveDefaultSelection(
    List<String> opts, {
    required bool preferAll,
  }) {
    if (opts.isEmpty) return '';
    if (preferAll) {
      final allOpt = opts.firstWhere(_isAllLabel, orElse: () => '');
      if (allOpt.isNotEmpty) return allOpt;
    }
    return opts.firstWhere(
      (e) => !_isAllLabel(e),
      orElse: () => opts.first,
    );
  }

  void _rebuildDependentOptions() {
    final fact = selFactory.value.trim();

    _withFilterSync(() {
      final currentFloor = selFloor.value.trim();
      final newFloors = _mkOpts(
        _allLocs.where((e) => e.factory == fact).map((e) => e.floor),
      );
      floors
        ..clear()
        ..addAll(newFloors);
      final nextFloor =
          (currentFloor.isNotEmpty && newFloors.contains(currentFloor))
              ? currentFloor
              : (newFloors.isNotEmpty ? newFloors.first : '');
      if (selFloor.value != nextFloor) selFloor.value = nextFloor;
      final activeFloor = selFloor.value.trim();

      Iterable<LocationEntry> qRoom =
          _allLocs.where((e) => e.factory == fact);
      if (activeFloor.isNotEmpty) {
        qRoom = qRoom.where((e) => e.floor == activeFloor);
      }
      final currentRoom = selRoom.value.trim();
      final newRooms = _mkOpts(
        qRoom.map((e) => e.room),
        includeAll: true,
      );
      rooms
        ..clear()
        ..addAll(newRooms);
      final nextRoom =
          (currentRoom.isNotEmpty && newRooms.contains(currentRoom))
              ? currentRoom
              : _resolveDefaultSelection(
                  newRooms,
                  preferAll: currentRoom.isEmpty || _isAllLabel(currentRoom),
                );
      if (selRoom.value != nextRoom) selRoom.value = nextRoom;
      final activeRoom = _normalizeFilterValue(selRoom.value);

      Iterable<LocationEntry> qGroup = qRoom;
      if (activeRoom.isNotEmpty) {
        qGroup = qGroup.where((e) => e.room == activeRoom);
      }
      final currentGroup = selGroup.value.trim();
      final newGroups = _mkOpts(qGroup.map((e) => e.group));
      groups
        ..clear()
        ..addAll(newGroups);
      final nextGroup =
          (currentGroup.isNotEmpty && newGroups.contains(currentGroup))
              ? currentGroup
              : (newGroups.isNotEmpty ? newGroups.first : '');
      if (selGroup.value != nextGroup) selGroup.value = nextGroup;
      final activeGroup = selGroup.value.trim();

      Iterable<LocationEntry> qModel = qGroup;
      if (activeGroup.isNotEmpty) {
        qModel = qModel.where((e) => e.group == activeGroup);
      }
      final currentModel = selModel.value.trim();
      final newModels = _mkOpts(
        qModel.map((e) => e.model),
        includeAll: true,
      );
      models
        ..clear()
        ..addAll(newModels);
      final nextModel =
          (currentModel.isNotEmpty && newModels.contains(currentModel))
              ? currentModel
              : _resolveDefaultSelection(
                  newModels,
                  preferAll: currentModel.isEmpty || _isAllLabel(currentModel),
                );
      if (selModel.value != nextModel) selModel.value = nextModel;

      vlog(
        () =>
            'FILTER OPTIONS REBUILD: '
            'Factory=$fact, Floor=${selFloor.value}, Room=${selRoom.value}, Group=${selGroup.value}\n'
            'Floors=${floors.join(", ")}\n'
            'Rooms=${rooms.join(", ")}\n'
            'Groups=${groups.join(", ")}\n'
            'Models=${models.join(", ")}',
      );
    });
  }

  Map<String, dynamic> _buildBody({required bool isF17}) {
    String? _nv(String s) {
      final normalized = _normalizeFilterValue(s);
      return normalized.isEmpty ? null : normalized;
    }

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
    _withFilterSync(() {
      selFloor.value = '';
      selRoom.value = '';
      selGroup.value = '';
      selModel.value = '';
    });
    _rebuildDependentOptions();
    refresh();
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
          'Factory=${selFactory.value}  Floor=${selFloor.value.isEmpty ? "-" : selFloor.value}  '
          'Room=${selRoom.value.isEmpty ? "-" : selRoom.value}  '
          'Group=${selGroup.value.isEmpty ? "-" : selGroup.value}  '
          'Model=${selModel.value.isEmpty ? "-" : selModel.value}',
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

  void _withFilterSync(VoidCallback run) {
    final prev = _isSyncingFilters;
    _isSyncingFilters = true;
    try {
      run();
    } finally {
      _isSyncingFilters = prev;
    }
  }
}
