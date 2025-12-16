import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../../service/cdu_api.dart';
import '../widget/nvidia_lc_switch/Cdu_Monitoring/cdu_node.dart';

class CduController extends GetxController {
  CduController({required String factory, required String floor})
      : factory = factory.obs,
        floor = floor.obs;

  // ====== Params (reactive) ======
  final RxString factory;
  final RxString floor;

  // ====== States ======
  final isLoading = false.obs;
  final isLoadingHistory = false.obs;
  final error = RxnString();

  // Auto refresh
  final isAutoRefreshEnabled = true.obs;
  final refreshIntervalSec = 10.obs;
  Timer? _timer;

  // ====== Raw JSON ======
  final dashboard = Rxn<Map<String, dynamic>>();
  final history = Rxn<List<dynamic>>();

  // ====== Nodes for canvas ======
  final nodes = <CduNode>[].obs;

  // ====== History “êm” ======
  final historyItems = <Map<String, dynamic>>[].obs;
  final isFirstHistoryLoad = true.obs;
  final isRefreshingHistory = false.obs;
  Timer? _historyTimer;

  // ====== Lifecycle ======
  @override
  void onInit() {
    super.onInit();
    refreshAll();
    _startAutoRefresh();
    _historyTimer?.cancel();
    _historyTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchDetailHistory());
  }

  @override
  void onClose() {
    _stopAutoRefresh();
    _historyTimer?.cancel();
    super.onClose();
  }

  // ====== API calls ======
  Future<void> fetchDashboard() async {
    try {
      error.value = null;
      isLoading.value = true;

      if (kDebugMode) {
        print('[CDU] fetchDashboard: ${factory.value}, ${floor.value}');
      }

      final data = await CduApi.fetchDashboard(
        factory: factory.value,
        floor: floor.value,
      );

      dashboard.value = data;
      _buildNodesFromDashboard();
      _debugDump();
    } on TimeoutException {
      error.value = 'Hết thời gian chờ API';
    } on FormatException catch (e) {
      error.value = 'JSON không hợp lệ: $e';
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false; // (fix) không gán 2 lần
    }
  }

  Future<void> fetchDetailHistory() async {
    final first = historyItems.isEmpty;
    if (first) {
      isLoadingHistory.value = true;
      isFirstHistoryLoad.value = true;
    } else {
      isRefreshingHistory.value = true;
    }

    try {
      if (kDebugMode) {
        print('[CDU] fetchDetailHistory: ${factory.value}, ${floor.value}');
      }

      final data = await CduApi.fetchDetailHistory(
        factory: factory.value,
        floor: floor.value,
      );

      history.value = data; // nếu UI cũ còn xài raw

      // Data is now a direct array
      final list = (data as List? ?? const [])
          .whereType<Map>()
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      _mergeHistory(list);
    } on TimeoutException {
      error.value = 'Hết thời gian chờ API (history)';
    } on FormatException catch (e) {
      error.value = 'JSON (history) không hợp lệ: $e';
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingHistory.value = false;
      isFirstHistoryLoad.value = false;
      isRefreshingHistory.value = false;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchDashboard(),
      fetchDetailHistory(),
    ]);
  }

  void changeLocation({required String newFactory, required String newFloor}) {
    factory.value = newFactory;
    floor.value = newFloor;
    // reset state history “êm”
    historyItems.clear();
    isFirstHistoryLoad.value = true;
    refreshAll();
  }

  String get webUrl =>
      CduApi.webDashboardUrl(factory: factory.value, floor: floor.value);

  // ====== Computed ======
  Map<String, dynamic>? get root => dashboard.value;

  String? get layoutImage => root?['image'] as String?;

  Map<String, dynamic>? get summary => null; // New API doesn't have summary, compute from data

  List<Map<String, dynamic>> get rawDevices {
    // data field contains JSON string, need to parse it
    final dataStr = root?['data'];
    if (dataStr is String && dataStr.isNotEmpty) {
      try {
        final parsed = jsonDecode(dataStr);
        if (parsed is List) return parsed.cast<Map<String, dynamic>>();
      } catch (e) {
        if (kDebugMode) {
          print('[CDU] Error parsing data field: $e');
        }
      }
    }
    return const [];
  }

  int get totalCdu => nodes.length;
  
  int get runningCdu => nodes.where((n) => n.status == 'running').length;
  
  int get warningCdu => nodes.where((n) => n.status == 'warning').length;
  
  int get abnormalCdu => nodes.where((n) => n.status == 'abnormal').length;


  // ====== Build nodes for canvas ======
  void _buildNodesFromDashboard() {
    final List<CduNode> out = [];

    for (final item in rawDevices) {
      // New API structure: Top, Left, Width, Height are direct fields
      final x = _asNum(item['Left']) / 100.0;
      final y = _asNum(item['Top']) / 100.0;
      final w = _asNum(item['Width']) / 100.0;
      final h = _asNum(item['Height']) / 100.0;

      // Support both camelCase (new API) and PascalCase (old API)
      final cduName = (item['cduName'] ?? item['CDUName'] ?? '').toString();
      final hostName = (item['hostName'] ?? item['HostName'] ?? '').toString();
      final ipAddress = (item['ipAddress'] ?? item['IPAddress'] ?? '').toString();

      // For now, assume no real-time status data from layout API
      // Status will need to come from another source or default to 'no_connect'
      String status = 'no_connect';
      
      // Create basic detail map
      final detail = <String, dynamic>{
        'IPAddress': ipAddress,
        'CDUName': cduName,
        'HostName': hostName,
        'Status': 'NO DATA',
      };

      out.add(
        CduNode(
          id: cduName.isEmpty ? hostName : cduName,
          x: x.clamp(0.0, 1.0),
          y: y.clamp(0.0, 1.0),
          w: (w <= 0 ? 0.06 : w).clamp(0.02, 0.5),
          h: (h <= 0 ? 0.06 : h).clamp(0.02, 0.5),
          status: status,
          detail: detail,
        ),
      );
    }

    nodes.assignAll(out);
  }

  // ====== Helpers ======

  num _asNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  void _debugDump() {
    if (!kDebugMode) return;
    final top = dashboard.value;
    print('[CDU] keys top: ${top?.keys.toList()}');
    print('[CDU] Data keys: ${root?.keys.toList()}');
    print('[CDU] devices: ${rawDevices.length}');
    print('[CDU] summary keys: ${summary?.keys.toList()}');
    print('[CDU] summary: total=$totalCdu, running=$runningCdu, warn=$warningCdu, abnormal=$abnormalCdu');
  }

  // ====== Auto refresh (dashboard + history) ======
  void _startAutoRefresh() {
    _stopAutoRefresh();
    if (!isAutoRefreshEnabled.value) return;

    _timer = Timer.periodic(Duration(seconds: refreshIntervalSec.value), (_) {
      fetchDashboard();
      fetchDetailHistory();  // panel đã “êm”
    });

    if (kDebugMode) {
      print('[CDU] Auto refresh started: every ${refreshIntervalSec.value}s');
    }
  }

  void _stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
    if (kDebugMode) {
      print('[CDU] Auto refresh stopped');
    }
  }

  void toggleAutoRefresh([bool? enable]) {
    isAutoRefreshEnabled.value = enable ?? !isAutoRefreshEnabled.value;
    if (isAutoRefreshEnabled.value) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  void setRefreshInterval(int seconds) {
    refreshIntervalSec.value = seconds.clamp(5, 120);
    _startAutoRefresh();
  }

  // ====== Date helpers for history sort ======
  int _startMs(Map<String, dynamic> m) {
    // New API uses camelCase: startTime instead of StartTime
    final s = (m['startTime'] ?? m['StartTime'] ?? m['Starttime'] ?? m['Start'])?.toString() ?? '';
    final mm = RegExp(r'\/Date\((\d+)\)\/').firstMatch(s);
    if (mm != null) {
      final g = mm.group(1);
      final ms = g == null ? null : int.tryParse(g);
      if (ms != null) return ms;
    }
    return DateTime.tryParse(s)?.millisecondsSinceEpoch ?? 0;
  }

  int _startYmd(Map<String, dynamic> m) {
    final ms = _startMs(m);
    if (ms == 0) return 0;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return dt.year * 10000 + dt.month * 100 + dt.day; // ví dụ 20250911
  }

  int _cduOrder(Map<String, dynamic> m) {
    // New API uses camelCase: cduName instead of CDUName
    final id = (m['cduName'] ?? m['CDUName'] ?? m['Id'] ?? m['Name'] ?? '').toString();
    final mm = RegExp(r'(\d+)$').firstMatch(id);
    return mm != null ? int.tryParse(mm.group(1)!) ?? 0 : 0;
  }

  // ====== Merge history êm ======
  void _mergeHistory(List<Map<String, dynamic>> incoming) {
    String keyOf(Map<String, dynamic> m) {
      // New API uses camelCase: cduName instead of CDUName
      final id = (m['cduName'] ?? m['CDUName'] ?? m['Id'] ?? m['Name'] ?? 'Unknown').toString();
      return '$id@${_startMs(m)}';
    }

    final map = {for (final it in historyItems) keyOf(it): it};
    for (final it in incoming) {
      map[keyOf(it)] = it; // overwrite nếu có bản mới
    }

    final merged = map.values.toList()
      ..sort((a, b) {
        // Ngày DESC
        final dayCmp = _startYmd(b).compareTo(_startYmd(a));
        if (dayCmp != 0) return dayCmp;
        // Trong ngày: time ASC
        final timeCmp = _startMs(a).compareTo(_startMs(b));
        if (timeCmp != 0) return timeCmp;
        // Ổn định
        return _cduOrder(a).compareTo(_cduOrder(b));
      });

    historyItems.assignAll(merged);
  }
}
