import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/yield_rate_api.dart';

String _normalizeNickName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'ALL';
  return trimmed.toUpperCase() == 'ALL' ? 'ALL' : trimmed;
}

List<String> _sanitizeNickList(Iterable<dynamic> rawList) {
  final result = <String>{};
  for (final item in rawList) {
    final name = (item ?? '').toString().trim();
    if (name.isEmpty) continue;
    if (name.toUpperCase() == 'ALL') continue;
    result.add(name);
  }
  return result.toList();
}

class YieldReportController extends GetxController {
  YieldReportController({
    required String reportType,
    String initialNickName = 'ALL',
  })  : _reportType =
            reportType.trim().isEmpty ? 'SWITCH' : reportType.trim().toUpperCase(),
        _initialNickName = _normalizeNickName(initialNickName),
        selectedNickName = _normalizeNickName(initialNickName).obs {
    if (_initialNickName != 'ALL') {
      allNickNames.add(_initialNickName);
    }
  }

  final String _reportType;
  final String _initialNickName;

  var dates = <String>[].obs;
  var dataNickNames = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  final RxList<String> allNickNames = <String>[].obs;

  late Rx<DateTime> startDateTime;
  late Rx<DateTime> endDateTime;
  final RxString selectedNickName;
  RxString quickFilter = ''.obs;
  RxString searchKey = ''.obs;

  RxBool filterPanelOpen = false.obs;
  Timer? _refreshTimer;
  Future<void>? _activeFetch;

  final expandedNickNames =
      <String>{}.obs; // ✅ giữ danh sách Nick đang mở khi refresh

  final DateFormat _format = DateFormat('yyyy/MM/dd HH:mm');

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDateTime = Rx<DateTime>(
      DateTime(now.year, now.month, now.day - 2, 7, 30),
    );
    endDateTime = Rx<DateTime>(DateTime(now.year, now.month, now.day, 19, 30));
    fetchReport(nickName: selectedNickName.value);
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      fetchReport(); // ✅ chỉ cập nhật dữ liệu, không reset bảng
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  String get range =>
      '${_format.format(startDateTime.value)} - ${_format.format(endDateTime.value)}';

  Future<void> fetchReport({String? nickName, bool force = false}) async {
    final inFlight = _activeFetch;
    if (inFlight != null) {
      if (!force) {
        print('>> [YieldReport] Skip fetch - request already in-flight');
        return inFlight;
      }
      print('>> [YieldReport] Waiting for active fetch before forcing refresh');
      try {
        await inFlight;
      } catch (_) {}
    }

    Future<void> run() async {
      isLoading.value = true;
      final currentNick = _normalizeNickName(nickName ?? selectedNickName.value);
      final apiNick = currentNick == 'ALL' ? 'All' : currentNick;
      final requestRange = range;
      final stopwatch = Stopwatch()..start();
      print(
        '>> [YieldReport] Fetch start type=$_reportType nick=$currentNick range="$requestRange"',
      );
      try {
        final data = await YieldRateApi.getOutputReport(
          rangeDateTime: requestRange,
          type: _reportType,
          nickName: apiNick,
        );
        stopwatch.stop();
        final res = data['Data'] ?? {};
        dates.value = List<String>.from(res['ClassDates'] ?? []);
        dataNickNames.value = List<Map<String, dynamic>>.from(
          res['DataNickNames'] ?? [],
        );
        // capture all nick names when loading unfiltered data
        if (currentNick == 'ALL') {
          allNickNames.value = _sanitizeNickList(
            dataNickNames.map((e) => e['NickName']),
          );
        } else {
          final names = <String>{...allNickNames, if (currentNick != 'ALL') currentNick};
          for (final item in dataNickNames) {
            final name = (item['NickName'] ?? '').toString();
            if (name.isNotEmpty && name.toUpperCase() != 'ALL') {
              names.add(name);
            }
          }
          allNickNames.value = names.toList();
        }
        // ✅ không reset expandedNickNames
        print(
          '>> [YieldReport] Fetch success type=$_reportType nick=$currentNick range="$requestRange" '
          'dates=${dates.length} nickCount=${dataNickNames.length} '
          'elapsed=${stopwatch.elapsedMilliseconds}ms',
        );
      } catch (e, stack) {
        stopwatch.stop();
        print(
          '>> [YieldReport] Fetch error type=$_reportType nick=$currentNick range="$requestRange" err=$e',
        );
        print(stack);
        Get.snackbar('Error', e.toString());
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

  void updateStart(DateTime dt) => startDateTime.value = dt;

  void updateEnd(DateTime dt) => endDateTime.value = dt;

  void updateQuickFilter(String v) => quickFilter.value = v;

  void openFilterPanel() => filterPanelOpen.value = true;

  void closeFilterPanel() => filterPanelOpen.value = false;

  void applyFilter(DateTime start, DateTime end, String? nickName) {
    startDateTime.value = start;
    endDateTime.value = end;
    selectedNickName.value =
        (nickName == null || nickName.isEmpty) ? 'ALL' : _normalizeNickName(nickName);
    closeFilterPanel();
    fetchReport(nickName: selectedNickName.value, force: true);
  }

  void resetFilter() {
    final now = DateTime.now();
    startDateTime.value = DateTime(now.year, now.month, now.day - 2, 7, 30);
    endDateTime.value = DateTime(now.year, now.month, now.day, 19, 30);
    selectedNickName.value = 'ALL';
    closeFilterPanel();
    fetchReport(force: true);
  }

  List<Map<String, dynamic>> get filteredNickNames {
    final q = quickFilter.value.trim().toLowerCase();
    if (q.isEmpty) return dataNickNames;

    final List<Map<String, dynamic>> result = [];

    for (final nick in dataNickNames) {
      final nickName = (nick['NickName'] ?? '').toString();
      final models = List<Map<String, dynamic>>.from(
        nick['DataModelNames'] ?? [],
      );

      if (nickName.toLowerCase().contains(q)) {
        result.add(nick);
        continue;
      }

      final filteredModels = <Map<String, dynamic>>[];

      for (final m in models) {
        final modelName = (m['ModelName'] ?? '').toString();
        final stations = List<Map<String, dynamic>>.from(
          m['DataStations'] ?? [],
        );

        if (modelName.toLowerCase().contains(q)) {
          filteredModels.add(m);
          continue;
        }

        final filteredStations =
            stations.where((st) {
              final stationName = (st['Station'] ?? '').toString();
              if (stationName.toLowerCase().contains(q)) return true;
              final data = st['Data'] as List? ?? [];
              for (final v in data) {
                if (v.toString().toLowerCase().contains(q)) return true;
              }
              return false;
            }).toList();

        if (filteredStations.isNotEmpty) {
          final newModel = Map<String, dynamic>.from(m);
          newModel['DataStations'] = filteredStations;
          filteredModels.add(newModel);
        }
      }

      if (filteredModels.isNotEmpty) {
        final newNick = Map<String, dynamic>.from(nick);
        newNick['DataModelNames'] = filteredModels;
        result.add(newNick);
      }
    }

    return result;
  }

  List<String> get nickNameList => ['ALL', ...allNickNames];

  bool get isDefaultFilter =>
      selectedNickName.value == 'ALL' &&
      startDateTime.value.isBefore(
        DateTime.now().subtract(const Duration(days: 2)),
      ) &&
      endDateTime.value.isAfter(
        DateTime.now().subtract(const Duration(hours: 23)),
      );
}
