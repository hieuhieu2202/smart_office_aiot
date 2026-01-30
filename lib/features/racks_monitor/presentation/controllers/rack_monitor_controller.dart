import 'dart:async';
import 'package:get/get.dart';

import '../../../../service/lc_switch_rack_api.dart' show CuringApiLog;
import '../../domain/entities/rack_entities.dart';
import '../../domain/usecases/get_rack_locations.dart';
import '../../domain/usecases/get_rack_monitoring_data.dart';
import '../utils/rack_data_utils.dart';

/// Rack Monitor Controller using GetX
/// Manages UI state and business logic for the rack monitoring screen
class RackMonitorController extends GetxController {
  final GetRackLocations getRackLocations;
  final GetRackMonitoringData getRackMonitoringData;

  RackMonitorController({
    required this.getRackLocations,
    required this.getRackMonitoringData,
    this.initialFactory,
    this.initialFloor,
    this.initialRoom,
    this.initialGroup,
    this.initialModel,
  });

  final String? initialFactory;
  final String? initialFloor;
  final String? initialRoom;
  final String? initialGroup;
  final String? initialModel;

  // ========= Filter Options =========
  List<RackMonitorLocation> _allLocations = const [];

  final factories = <String>['F16', 'F17'].obs;
  final floors = <String>[].obs;
  final rooms = <String>['ALL'].obs;
  final groups = <String>[].obs;
  final models = <String>['ALL'].obs;

  // ========= Selected Filters =========
  final selFactory = 'F16'.obs;
  final selFloor = ''.obs;
  final selRoom = 'ALL'.obs;
  final selGroup = ''.obs;
  final selModel = 'ALL'.obs;

  // ========= UI State =========
  final showOfflineRack = true.obs;
  final showAnimation = false.obs;

  final data = Rxn<RackMonitorData>();
  final isLoading = false.obs;
  final error = RxnString();

  // ========= Auto Refresh =========
  final autoRefresh = true.obs;
  final intervalSec = 10.obs;
  Timer? _timer;

  @override
  Future<void> onInit() async {
    super.onInit();
    CuringApiLog.network = true;

    await _loadFilterSources();
    _applyInitialSelections();
    await refresh();

    debounce(intervalSec, (_) => _restartTimer());
    ever(autoRefresh, (_) => _restartTimer());
    _restartTimer();

    // Watch filter changes
    ever(selFactory, (_) {
      selFloor.value = '';
      selRoom.value = 'ALL';
      selGroup.value = '';
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

  void _applyInitialSelections() {
    final targetFactory = initialFactory?.trim();
    if (targetFactory != null && factories.contains(targetFactory)) {
      selFactory.value = targetFactory;
      _rebuildDependentOptions();
    }

    final targetFloor = initialFloor?.trim();
    if (targetFloor != null && floors.contains(targetFloor)) {
      selFloor.value = targetFloor;
    }

    final targetRoom = initialRoom?.trim();
    if (targetRoom != null && rooms.contains(targetRoom)) {
      selRoom.value = targetRoom;
    }

    final targetGroup = initialGroup?.trim();
    if (targetGroup != null && groups.contains(targetGroup)) {
      selGroup.value = targetGroup;
    }

    final targetModel = initialModel?.trim();
    if (targetModel != null && models.contains(targetModel)) {
      selModel.value = targetModel;
    }

    _rebuildDependentOptions();
  }

  Future<void> _loadFilterSources() async {
    try {
      _allLocations = await getRackLocations.call();

      final fset = {for (final e in _allLocations) e.factory.trim()}
        ..removeWhere((e) => e.isEmpty);

      if (fset.isNotEmpty) {
        factories
          ..clear()
          ..addAll(fset.toList()..sort());
        if (!factories.contains(selFactory.value)) {
          selFactory.value = factories.first;
        }
      }

      _rebuildDependentOptions();
    } catch (e) {
      error.value = 'Load filters failed: $e';
      _allLocations = const [];

      // Fallback defaults
      factories
        ..clear()
        ..addAll(['F16', 'F17']);
      floors
        ..clear()
        ..addAll(['3F']);
      rooms
        ..clear()
        ..addAll(['ALL', 'ROOM1', 'ROOM2']);
      groups
        ..clear()
        ..addAll(['CTO', 'FT', 'J_TAG']);
      models
        ..clear()
        ..addAll(['ALL', 'GB200', 'GB300']);
    }
  }

  List<String> _mkOpts(Iterable<String> vals, {bool includeAll = true}) {
    final s = <String>{};
    for (final v in vals) {
      final t = v.trim();
      if (t.isNotEmpty) s.add(t);
    }
    final list = s.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (includeAll) return ['ALL', ...list];
    return list;
  }

  void _rebuildDependentOptions() {
    final fact = selFactory.value.trim();
    final floor = selFloor.value.trim();
    final room = selRoom.value.trim();
    final group = selGroup.value.trim();

    final newFloors = _mkOpts(
      _allLocations.where((e) => e.factory == fact).map((e) => e.floor),
      includeAll: false,
    );
    floors
      ..clear()
      ..addAll(newFloors);
    if (!floors.contains(selFloor.value)) {
      selFloor.value = floors.isNotEmpty ? floors.first : '';
    }

    Iterable<RackMonitorLocation> qRoom =
        _allLocations.where((e) => e.factory == fact);
    if (selFloor.value.isNotEmpty) {
      qRoom = qRoom.where((e) => e.floor == floor);
    }
    final newRooms = _mkOpts(qRoom.map((e) => e.room));
    rooms
      ..clear()
      ..addAll(newRooms);
    if (!rooms.contains(selRoom.value)) {
      selRoom.value = rooms.isNotEmpty ? rooms.first : 'ALL';
    }

    Iterable<RackMonitorLocation> qGroup = qRoom;
    if (selRoom.value != 'ALL') {
      qGroup = qGroup.where((e) => e.room == room);
    }
    final newGroups = _mkOpts(qGroup.map((e) => e.group), includeAll: false);
    groups
      ..clear()
      ..addAll(newGroups);
    if (!groups.contains(selGroup.value)) {
      selGroup.value = groups.isNotEmpty ? groups.first : '';
    }

    Iterable<RackMonitorLocation> qModel = qGroup;
    if (selGroup.value.isNotEmpty && selGroup.value != 'ALL') {
      qModel = qModel.where((e) => e.group == group);
    }
    final newModels = _mkOpts(qModel.map((e) => e.model));
    models
      ..clear()
      ..addAll(newModels);
    if (!models.contains(selModel.value)) selModel.value = 'ALL';
  }

  Future<void> refresh() async {
    try {
      isLoading.value = true;
      error.value = null;

      String _orAll(String s) => (s.isEmpty ? 'ALL' : s).trim();

      final data = await getRackMonitoringData.call(
        factory: _orAll(selFactory.value),
        floor: _orAll(selFloor.value),
        room: _orAll(selRoom.value),
        group: _orAll(selGroup.value),
        model: _orAll(selModel.value),
      );

      this.data.value = data;
    } catch (e) {
      error.value = 'Refresh failed: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void clearFiltersKeepFactory() {
    selFloor.value = floors.isNotEmpty ? floors.first : '';
    selRoom.value = 'ALL';
    selGroup.value = '';
    selModel.value = 'ALL';
    _rebuildDependentOptions();
  }

  // ========= Computed Properties (KPIs) =========
  double get kpiUT => data.value?.quantitySummary.ut ?? 0.0;
  int get kpiInput => data.value?.quantitySummary.input ?? 0;
  int get kpiPass => data.value?.quantitySummary.pass ?? 0;
  int get kpiRePass => data.value?.quantitySummary.rePass ?? 0;
  int get kpiFail => data.value?.quantitySummary.fail ?? 0;
  double get kpiFpr => data.value?.quantitySummary.fpr ?? 0.0;
  double get kpiYr => data.value?.quantitySummary.yr ?? 0.0;
  int get kpiWip => data.value?.quantitySummary.wip ?? 0;

  List<ModelPassSummary> get passByModelAgg {
    return RackDataUtils.aggregateModelPass(
      data.value?.modelDetails ?? [],
      data.value?.rackDetails ?? [],
    );
  }

  Map<String, int> get slotStatusCount {
    final m = <String, int>{};
    for (final s in data.value?.slotStatic ?? const <SlotStaticItem>[]) {
      m[s.status] = (m[s.status] ?? 0) + s.value;
    }
    return m;
  }

  List<RackDetail> get racks => data.value?.rackDetails ?? const [];

  List<SlotDetail> slotsOfRack(int i) {
    final rs = racks;
    if (i < 0 || i >= rs.length) return const [];
    return rs[i].slotDetails;
  }
}

