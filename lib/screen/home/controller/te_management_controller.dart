import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/te_management_api.dart';

class TEManagementController extends GetxController {
  TEManagementController({
    String initialModelSerial = 'SWITCH',
    String initialModel = '',
  })  : modelSerial = initialModelSerial.obs,
        model = initialModel.obs;

  final RxList<List<Map<String, dynamic>>> data = <List<Map<String, dynamic>>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  Future<void>? _activeFetch;

  late Rx<DateTime> startDate;
  late Rx<DateTime> endDate;
  final DateFormat _fmt = DateFormat('yyyy/MM/dd HH:mm');

  final RxString modelSerial;
  final RxString model;
  final RxString quickFilter = ''.obs;
  final RxBool filterPanelOpen = false.obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDate = Rx<DateTime>(DateTime(now.year, now.month, now.day, 7, 30));
    endDate = Rx<DateTime>(DateTime(now.year, now.month, now.day, 19, 30));
    fetchData();
  }

  String get range =>
      '${_fmt.format(startDate.value)} - ${_fmt.format(endDate.value)}';

  Future<void> fetchData({bool force = false}) async {
    final inFlight = _activeFetch;
    if (inFlight != null) {
      if (!force) {
        print('>> [TEManagement] Skip fetch - request already in-flight');
        return inFlight;
      }
      print('>> [TEManagement] Waiting for active fetch before forcing refresh');
      try {
        await inFlight;
      } catch (_) {}
    }

    final serial = modelSerial.value;
    final modelName = model.value;
    final requestRange = range;
    final stopwatch = Stopwatch()..start();
    print(
      '>> [TEManagement] Fetch start serial=$serial model="$modelName" range="$requestRange"',
    );

    Future<void> run() async {
      try {
        isLoading.value = true;
        error.value = '';
        final res = await TEManagementApi.fetchTableDetail(
          rangeDateTime: requestRange,
          modelSerial: serial,
          model: modelName,
        );
        data.value = res;
        stopwatch.stop();
        print(
          '>> [TEManagement] Fetch success serial=$serial model="$modelName" range="$requestRange" '
          'groups=${res.length} elapsed=${stopwatch.elapsedMilliseconds}ms',
        );
      } catch (e, stack) {
        stopwatch.stop();
        error.value = e.toString();
        print(
          '>> [TEManagement] Fetch error serial=$serial model="$modelName" range="$requestRange" err=$e',
        );
        print(stack);
      } finally {
        isLoading.value = false;
      }
    }

    final future = run();
    _activeFetch = future;
    try {
      await future;
    } finally {
      if (identical(_activeFetch, future)) {
        _activeFetch = null;
      }
    }
  }

  void updateQuickFilter(String v) => quickFilter.value = v;

  void openFilterPanel() => filterPanelOpen.value = true;
  void closeFilterPanel() => filterPanelOpen.value = false;

  void applyFilter(
    DateTime start,
    DateTime end,
    String serial,
    String modelName,
  ) {
    startDate.value = start;
    endDate.value = end;
    modelSerial.value = serial;
    model.value = modelName;
    fetchData(force: true);
    closeFilterPanel();
  }

  List<List<Map<String, dynamic>>> get filteredData {
    final q = quickFilter.value.trim().toLowerCase();
    if (q.isEmpty) return data;

    final List<List<Map<String, dynamic>>> result = [];
    for (final group in data) {
      if (group.isEmpty) continue;
      final modelName = (group.first['MODEL_NAME'] ?? '').toString();
      if (modelName.toLowerCase().contains(q)) {
        result.add(group);
        continue;
      }
      final filtered = group.where((row) {
        for (final v in row.values) {
          if (v.toString().toLowerCase().contains(q)) return true;
        }
        return false;
      }).toList();
      if (filtered.isNotEmpty) result.add(filtered);
    }
    return result;
  }
}
