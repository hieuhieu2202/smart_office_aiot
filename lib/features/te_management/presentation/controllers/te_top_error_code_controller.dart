import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/te_top_error.dart';
import '../../domain/usecases/get_top_error_codes.dart';
import '../../domain/usecases/get_top_error_trends.dart';

enum TETopErrorCategory { system, pcba }

extension TETopErrorCategoryLabel on TETopErrorCategory {
  String get label => switch (this) {
        TETopErrorCategory.system => 'System',
        TETopErrorCategory.pcba => 'PCBA',
      };
}

class TETopErrorCodeController extends GetxController {
  TETopErrorCodeController({
    required this.getTopErrorCodesUseCase,
    required this.getTopErrorTrendByErrorCodeUseCase,
    required this.getTopErrorTrendByModelStationUseCase,
    this.initialModelSerial = 'ADAPTER',
    this.initialCategory = TETopErrorCategory.system,
    this.refreshInterval = const Duration(minutes: 1),
  });

  final GetTopErrorCodesUseCase getTopErrorCodesUseCase;
  final GetTopErrorTrendByErrorCodeUseCase
      getTopErrorTrendByErrorCodeUseCase;
  final GetTopErrorTrendByModelStationUseCase
      getTopErrorTrendByModelStationUseCase;

  final String initialModelSerial;
  final TETopErrorCategory initialCategory;
  final Duration refreshInterval;

  final RxString modelSerial = ''.obs;
  final Rx<TETopErrorCategory> category =
      Rx<TETopErrorCategory>(TETopErrorCategory.system);
  final Rx<DateTime> startDateTime = Rx<DateTime>(_initialStart());
  final Rx<DateTime> endDateTime = Rx<DateTime>(_initialEnd());

  final RxBool isLoading = false.obs;
  final RxBool isTrendLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString trendErrorMessage = ''.obs;
  final RxList<TETopErrorEntity> errors = <TETopErrorEntity>[].obs;
  final Rxn<TETopErrorEntity> selectedError = Rxn<TETopErrorEntity>();
  final Rxn<TETopErrorDetailEntity> selectedDetail =
      Rxn<TETopErrorDetailEntity>();
  final RxList<TETopErrorTrendPointEntity> trendPoints =
      <TETopErrorTrendPointEntity>[].obs;
  final Rx<DateTime> lastUpdated = DateTime.now().obs;

  Timer? _timer;
  Future<void>? _running;
  final DateFormat _rangeFormatter = DateFormat('yyyy/MM/dd HH:mm');

  static DateTime _initialStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 7, 30);
  }

  static DateTime _initialEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 19, 30);
  }

  String get rangeLabel =>
      '${_rangeFormatter.format(startDateTime.value)} - ${_rangeFormatter.format(endDateTime.value)}';

  String get categoryLabel => category.value.label;

  String get apiType => category.value.label;

  bool get hasError => errorMessage.isNotEmpty;

  bool get hasTrendError => trendErrorMessage.isNotEmpty;

  bool get hasTrendData => trendPoints.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    modelSerial.value = initialModelSerial.trim().isEmpty
        ? 'ADAPTER'
        : initialModelSerial.trim().toUpperCase();
    category.value = initialCategory;
    _fetchInitial();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void updateModelSerial(String value) {
    final next = value.trim().isEmpty ? 'ADAPTER' : value.trim().toUpperCase();
    if (modelSerial.value == next) return;
    modelSerial.value = next;
    fetchTopErrors(showLoading: true);
  }

  void updateCategory(TETopErrorCategory value) {
    if (category.value == value) return;
    category.value = value;
    fetchTopErrors(showLoading: true);
  }

  Future<void> setStartDateTime(DateTime value) async {
    if (!value.isBefore(endDateTime.value)) {
      endDateTime.value = value.add(const Duration(hours: 1));
    }
    startDateTime.value = value;
    await fetchTopErrors(showLoading: true);
  }

  Future<void> setEndDateTime(DateTime value) async {
    if (!value.isAfter(startDateTime.value)) {
      startDateTime.value = value.subtract(const Duration(hours: 1));
    }
    endDateTime.value = value;
    await fetchTopErrors(showLoading: true);
  }

  Future<void> shiftToTodayRange() async {
    startDateTime.value = _initialStart();
    endDateTime.value = _initialEnd();
    await fetchTopErrors(showLoading: true);
  }

  Future<void> fetchTopErrors({required bool showLoading}) async {
    if (_running != null) {
      return _running;
    }

    Future<void> runner() async {
      try {
        if (showLoading) {
          isLoading.value = true;
        }
        errorMessage.value = '';
        final result = await getTopErrorCodesUseCase(
          modelSerial: modelSerial.value,
          range: rangeLabel,
          type: apiType,
        );
        errors.assignAll(result);
        lastUpdated.value = DateTime.now();
        _ensureSelection();
      } catch (error) {
        if (showLoading) {
          errors.clear();
        }
        errorMessage.value = error.toString();
      } finally {
        if (showLoading) {
          isLoading.value = false;
        }
      }
    }

    final future = runner();
    _running = future;
    await future;
    if (identical(_running, future)) {
      _running = null;
    }
  }

  Future<void> refresh() => fetchTopErrors(showLoading: true);

  Future<void> selectError(TETopErrorEntity? error) async {
    selectedError.value = error;
    if (error == null) {
      trendPoints.clear();
      selectedDetail.value = null;
      return;
    }

    final currentDetail = selectedDetail.value;
    if (currentDetail != null &&
        !error.details.any((detail) =>
            detail.modelName == currentDetail.modelName &&
            detail.groupName == currentDetail.groupName)) {
      selectedDetail.value = null;
    }
    await _loadTrend(detail: selectedDetail.value);
  }

  Future<void> selectDetail(TETopErrorDetailEntity? detail) async {
    selectedDetail.value = detail;
    await _loadTrend(detail: detail);
  }

  void clearDetailSelection() {
    if (selectedDetail.value == null) return;
    selectedDetail.value = null;
    _loadTrend(detail: null);
  }

  void _ensureSelection() {
    if (errors.isEmpty) {
      selectedError.value = null;
      selectedDetail.value = null;
      trendPoints.clear();
      return;
    }

    final current = selectedError.value;
    if (current != null) {
      final match = errors
          .firstWhereOrNull((item) => item.errorCode == current.errorCode);
      if (match != null) {
        selectedError.value = match;
        final detail = selectedDetail.value;
        if (detail != null) {
          final detailMatch = match.details.firstWhereOrNull((element) =>
              element.modelName == detail.modelName &&
              element.groupName == detail.groupName);
          if (detailMatch != null) {
            selectedDetail.value = detailMatch;
          } else {
            selectedDetail.value = null;
          }
        }
        _loadTrend(detail: selectedDetail.value);
        return;
      }
    }

    final fallback = errors.first;
    selectedError.value = fallback;
    selectedDetail.value = fallback.details.isNotEmpty
        ? fallback.details.first
        : null;
    _loadTrend(detail: selectedDetail.value);
  }

  Future<void> _fetchInitial() async {
    await fetchTopErrors(showLoading: true);
    _timer?.cancel();
    _timer = Timer.periodic(refreshInterval, (_) {
      fetchTopErrors(showLoading: false);
    });
  }

  Future<void> _loadTrend({TETopErrorDetailEntity? detail}) async {
    final error = selectedError.value;
    if (error == null) {
      trendPoints.clear();
      return;
    }

    try {
      isTrendLoading.value = true;
      trendErrorMessage.value = '';
      List<TETopErrorTrendPointEntity> points;
      if (detail != null) {
        points = await getTopErrorTrendByModelStationUseCase(
          range: rangeLabel,
          errorCode: error.errorCode,
          model: detail.modelName,
          station: detail.groupName,
        );
      } else {
        points = await getTopErrorTrendByErrorCodeUseCase(
          modelSerial: modelSerial.value,
          range: rangeLabel,
          errorCode: error.errorCode,
          type: apiType,
        );
      }
      trendPoints.assignAll(points);
    } catch (error) {
      trendPoints.clear();
      trendErrorMessage.value = error.toString();
    } finally {
      isTrendLoading.value = false;
    }
  }
}
