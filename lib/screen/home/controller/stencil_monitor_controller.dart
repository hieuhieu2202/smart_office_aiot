import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../model/smt/stencil_detail.dart';
import '../../../service/stencil_monitor_api.dart';

class StencilMonitorController extends GetxController {
  StencilMonitorController();

  static const String networkErrorMessage =
      'Connection issue detected. Please check your network connection and tap Reload to try again.';

  final RxList<StencilDetail> stencilData = <StencilDetail>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<DateTime?> lastUpdated = Rx<DateTime?>(null);

  final RxString selectedCustomer = 'ALL'.obs;
  final RxString selectedFloor = 'F06'.obs;

  final RxList<String> customers = <String>[].obs;
  final RxList<String> floors = <String>[].obs;

  Future<void>? _activeFetch;
  static const Set<String> ignoredCustomers = {'CPEII'};

  @override
  void onInit() {
    super.onInit();
    customers.assignAll(['ALL']);
    floors.assignAll(['ALL', 'F06']);
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
        lastUpdated.value = DateTime.now();
        _rebuildCustomers();
        _rebuildFloors();
        print('>> [StencilMonitor] Loaded ${results.length} rows');
      } catch (e, stack) {
        error.value = _describeError(e);
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
      final customer = item.customer.trim().toUpperCase();
      if (ignoredCustomers.contains(customer)) {
        continue;
      }
      final status = item.statusLabel;
      if (status.toUpperCase() == 'TOOLROOM') {
        continue;
      }
      map[status] = (map[status] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> vendorBreakdown(List<StencilDetail> source) {
    final map = <String, int>{};
    for (final item in source) {
      final customer = item.customer.trim().toUpperCase();
      if (ignoredCustomers.contains(customer)) {
        continue;
      }
      final vendor = _normalizeLabel(item.vendorName);
      map[vendor] = (map[vendor] ?? 0) + 1;
    }
    return map;
  }

  void _rebuildCustomers() {
    final set = <String>{};
    for (final item in stencilData) {
      final label = item.customerLabel;
      set.add(label);
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
      final label = item.customerLabel;
      if (customerFilter != 'ALL' && label != customerFilter) {
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
    return raw.isEmpty ? 'UNKNOWN' : raw;
  }

  String _describeError(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error is HandshakeException ||
        error is TlsException) {
      return networkErrorMessage;
    }

    final message = error.toString();
    if (message.contains('Connection closed while receiving data') ||
        message.contains('Failed host lookup') ||
        message.contains('Network is unreachable') ||
        message.contains('Software caused connection abort')) {
      return networkErrorMessage;
    }

    return message;
  }
}

