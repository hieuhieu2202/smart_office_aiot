import 'package:get/get.dart';

import '../../../model/smt/stencil_detail.dart';
import '../../../service/stencil_monitor_api.dart';

class StencilMonitorController extends GetxController {
  StencilMonitorController();

  final RxList<StencilDetail> stencilData = <StencilDetail>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  final RxString selectedCustomer = 'ALL'.obs;
  final RxString selectedFloor = 'ALL'.obs;

  final RxList<String> customers = <String>[].obs;
  final RxList<String> floors = <String>[].obs;

  Future<void>? _activeFetch;

  @override
  void onInit() {
    super.onInit();
    customers.assignAll(['ALL']);
    floors.assignAll(['ALL']);
    fetchData();
  }

  Future<void> fetchData({bool force = false}) async {
    final inFlight = _activeFetch;
    if (inFlight != null) {
      if (!force) {
        print('>> [StencilMonitor] Skip fetch - already in flight');
        return inFlight;
      }
      print('>> [StencilMonitor] Waiting for active fetch before forcing refresh');
      try {
        await inFlight;
      } catch (_) {}
    }

    Future<void> runner() async {
      try {
        isLoading.value = true;
        error.value = '';
        final results = await StencilMonitorApi.fetchStencilDetails();
        stencilData.assignAll(results);
        _rebuildCustomers();
        _rebuildFloors();
        print('>> [StencilMonitor] Loaded ${results.length} rows');
      } catch (e, stack) {
        error.value = e.toString();
        print('>> [StencilMonitor] Fetch error: $e');
        print(stack);
      } finally {
        isLoading.value = false;
      }
    }

    final future = runner();
    _activeFetch = future;
    try {
      await future;
    } finally {
      if (identical(_activeFetch, future)) {
        _activeFetch = null;
      }
    }
  }

  void selectCustomer(String value) {
    if (selectedCustomer.value == value) return;
    selectedCustomer.value = value;
    _rebuildFloors();
  }

  void selectFloor(String value) {
    selectedFloor.value = value;
  }

  Future<void> refresh() => fetchData(force: true);

  List<StencilDetail> get filteredData {
    final customerFilter = selectedCustomer.value;
    final floorFilter = selectedFloor.value;
    return stencilData.where((item) {
      final customerLabel = item.customerLabel;
      final floorLabel = item.floorLabel;
      final matchCustomer =
          customerFilter == 'ALL' || customerLabel == customerFilter;
      final matchFloor = floorFilter == 'ALL' || floorLabel == floorFilter;
      return matchCustomer && matchFloor;
    }).toList(growable: false);
  }

  Map<String, int> statusBreakdown(List<StencilDetail> source) {
    final map = <String, int>{};
    for (final item in source) {
      final key = item.statusLabel;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> vendorBreakdown(List<StencilDetail> source) {
    final map = <String, int>{};
    for (final item in source) {
      final vendor = _normalizeLabel(item.vendorName);
      map[vendor] = (map[vendor] ?? 0) + 1;
    }
    return map;
  }

  void _rebuildCustomers() {
    final set = <String>{};
    for (final item in stencilData) {
      set.add(item.customerLabel);
    }
    final sorted = set.toList()..sort();
    customers.assignAll(['ALL', ...sorted]);
    if (!customers.contains(selectedCustomer.value)) {
      selectedCustomer.value = 'ALL';
    }
  }

  void _rebuildFloors() {
    final set = <String>{};
    final customerFilter = selectedCustomer.value;
    for (final item in stencilData) {
      if (customerFilter != 'ALL' && item.customerLabel != customerFilter) {
        continue;
      }
      set.add(item.floorLabel);
    }
    final sorted = set.toList()..sort();
    floors.assignAll(['ALL', ...sorted]);
    if (!floors.contains(selectedFloor.value)) {
      selectedFloor.value = 'ALL';
    }
  }

  String _normalizeLabel(String? value) {
    final raw = value?.trim() ?? '';
    return raw.isEmpty ? 'UNK' : raw;
  }
}
