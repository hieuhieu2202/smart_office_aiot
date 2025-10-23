import 'dart:async';

import 'package:get/get.dart';

import '../../data/datasources/nvidia_kanban_remote_data_source.dart';
import '../../data/repositories/nvidia_kanban_repository_impl.dart';
import '../../domain/entities/kanban_entities.dart';
import '../../domain/usecases/get_groups.dart';
import '../../domain/usecases/get_output_tracking.dart';
import '../../domain/usecases/get_output_tracking_detail.dart';
import '../../domain/usecases/get_uph_tracking.dart';
import '../viewmodels/output_tracking_view_state.dart';

class OutputTrackingController extends GetxController {
  OutputTrackingController({
    GetGroups? getGroups,
    GetOutputTracking? getOutputTracking,
    GetOutputTrackingDetail? getOutputTrackingDetail,
    GetUphTracking? getUphTracking,
    NvidiaKanbanRepositoryImpl? repository,
  }) : _repository = repository ??
          NvidiaKanbanRepositoryImpl(
            remoteDataSource: NvidiaKanbanRemoteDataSource(),
          ) {
    final repo = _repository;
    _getGroups = getGroups ?? GetGroups(repo);
    _getOutputTracking = getOutputTracking ?? GetOutputTracking(repo);
    _getOutputTrackingDetail =
        getOutputTrackingDetail ?? GetOutputTrackingDetail(repo);
    _getUphTracking = getUphTracking ?? GetUphTracking(repo);
  }

  final NvidiaKanbanRepositoryImpl _repository;
  late final GetGroups _getGroups;
  late final GetOutputTracking _getOutputTracking;
  late final GetOutputTrackingDetail _getOutputTrackingDetail;
  late final GetUphTracking _getUphTracking;

  // ====== Filter state ======
  final RxString modelSerial = 'SWITCH'.obs;
  final Rx<DateTime> date = DateTime.now().obs;
  final RxString shift = 'Day'.obs;
  final RxList<String> groups = <String>['699-1T363-0100-000'].obs;

  final RxString dateRange = 'string'.obs;
  final RxString section = 'string'.obs;
  final RxString station = 'string'.obs;
  final RxString line = 'string'.obs;
  final RxString customer = 'string'.obs;
  final RxString nickName = 'string'.obs;
  final RxString modelName = 'string'.obs;

  // Loading & error
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  // Payloads
  final Rxn<OutputTrackingEntity> outputTracking = Rxn<OutputTrackingEntity>();
  final Rxn<UphTrackingEntity> uphTracking = Rxn<UphTrackingEntity>();
  final Rxn<OtViewState> outputTrackingView = Rxn<OtViewState>();

  final RxList<String> allModels = <String>[].obs;
  final RxBool isLoadingModels = false.obs;

  final RxMap<String, String> _modelByStation = <String, String>{}.obs;

  final RxBool isAutoRefreshEnabled = true.obs;
  final RxInt refreshSec = 60.obs;
  Timer? _timer;

  // ---------------- Public API ----------------
  Future<void> updateFilter({
    String? newModelSerial,
    DateTime? newDate,
    String? newShift,
    List<String>? newGroups,
    String? newDateRange,
    String? newSection,
    String? newStation,
    String? newLine,
    String? newCustomer,
    String? newNickName,
    String? newModelName,
  }) async {
    var shouldReloadModels = false;

    if (newModelSerial != null && newModelSerial != modelSerial.value) {
      modelSerial.value = newModelSerial;
      shouldReloadModels = true;
    }
    if (newDate != null && !_isSameDay(newDate, date.value)) {
      date.value = newDate;
      shouldReloadModels = true;
    }
    if (newShift != null && newShift != shift.value) {
      shift.value = newShift;
      shouldReloadModels = true;
    }

    if (newGroups != null) {
      groups
        ..clear()
        ..addAll(newGroups);
    }

    if (newDateRange != null) dateRange.value = newDateRange;
    if (newSection != null) section.value = newSection;
    if (newStation != null) station.value = newStation;
    if (newLine != null) line.value = newLine;
    if (newCustomer != null) customer.value = newCustomer;
    if (newNickName != null) nickName.value = newNickName;
    if (newModelName != null) modelName.value = newModelName;

    if (shouldReloadModels) {
      await ensureModels(force: true, selectAll: groups.isEmpty);
    }

    await loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    error.value = null;
    outputTrackingView.value = null;

    try {
      final KanbanRequest request = _currentRequest();
      NvidiaKanbanLogger.net(() => '[OutputTrackingController] loadAll body=${request.toBody()}');

      final results = await Future.wait([
        _getOutputTracking(request),
        _getUphTracking(request),
      ]);

      outputTracking.value = results[0] as OutputTrackingEntity;
      uphTracking.value = results[1] as UphTrackingEntity;

      await _rebuildModelByStation();
      _mergeModelsFromResponses();
      _rebuildOutputTrackingView();
    } catch (e) {
      error.value = e.toString();
      outputTrackingView.value = null;
      NvidiaKanbanLogger.net(() => '[OutputTrackingController] loadAll ERROR: $e');
    } finally {
      isLoading.value = false;
      if (isAutoRefreshEnabled.value) {
        startAutoRefresh();
      }
    }
  }

  Future<void> ensureModels({bool force = false, bool selectAll = false}) async {
    if (!force && allModels.length > 1) {
      if (selectAll && allModels.isNotEmpty) {
        groups
          ..clear()
          ..addAll(allModels);
      }
      return;
    }

    isLoadingModels.value = true;
    try {
      final List<String> list = await _getGroups(
        _currentRequest(groups: const <String>[]),
      );

      if (list.isNotEmpty) {
        allModels.assignAll(list);
        if (selectAll) {
          groups
            ..clear()
            ..addAll(list);
        }
      } else {
        _mergeModelsFromResponses();
        if (selectAll && allModels.isNotEmpty) {
          groups
            ..clear()
            ..addAll(allModels);
        }
      }
      NvidiaKanbanLogger.net(
        () => '[OutputTrackingController] ensureModels count=${allModels.length}',
      );
    } catch (e) {
      NvidiaKanbanLogger.net(
        () => '[OutputTrackingController] ensureModels ERROR: $e',
      );
      if (allModels.isEmpty) {
        _mergeModelsFromResponses();
      }
      if (selectAll && allModels.isNotEmpty) {
        groups
          ..clear()
          ..addAll(allModels);
      }
    } finally {
      isLoadingModels.value = false;
    }
  }

  Future<OutputTrackingDetailEntity> fetchOutputTrackingDetail({
    required String station,
    required String section,
  }) async {
    final Set<String> selection = <String>{};

    void addIfNotEmpty(Iterable<String> values) {
      selection.addAll(values.map((e) => e.trim()).where((e) => e.isNotEmpty));
    }

    if (groups.isNotEmpty) addIfNotEmpty(groups);
    addIfNotEmpty(outputTracking.value?.models ?? const <String>[]);
    if (allModels.isNotEmpty) addIfNotEmpty(allModels);

    final List<String> groupList = selection.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (groupList.isEmpty) {
      throw Exception('Không có model nào được chọn.');
    }

    final OutputTrackingDetailParams params = OutputTrackingDetailParams(
      modelSerial: modelSerial.value,
      date: _fmt(date.value),
      shift: shift.value,
      groups: groupList,
      station: station,
      section: _normalizeSectionParam(section),
    );

    return _getOutputTrackingDetail(params);
  }

  void _mergeModelsFromResponses() {
    final Set<String> merged = <String>{...allModels};
    final OutputTrackingEntity? ot = outputTracking.value;
    final UphTrackingEntity? uph = uphTracking.value;
    if (ot != null) merged.addAll(ot.models);
    if (uph != null) merged.addAll(uph.models);
    if (merged.isNotEmpty) {
      final List<String> ordered = merged.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      allModels.assignAll(ordered);
    }
  }

  void _rebuildOutputTrackingView() {
    final OutputTrackingEntity? out = outputTracking.value;
    if (out == null) {
      outputTrackingView.value = null;
      return;
    }

    final List<String> fallback = out.models
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (fallback.isEmpty) {
      fallback.addAll(groups.map((e) => e.trim()).where((e) => e.isNotEmpty));
    }

    outputTrackingView.value = OtViewState.fromResponse(
      hours: hours,
      groups: out.groups,
      modelByStation: modelNameByGroup,
      fallbackModels: fallback,
    );
  }

  Future<void> _rebuildModelByStation() async {
    _modelByStation.clear();
    final OutputTrackingEntity? out = outputTracking.value;
    if (out == null) return;

    final List<String> stations = [
      for (final OutputGroupEntity g in out.groups) g.groupName.trim(),
    ];

    if (out.models.length == 1 && out.models.first.trim().isNotEmpty) {
      final String model = out.models.first.trim();
      for (final String st in stations) {
        _modelByStation[st] = model;
      }
      _debugModelMapLog();
      return;
    }

    if (out.models.isNotEmpty && out.models.length == out.groups.length) {
      for (int i = 0; i < out.groups.length; i++) {
        final String st = out.groups[i].groupName.trim();
        final String md = out.models[i].trim();
        if (st.isNotEmpty) {
          _modelByStation[st] = md.isEmpty ? '-' : md;
        }
      }
      _debugModelMapLog();
      return;
    }

    await _rebuildModelByStationFanout(stations);
    _debugModelMapLog();
  }

  Future<void> _rebuildModelByStationFanout(List<String> allStations) async {
    if (groups.isEmpty) {
      for (final String st in allStations) {
        _modelByStation[st] = '-';
      }
      return;
    }

    try {
      for (final String model in groups) {
        final OutputTrackingEntity? ot = await _fetchOtForModelSafe(model);
        if (ot == null) continue;
        for (final OutputGroupEntity row in ot.groups) {
          final String st = row.groupName.trim();
          if (st.isEmpty) continue;
          if (allStations.contains(st)) {
            _modelByStation[st] = model.trim().isEmpty ? '-' : model.trim();
          }
        }
      }

      for (final String st in allStations) {
        _modelByStation.putIfAbsent(st, () => '-');
      }
    } catch (e) {
      for (final String st in allStations) {
        _modelByStation.putIfAbsent(st, () => '-');
      }
      NvidiaKanbanLogger.net(
        () => '[OutputTrackingController] fan-out modelByStation ERROR: $e',
      );
    }
  }

  Future<OutputTrackingEntity> _fetchOtForModel(String model) {
    final KanbanRequest request = _currentRequest(groups: <String>[model]);
    NvidiaKanbanLogger.net(
      () => '[OutputTrackingController] FANOUT body=${request.toBody()}',
    );
    return _getOutputTracking(request);
  }

  Future<OutputTrackingEntity?> _fetchOtForModelSafe(String model) async {
    try {
      return await _fetchOtForModel(model);
    } catch (e) {
      NvidiaKanbanLogger.net(
        () => '[OutputTrackingController] fanout "$model" => NO DATA ($e)',
      );
      return null;
    }
  }

  void _debugModelMapLog() {
    final int n = _modelByStation.length;
    final String sample = _modelByStation.entries
        .take(5)
        .map((e) => '${e.key} -> ${e.value}')
        .join(' | ');
    NvidiaKanbanLogger.net(
      () => '[OutputTrackingController] modelByStation size=$n; sample: $sample',
    );
  }

  void setNetworkLog(bool on) => NvidiaKanbanLogger.network = on;

  void startAutoRefresh() {
    _timer?.cancel();
    if (!isAutoRefreshEnabled.value) return;
    _timer = Timer.periodic(
      Duration(seconds: refreshSec.value),
      (_) async => loadAll(),
    );
  }

  void stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  int _sumInt(List<double>? list) {
    final Iterable<double> source = list ?? const <double>[];
    return source.fold<int>(0, (sum, value) => sum + value.round());
  }

  List<String> get hours {
    final OutputTrackingEntity? out = outputTracking.value;
    if (out != null && out.sections.isNotEmpty) return out.sections;
    final UphTrackingEntity? uph = uphTracking.value;
    return uph?.sections ?? const <String>[];
  }

  Map<String, List<double>> get passSeriesByGroup => {
        for (final OutputGroupEntity g in (outputTracking.value?.groups ?? const []))
          g.groupName: g.pass,
      };

  Map<String, List<double>> get yrSeriesByGroup => {
        for (final OutputGroupEntity g in (outputTracking.value?.groups ?? const []))
          g.groupName: g.yr,
      };

  Map<String, List<double>> get rrSeriesByGroup => {
        for (final OutputGroupEntity g in (outputTracking.value?.groups ?? const []))
          g.groupName: g.rr,
      };

  Map<String, int> get wipByGroup => {
        for (final OutputGroupEntity g in (outputTracking.value?.groups ?? const []))
          g.groupName: g.wip,
      };

  Map<String, int> get totalPassByGroup => {
        for (final OutputGroupEntity g in (outputTracking.value?.groups ?? const []))
          g.groupName: _sumInt(g.pass),
      };

  Map<String, int> get totalFailByGroup => {
        for (final OutputGroupEntity g in (outputTracking.value?.groups ?? const []))
          g.groupName: _sumInt(g.fail),
      };

  int get totalPass => (outputTracking.value?.groups ?? const [])
      .fold<int>(0, (sum, g) => sum + _sumInt(g.pass));

  int get totalFail => (outputTracking.value?.groups ?? const [])
      .fold<int>(0, (sum, g) => sum + _sumInt(g.fail));

  double get avgYr {
    final List<double> values =
        (outputTracking.value?.groups ?? const []).expand((g) => g.yr).toList();
    if (values.isEmpty) return 0;
    final double total = values.fold<double>(0.0, (sum, value) => sum + value);
    return total / values.length;
  }

  double get avgRr {
    final List<double> values =
        (outputTracking.value?.groups ?? const []).expand((g) => g.rr).toList();
    if (values.isEmpty) return 0;
    final double total = values.fold<double>(0.0, (sum, value) => sum + value);
    return total / values.length;
  }

  int get totalWip =>
      (outputTracking.value?.groups ?? const []).fold<int>(0, (sum, g) => sum + g.wip);

  Map<String, String> get modelNameByGroup {
    if (_modelByStation.isNotEmpty) {
      return Map<String, String>.from(_modelByStation);
    }

    final OutputTrackingEntity? out = outputTracking.value;
    if (out == null) return const <String, String>{};

    final Map<String, String> map = <String, String>{};

    if (out.models.length == 1) {
      final String model = out.models.first.trim();
      for (final OutputGroupEntity row in out.groups) {
        map[row.groupName] = model.isEmpty ? '-' : model;
      }
    } else {
      final int len = out.groups.length < out.models.length
          ? out.groups.length
          : out.models.length;
      for (int i = 0; i < len; i++) {
        map[out.groups[i].groupName] =
            out.models[i].trim().isEmpty ? '-' : out.models[i].trim();
      }
      for (final OutputGroupEntity row in out.groups.skip(len)) {
        map.putIfAbsent(row.groupName, () => '-');
      }
    }
    return map;
  }

  @override
  void onInit() {
    super.onInit();
    setNetworkLog(true);
    Future.microtask(() async {
      await ensureModels(force: true, selectAll: true);
      if (groups.isEmpty && allModels.isNotEmpty) {
        groups
          ..clear()
          ..addAll(allModels);
      }
      await loadAll();
      if (isAutoRefreshEnabled.value) {
        startAutoRefresh();
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  KanbanRequest _currentRequest({List<String>? groups, String? section}) {
    return KanbanRequest(
      modelSerial: modelSerial.value,
      date: _fmt(date.value),
      shift: shift.value,
      dateRange: dateRange.value,
      groups: groups ?? this.groups.toList(),
      section: section ?? this.section.value,
      station: station.value,
      line: line.value,
      customer: customer.value,
      nickName: nickName.value,
      modelName: modelName.value,
    );
  }

  String _normalizeSectionParam(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    final String digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return trimmed;

    final int? parsed = int.tryParse(digitsOnly);
    if (parsed == null) return trimmed;
    if (parsed == 24) return '24';

    final int bounded = parsed % 100;
    return bounded.toString().padLeft(2, '0');
  }
}

String _fmt(DateTime d) {
  final String y = d.year.toString().padLeft(4, '0');
  final String m = d.month.toString().padLeft(2, '0');
  final String day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
