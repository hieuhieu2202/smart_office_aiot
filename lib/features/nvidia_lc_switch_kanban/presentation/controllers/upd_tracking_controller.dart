import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/datasources/nvidia_kanban_remote_data_source.dart';
import '../../data/repositories/nvidia_kanban_repository_impl.dart';
import '../../domain/entities/kanban_entities.dart';
import '../../domain/usecases/get_groups_by_date_range.dart';
import '../../domain/usecases/get_upd_tracking.dart';
import '../viewmodels/upd_tracking_view_state.dart';

class UpdTrackingController extends GetxController {
  UpdTrackingController({
    GetGroupsByDateRange? getGroups,
    GetUpdTracking? getUpdTracking,
    NvidiaKanbanRepositoryImpl? repository,
    String initialModelSerial = 'SWITCH',
  }) : _repository = repository ??
            NvidiaKanbanRepositoryImpl(
              remoteDataSource: NvidiaKanbanRemoteDataSource(),
            ) {
    final repo = _repository;
    _getGroups = getGroups ?? GetGroupsByDateRange(repo);
    _getUpdTracking = getUpdTracking ?? GetUpdTracking(repo);

    final serial = initialModelSerial.trim().isEmpty
        ? 'SWITCH'
        : initialModelSerial.trim().toUpperCase();
    modelSerial.value = serial;
  }

  final NvidiaKanbanRepositoryImpl _repository;
  late final GetGroupsByDateRange _getGroups;
  late final GetUpdTracking _getUpdTracking;

  final RxString modelSerial = 'SWITCH'.obs;
  final Rx<DateTimeRange> range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  ).obs;
  final RxList<String> selectedGroups = <String>[].obs;
  final RxList<String> allGroups = <String>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingModels = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool hasLoadedOnce = false.obs;
  final RxnString error = RxnString();
  final Rxn<UpdTrackingViewState> viewState = Rxn<UpdTrackingViewState>();
  final Rx<DateTime?> lastUpdatedAt = Rx<DateTime?>(null);
  final RxBool showUpdateBadge = false.obs;

  final RxBool isAutoRefreshEnabled = true.obs;
  final RxInt refreshSeconds = 60.obs;
  Timer? _autoRefreshTimer;
  Timer? _updateBadgeTimer;

  Future<void> updateFilter({
    String? newModelSerial,
    DateTimeRange? newRange,
    List<String>? newGroups,
  }) async {
    var shouldReloadModels = false;

    if (newModelSerial != null && newModelSerial != modelSerial.value) {
      modelSerial.value = newModelSerial;
      shouldReloadModels = true;
      _log('Changed model serial -> $newModelSerial');
    }

    if (newRange != null && !_isSameRange(newRange, range.value)) {
      range.value = newRange;
      shouldReloadModels = true;
      _log('Changed range -> ${_formatRange(newRange)}');
    }

    if (newGroups != null) {
      selectedGroups
        ..clear()
        ..addAll(newGroups);
      _log('Selected groups -> ${selectedGroups.join(', ')}');
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
      final rangeText = _formatRange(range.value);
      _log('Fetching model groups for ${modelSerial.value} range $rangeText');
      final List<String> list =
          await _getGroups(_currentRequest(groups: const <String>[]));

      if (list.isNotEmpty) {
        allGroups.assignAll(list);
        if (selectAll || selectedGroups.isEmpty) {
          selectedGroups
            ..clear()
            ..addAll(list);
          _log('Auto-selected ${selectedGroups.length} groups');
        }
      }
    } catch (e) {
      error.value = e.toString();
      _log('Failed to fetch UPD groups -> $e');
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
      _log('Requesting UPD tracking | '
          'range=${request.dateRange} endDate=${request.date} '
          'groups=${groups.join(', ')}');
      final UpdTrackingEntity entity = await _getUpdTracking(request);
      final view = UpdTrackingViewState.fromEntity(entity);
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
      _log('Failed to load UPD tracking -> $e');
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
    final currentRange = range.value;
    return KanbanRequest(
      modelSerial: modelSerial.value,
      date: _formatDate(currentRange.end),
      shift: 'ALL',
      dateRange: _formatRange(currentRange),
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

  void _log(String message) {
    developer.log(message, name: 'UpdTrackingController');
  }
}

String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _formatRange(DateTimeRange range) =>
    '${_formatDate(range.start)} - ${_formatDate(range.end)}';

bool _isSameRange(DateTimeRange a, DateTimeRange b) {
  return _isSameDay(a.start, b.start) && _isSameDay(a.end, b.end);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
