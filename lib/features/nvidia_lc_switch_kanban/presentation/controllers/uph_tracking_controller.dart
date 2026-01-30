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
  final RxBool isLoadingModels = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool hasLoadedOnce = false.obs;
  final RxnString error = RxnString();
  final Rxn<UphTrackingViewState> viewState = Rxn<UphTrackingViewState>();
  final Rx<DateTime?> lastUpdatedAt = Rx<DateTime?>(null);
  final RxBool showUpdateBadge = false.obs;

  final RxBool isAutoRefreshEnabled = true.obs;
  final RxInt refreshSeconds = 60.obs;
  Timer? _autoRefreshTimer;
  Timer? _updateBadgeTimer;

  Future<void> updateFilter({
    String? newModelSerial,
    DateTime? newDate,
    String? newShift,
    List<String>? newGroups,
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
      selectedGroups
        ..clear()
        ..addAll(newGroups);
    }

    if (shouldReloadModels) {
      await ensureModels(force: true, selectAll: selectedGroups.isEmpty);
    }

    await loadAll();
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

    isLoadingModels.value = true;
    try {
      final List<String> list =
          await _getGroups(_currentRequest(groups: const <String>[]));

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
      isLoadingModels.value = false;
    }
  }

  Future<void> loadAll() async {
    final List<String> groups = selectedGroups.isEmpty
        ? allGroups.toList()
        : selectedGroups.toList();
    if (groups.isEmpty) {
      viewState.value = null;
      error.value = 'Vui lòng chọn ít nhất một model.';
      return;
    }

    final bool hadView = viewState.value != null;
    isLoading.value = true;
    isRefreshing.value = hadView;
    error.value = null;
    if (!hadView) {
      viewState.value = null;
    } else {
      _updateBadgeTimer?.cancel();
      showUpdateBadge.value = false;
    }

    try {
      final request = _currentRequest(groups: groups);
      final UphTrackingEntity entity = await _getUphTracking(request);
      final view = UphTrackingViewState.fromEntity(entity);
      viewState.value = view;

      if (view.hasData) {
        _markUpdated(highlight: hadView);
      }
    } catch (e) {
      error.value = e.toString();
      if (!hadView) {
        viewState.value = null;
      }
      _updateBadgeTimer?.cancel();
      showUpdateBadge.value = false;
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      hasLoadedOnce.value = true;

      if (isAutoRefreshEnabled.value) {
        startAutoRefresh();
      }
    }
  }

  void startAutoRefresh() {
    if (!isAutoRefreshEnabled.value) return;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: refreshSeconds.value),
      (_) => loadAll(),
    );
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void toggleAutoRefresh(bool enabled) {
    isAutoRefreshEnabled.value = enabled;
    if (enabled) {
      startAutoRefresh();
    } else {
      stopAutoRefresh();
    }
  }

  void updateRefreshInterval(int seconds) {
    refreshSeconds.value = seconds.clamp(15, 600);
    if (isAutoRefreshEnabled.value) {
      startAutoRefresh();
    }
  }

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() async {
      await ensureModels(force: true, selectAll: true);
      await loadAll();
    });
  }

  @override
  void onClose() {
    stopAutoRefresh();
    _updateBadgeTimer?.cancel();
    super.onClose();
  }

  KanbanRequest _currentRequest({List<String>? groups}) {
    return KanbanRequest(
      modelSerial: modelSerial.value,
      date: _formatDate(date.value),
      shift: shift.value,
      dateRange: 'string',
      groups: groups ?? selectedGroups.toList(),
    );
  }

  void _markUpdated({required bool highlight}) {
    final now = DateTime.now();
    lastUpdatedAt.value = now;
    if (!highlight) {
      showUpdateBadge.value = false;
      return;
    }

    showUpdateBadge.value = true;
    _updateBadgeTimer?.cancel();
    _updateBadgeTimer = Timer(const Duration(seconds: 6), () {
      showUpdateBadge.value = false;
    });
  }
}

String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
