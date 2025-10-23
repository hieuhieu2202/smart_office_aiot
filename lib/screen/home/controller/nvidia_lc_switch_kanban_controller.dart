import 'dart:async';

import 'package:get/get.dart';

import '../../../service/lc_switch_kanban_api.dart';
import '../widget/nvidia_lc_switch_kanban/Output_Tracking/output_tracking_view_state.dart';

class KanbanController extends GetxController {
  // ====== Filter state ======
  final modelSerial = 'SWITCH'.obs;
  final date = DateTime.now().obs;
  final shift = 'Day'.obs;

  /// CHÚ Ý: theo API OutputTracking, `groups` là DANH SÁCH MODEL được chọn
  final groups = <String>['699-1T363-0100-000'].obs;

  // Optional (gửi lên API nếu cần)
  final dateRange = 'string'.obs;
  final section = 'string'.obs;
  final station = 'string'.obs;
  final line = 'string'.obs;
  final customer = 'string'.obs;
  final nickName = 'string'.obs;
  final modelName = 'string'.obs;

  // Loading & error
  final isLoading = false.obs;
  final error = RxnString();

  // Payloads
  final outputTracking = Rxn<KanbanOutputTracking>();
  final uphTracking    = Rxn<KanbanUphTracking>();
  final outputTrackingView = Rxn<OtViewState>();

  // Danh sách model cho picker (SFIS/GetGroupsByShift)
  final allModels = <String>[].obs;
  final isLoadingModels = false.obs;

  // Map STATION -> MODEL (dùng trực tiếp hiển thị cột "MODEL NAME")
  final RxMap<String, String> _modelByStation = <String, String>{}.obs;

  // Auto refresh
  final isAutoRefreshEnabled = true.obs;
  final refreshSec = 60.obs;
  Timer? _timer;

  // ---------------- Public API ----------------
  Future<void> updateFilter({
    String? newModelSerial,
    DateTime? newDate,
    String? newShift,
    List<String>? newGroups, // DANH SÁCH MODEL
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
    if (newSection   != null) section.value   = newSection;
    if (newStation   != null) station.value   = newStation;
    if (newLine      != null) line.value      = newLine;
    if (newCustomer  != null) customer.value  = newCustomer;
    if (newNickName  != null) nickName.value  = newNickName;
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
      final body = KanbanApi.buildBody(
        modelSerial: modelSerial.value,
        date: _fmt(date.value),              // yyyy-MM-dd
        shift: shift.value,
        dateRange: dateRange.value,
        groups: groups.toList(),             // DANH SÁCH MODEL
        section: section.value,
        station: station.value,
        line: line.value,
        customer: customer.value,
        nickName: nickName.value,
        modelName: modelName.value,
      );

      KanbanApiLog.net(() => '[KanbanController] loadAll body=$body');

      final results = await Future.wait([
        KanbanApi.getOutputTrackingData(body: body),
        KanbanApi.getUphTrackingData(body: body),
      ]);

      outputTracking.value = results[0] as KanbanOutputTracking;
      uphTracking.value    = results[1] as KanbanUphTracking;

      // Xây map STATION -> MODEL từ response hiện tại (có fan-out khi cần)
      await _rebuildModelByStation();

      // Cập nhật danh sách model nếu cần
      _mergeModelsFromResponses();

      _rebuildOutputTrackingView();
    } catch (e) {
      error.value = e.toString();
      KanbanApiLog.net(() => '[KanbanController] loadAll ERROR: $e');
      outputTrackingView.value = null;
    } finally {
      isLoading.value = false;
      if (isAutoRefreshEnabled.value) {
        startAutoRefresh();
      }
    }
  }

  /// Nạp danh sách MODEL từ SFIS/GetGroupsByShift
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
      final list = await KanbanApi.getGroupsByShift(
        modelSerial: modelSerial.value,
        dateYmd: _fmt(date.value), // service có thể tự convert sang yyyymmdd
        shift: shift.value,
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
      KanbanApiLog.net(() => '[KanbanController] ensureModels count=${allModels.length}');
    } catch (e) {
      KanbanApiLog.net(() => '[KanbanController] ensureModels ERROR: $e');
      if (allModels.isEmpty) _mergeModelsFromResponses();
      if (selectAll && allModels.isNotEmpty) {
        groups
          ..clear()
          ..addAll(allModels);
      }
    } finally {
      isLoadingModels.value = false;
    }
  }

  Future<KanbanOutputTrackingDetail> fetchOutputTrackingDetail({
    required String station,
    required String section,
  }) async {
    final responseModels = outputTracking.value?.model ?? const <String>[];
    final normalizedResponseModels = responseModels
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final fallbackSelection = groups.isNotEmpty
        ? groups.toList()
        : allModels.toList();
    final groupList = normalizedResponseModels.isNotEmpty
        ? normalizedResponseModels
        : fallbackSelection
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (groupList.isEmpty) {
      throw Exception('Không có model nào được chọn.');
    }

    final normalizedSection = _normalizeSectionParam(section);

    return KanbanApi.getOutputTrackingDataDetail(
      modelSerial: modelSerial.value,
      date: _fmt(date.value),
      shift: shift.value,
      groups: groupList,
      station: station,
      section: normalizedSection,
    );
  }

  void _mergeModelsFromResponses() {
    final set = <String>{...allModels};
    final o = outputTracking.value;
    final u = uphTracking.value;
    if (o != null) set.addAll(o.model);
    if (u != null) set.addAll(u.model);
    if (set.isNotEmpty) {
      final merged = set.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      allModels.assignAll(merged);
    }
  }

  void _rebuildOutputTrackingView() {
    final out = outputTracking.value;
    if (out == null) {
      outputTrackingView.value = null;
      return;
    }

    final fallback = out.model
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (fallback.isEmpty) {
      fallback.addAll(groups.map((e) => e.trim()).where((e) => e.isNotEmpty));
    }

    outputTrackingView.value = OtViewState.fromResponse(
      hours: hours,
      groups: out.data,
      modelByStation: modelNameByGroup,
      fallbackModels: fallback,
    );
  }

  // ====== Build STATION -> MODEL map dựa đúng OutputTracking ======
  Future<void> _rebuildModelByStation() async {
    _modelByStation.clear();

    final out = outputTracking.value;
    if (out == null) return;

    final stations = <String>[
      for (final g in out.data) g.groupName.trim(),
    ];

    // 1) Nếu server trả đúng 1 model cho tất cả station
    if (out.model.length == 1 && out.model.first.trim().isNotEmpty) {
      final model = out.model.first.trim();
      for (final st in stations) {
        _modelByStation[st] = model;
      }
      _debugModelMapLog();
      return;
    }

    // 2) Nếu số model == số dòng data -> ghép theo index
    if (out.model.isNotEmpty && out.model.length == out.data.length) {
      for (int i = 0; i < out.data.length; i++) {
        final st = out.data[i].groupName.trim();
        final md = out.model[i].trim();
        if (st.isNotEmpty) _modelByStation[st] = md.isEmpty ? '-' : md;
      }
      _debugModelMapLog();
      return;
    }

    // 3) Nhiều model được chọn, response không nêu rõ từng dòng -> fan-out từng model
    await _rebuildModelByStationFanout(stations);
    _debugModelMapLog();
  }

  /// Fanout: gọi API OutputTracking cho từng model trong `groups`
  Future<void> _rebuildModelByStationFanout(List<String> allStations) async {
    if (groups.isEmpty) {
      for (final st in allStations) {
        _modelByStation[st] = '-';
      }
      return;
    }

    try {
      // Gọi tuần tự để tránh nghẽn/gây 400 “No data.” hàng loạt (có thể chuyển sang song song nếu server chịu tải tốt)
      for (final m in groups) {
        final ot = await _fetchOtForModelSafe(m);
        if (ot == null) {
          continue; // không có data → bỏ qua
        }
        for (final row in ot.data) {
          final st = row.groupName.trim();
          if (st.isEmpty) continue;
          if (allStations.contains(st)) {
            _modelByStation[st] = m.trim().isEmpty ? '-' : m.trim();
          }
        }
      }

      // Điền '-' cho station còn thiếu
      for (final st in allStations) {
        _modelByStation.putIfAbsent(st, () => '-');
      }
    } catch (e) {
      // Nếu fanout lỗi chung → vẫn đảm bảo có key với '-'
      for (final st in allStations) {
        _modelByStation.putIfAbsent(st, () => '-');
      }
      KanbanApiLog.net(() => '[KanbanController] fan-out modelByStation ERROR: $e');
    }
  }

  /// Gọi API OutputTracking cho duy nhất 1 model
  Future<KanbanOutputTracking> _fetchOtForModel(String model) async {
    final body = KanbanApi.buildBody(
      modelSerial: modelSerial.value,
      date: _fmt(date.value),
      shift: shift.value,
      dateRange: dateRange.value,
      groups: [model],                 // KEY: gọi riêng theo từng model
      section: section.value,
      station: station.value,
      line: line.value,
      customer: customer.value,
      nickName: nickName.value,
      modelName: modelName.value,
    );
    KanbanApiLog.net(() => '[KanbanController] FANOUT body=$body');
    return await KanbanApi.getOutputTrackingData(body: body);
  }

  /// Bọc an toàn: nếu API trả 400 "No data." → trả null, KHÔNG tạo object rỗng
  Future<KanbanOutputTracking?> _fetchOtForModelSafe(String model) async {
    try {
      return await _fetchOtForModel(model);
    } catch (e) {
      KanbanApiLog.net(() => '[KanbanController] fanout "$model" => NO DATA (${e.toString()})');
      return null;
    }
  }

  void _debugModelMapLog() {
    final n = _modelByStation.length;
    final sample = _modelByStation.entries.take(5).map((e) => '${e.key} -> ${e.value}').join(' | ');
    KanbanApiLog.net(() => '[KanbanController] modelByStation size=$n; sample: $sample');
  }

  void setNetworkLog(bool on) => KanbanApiLog.network = on;

  void startAutoRefresh() {
    _timer?.cancel();
    if (!isAutoRefreshEnabled.value) return;
    _timer = Timer.periodic(
      Duration(seconds: refreshSec.value),
          (_) async {
        await loadAll();
      },
    );
  }

  void stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  // ====== Helpers ======
  int _sumInt(List<double>? list) {
    final src = list ?? const <double>[];
    return src.fold<int>(0, (s, v) => s + v.round());
  }

  // ====== Derived getters ======
  List<String> get hours {
    final out = outputTracking.value;
    if (out != null && out.section.isNotEmpty) return out.section;
    final uph = uphTracking.value;
    return uph?.section ?? const <String>[];
  }

  Map<String, List<double>> get passSeriesByGroup =>
      {for (final g in (outputTracking.value?.data ?? const [])) g.groupName: g.pass};

  Map<String, List<double>> get yrSeriesByGroup =>
      {for (final g in (outputTracking.value?.data ?? const [])) g.groupName: g.yr};

  Map<String, List<double>> get rrSeriesByGroup =>
      {for (final g in (outputTracking.value?.data ?? const [])) g.groupName: g.rr};

  Map<String, int> get wipByGroup =>
      {for (final g in (outputTracking.value?.data ?? const [])) g.groupName: g.wip};

  Map<String, int> get totalPassByGroup =>
      {for (final g in (outputTracking.value?.data ?? const [])) g.groupName: _sumInt(g.pass)};

  Map<String, int> get totalFailByGroup =>
      {for (final g in (outputTracking.value?.data ?? const [])) g.groupName: _sumInt(g.fail)};

  int get totalPass => (outputTracking.value?.data ?? const [])
      .fold<int>(0, (sum, g) => sum + _sumInt(g.pass));

  int get totalFail => (outputTracking.value?.data ?? const [])
      .fold<int>(0, (sum, g) => sum + _sumInt(g.fail));

  double get avgYr {
    final l = (outputTracking.value?.data ?? const []).expand((g) => g.yr).toList();
    if (l.isEmpty) return 0;
    final total = l.fold<double>(0.0, (s, v) => s + v);
    return total / l.length;
  }

  String _normalizeSectionParam(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return trimmed;

    final parsed = int.tryParse(digitsOnly);
    if (parsed == null) return trimmed;
    if (parsed == 24) return '24';

    final bounded = parsed % 100;
    return bounded.toString().padLeft(2, '0');
  }

  double get avgRr {
    final l = (outputTracking.value?.data ?? const []).expand((g) => g.rr).toList();
    if (l.isEmpty) return 0;
    final total = l.fold<double>(0.0, (s, v) => s + v);
    return total / l.length;
  }

  int get totalWip =>
      (outputTracking.value?.data ?? const []).fold<int>(0, (s, g) => s + g.wip);

  /// Getter cho UI: STATION -> MODEL (ưu tiên map đã ghép chính xác)
  Map<String, String> get modelNameByGroup {
    if (_modelByStation.isNotEmpty) {
      return Map<String, String>.from(_modelByStation);
    }

    // Fallback tối thiểu (không nên rơi vào)
    final out = outputTracking.value;
    if (out == null) return const <String, String>{};
    final map = <String, String>{};

    if (out.model.length == 1) {
      final m = out.model.first.trim();
      for (final row in out.data) {
        map[row.groupName] = m.isEmpty ? '-' : m;
      }
    } else {
      final len = out.data.length < out.model.length ? out.data.length : out.model.length;
      for (int i = 0; i < len; i++) {
        map[out.data[i].groupName] = out.model[i].trim().isEmpty ? '-' : out.model[i].trim();
      }
      for (final row in out.data.skip(len)) {
        map.putIfAbsent(row.groupName, () => '-');
      }
    }
    return map;
  }

  // ====== Lifecycle ======
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
}

String _fmt(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
