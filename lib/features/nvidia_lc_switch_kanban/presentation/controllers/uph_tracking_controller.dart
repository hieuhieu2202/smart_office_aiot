import 'dart:async';

import 'package:get/get.dart';

import '../../data/datasources/nvidia_kanban_remote_data_source.dart';
import '../../data/repositories/nvidia_kanban_repository_impl.dart';
import '../../domain/entities/kanban_entities.dart';
import '../../domain/usecases/get_groups.dart';
import '../../domain/usecases/get_uph_tracking.dart';
import '../viewmodels/uph_tracking_view_state.dart';

class UphTrackingController extends GetxController {
  UphTrackingController({
    GetGroups? getGroups,
    GetUphTracking? getUphTracking,
    NvidiaKanbanRepositoryImpl? repository,
    String initialModelSerial = 'SWITCH',
  }) : _repository = repository ??
            NvidiaKanbanRepositoryImpl(
              remoteDataSource: NvidiaKanbanRemoteDataSource(),
            ) {
    final repo = _repository;
    _getGroups = getGroups ?? GetGroups(repo);
    _getUphTracking = getUphTracking ?? GetUphTracking(repo);

    final serial = initialModelSerial.trim().isEmpty
        ? 'SWITCH'
        : initialModelSerial.trim().toUpperCase();
    modelSerial.value = serial;
  }

  final NvidiaKanbanRepositoryImpl _repository;
  late final GetGroups _getGroups;
  late final GetUphTracking _getUphTracking;

  final RxString modelSerial = 'SWITCH'.obs;
  final Rx<DateTime> date = DateTime.now().obs;
  final RxString shift = 'ALL'.obs;
  final RxList<String> selectedGroups = <String>[].obs;
  final RxList<String> allGroups = <String>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingGroups = false.obs;
  final RxnString error = RxnString();
  final Rxn<UphTrackingViewState> viewState = Rxn<UphTrackingViewState>();

  Timer? _autoRefreshTimer;
  final RxBool autoRefresh = false.obs;
  final RxInt refreshSeconds = 60.obs;

  Future<void> updateFilters({
    String? newModelSerial,
    DateTime? newDate,
    String? newShift,
    List<String>? newGroups,
    bool reload = true,
  }) async {
    if (newModelSerial != null && newModelSerial != modelSerial.value) {
      modelSerial.value = newModelSerial;
      await ensureModels(force: true, selectAll: true);
    }
    if (newDate != null && !_isSameDay(newDate, date.value)) {
      date.value = newDate;
    }
    if (newShift != null && newShift != shift.value) {
      shift.value = newShift;
      await ensureModels(force: true, selectAll: selectedGroups.isEmpty);
    }
    if (newGroups != null) {
      selectedGroups
        ..clear()
        ..addAll(newGroups);
    }

    if (reload) {
      await loadData();
    }
  }

  Future<void> ensureModels({bool force = false, bool selectAll = false}) async {
    if (!force && allGroups.isNotEmpty) {
      if (selectAll && selectedGroups.isEmpty) {
        selectedGroups
          ..clear()
          ..addAll(allGroups);
      }
      return;
    }

    isLoadingGroups.value = true;
    try {
      final List<String> list = await _getGroups(_currentRequest(groups: const <String>[]));
      if (list.isNotEmpty) {
        allGroups.assignAll(list);
        if (selectAll || selectedGroups.isEmpty) {
          selectedGroups
            ..clear()
            ..addAll(list);
        }
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingGroups.value = false;
    }
  }

  Future<void> loadData() async {
    final List<String> groups = selectedGroups.isEmpty
        ? allGroups.toList()
        : selectedGroups.toList();
    if (groups.isEmpty) {
      viewState.value = null;
      error.value = 'Vui lòng chọn ít nhất một model.';
      return;
    }

    isLoading.value = true;
    error.value = null;
    try {
      final request = _currentRequest(groups: groups);
      final UphTrackingEntity entity = await _getUphTracking(request);
      viewState.value = UphTrackingViewState.fromEntity(entity);
    } catch (e) {
      error.value = e.toString();
      viewState.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void toggleAutoRefresh(bool enabled) {
    autoRefresh.value = enabled;
    _autoRefreshTimer?.cancel();
    if (enabled) {
      _autoRefreshTimer = Timer.periodic(
        Duration(seconds: refreshSeconds.value),
        (_) => loadData(),
      );
    }
  }

  void updateRefreshInterval(int seconds) {
    refreshSeconds.value = seconds;
    if (autoRefresh.value) {
      toggleAutoRefresh(true);
    }
  }

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() async {
      await ensureModels(force: true, selectAll: true);
      await loadData();
    });
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  KanbanRequest _currentRequest({List<String>? groups}) {
    return KanbanRequest(
      modelSerial: modelSerial.value,
      date: _fmt(date.value),
      shift: shift.value,
      dateRange: 'string',
      groups: groups ?? selectedGroups.toList(),
    );
  }
}

String _fmt(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
