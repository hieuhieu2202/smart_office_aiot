// 📁 yield_report_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/yield_rate_api.dart';

class YieldReportController extends GetxController {
  var dates = <String>[].obs;
  var dataNickNames = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var allNickNames = <String>[].obs;

  late Rx<DateTime> startDateTime;
  late Rx<DateTime> endDateTime;
  RxString selectedNickName = 'All'.obs;
  RxString quickFilter = ''.obs;
  RxString searchKey = ''.obs;

  RxBool filterPanelOpen = false.obs;
  Timer? _refreshTimer;

  final expandedNickNames = <String>{}.obs; // ✅ giữ danh sách Nick đang mở khi refresh

  final DateFormat _format = DateFormat('yyyy/MM/dd HH:mm');

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDateTime = Rx<DateTime>(DateTime(now.year, now.month, now.day - 7, 7, 30));
    endDateTime = Rx<DateTime>(DateTime(now.year, now.month, now.day, 19, 30));
    fetchReport();
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

  Future<void> fetchReport({String? nickName}) async {
    isLoading.value = true;
    try {
      final data = await YieldRateApi.getOutputReport(
        rangeDateTime: range,
        nickName: nickName ?? selectedNickName.value,
      );
      final res = data['Data'] ?? {};
      dates.value = List<String>.from(res['ClassDates'] ?? []);
      dataNickNames.value = List<Map<String, dynamic>>.from(res['DataNickNames'] ?? []);
      // capture all nick names when loading unfiltered data
      if ((nickName ?? selectedNickName.value) == 'All') {
        allNickNames.value = dataNickNames
            .map((e) => e['NickName'].toString())
            .toSet()
            .toList();
      }
      // ✅ không reset expandedNickNames
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
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
    selectedNickName.value = (nickName == null || nickName.isEmpty) ? 'All' : nickName;
    closeFilterPanel();
    fetchReport(nickName: selectedNickName.value);
  }

  void resetFilter() {
    final now = DateTime.now();
    startDateTime.value = DateTime(now.year, now.month, now.day - 2, 7, 30);
    endDateTime.value = DateTime(now.year, now.month, now.day, 19, 30);
    selectedNickName.value = 'All';
    closeFilterPanel();
    fetchReport();
  }

  List<Map<String, dynamic>> get filteredNickNames {
    final q = quickFilter.value.trim().toLowerCase();
    if (q.isEmpty) return dataNickNames;
    return dataNickNames.where((nick) {
      if ((nick['NickName'] ?? '').toString().toLowerCase().contains(q)) return true;
      final models = nick['DataModelNames'] as List? ?? [];
      for (final m in models) {
        if ((m['ModelName'] ?? '').toString().toLowerCase().contains(q)) return true;
        final stations = m['DataStations'] as List? ?? [];
        for (final st in stations) {
          if ((st['Station'] ?? '').toString().toLowerCase().contains(q)) return true;
        }
      }
      return false;
    }).toList();
  }

  List<String> get nickNameList => ['All', ...allNickNames];

  bool get isDefaultFilter =>
      selectedNickName.value == 'All' &&
          startDateTime.value.isBefore(DateTime.now().subtract(const Duration(days: 2))) &&
          endDateTime.value.isAfter(DateTime.now().subtract(const Duration(hours: 23)));
}
