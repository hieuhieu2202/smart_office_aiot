import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/datasources/station_overview_remote_data_source.dart';
import '../../data/repositories/station_overview_repository_impl.dart';
import '../../domain/entities/station_overview_entities.dart';
import '../../domain/usecases/get_station_analysis.dart';
import '../../domain/usecases/get_station_details.dart';
import '../../domain/usecases/get_station_overview.dart';
import '../../domain/usecases/get_station_products.dart';
import '../viewmodels/station_overview_view_state.dart';

class StationOverviewController extends GetxController {
  StationOverviewController({
    StationOverviewRepositoryImpl? repository,
    GetStationProducts? getStationProducts,
    GetStationOverview? getStationOverview,
    GetStationAnalysis? getStationAnalysis,
    GetStationDetails? getStationDetails,
  }) : _repository =
            repository ?? StationOverviewRepositoryImpl(remoteDataSource: StationOverviewRemoteDataSource()) {
    final repo = _repository;
    _getStationProducts = getStationProducts ?? GetStationProducts(repo);
    _getStationOverview = getStationOverview ?? GetStationOverview(repo);
    _getStationAnalysis = getStationAnalysis ?? GetStationAnalysis(repo);
    _getStationDetails = getStationDetails ?? GetStationDetails(repo);
  }

  final StationOverviewRepositoryImpl _repository;
  late final GetStationProducts _getStationProducts;
  late final GetStationOverview _getStationOverview;
  late final GetStationAnalysis _getStationAnalysis;
  late final GetStationDetails _getStationDetails;

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadingStation = false.obs;
  final RxnString error = RxnString();

  final RxString selectedModelSerial = 'ADAPTER'.obs;
  final RxString selectedProduct = 'ALL'.obs;
  final RxString selectedModel = 'ALL'.obs;
  final RxString selectedGroup = 'ALL'.obs;
  final Rx<StationDetailType> selectedDetailType = StationDetailType.input.obs;

  final RxList<StationProduct> products = <StationProduct>[].obs;
  final RxList<String> models = <String>[].obs;

  final Rxn<StationSummary> highlightedStation = Rxn<StationSummary>();
  final Rxn<StationOverviewDashboardViewState> dashboard =
      Rxn<StationOverviewDashboardViewState>();

  final StationRateConfig rateConfig = const StationRateConfig.defaults();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  final Rxn<DateTimeRange> selectedRange = Rxn<DateTimeRange>();
  String? _dateRangeString;

  List<StationOverviewData> _overview = <StationOverviewData>[];
  List<StationAnalysisData> _analysis = <StationAnalysisData>[];
  List<StationDetailData> _details = <StationDetailData>[];

  Timer? _autoRefreshTimer;

  static const Map<String, List<String>> _groupOptions = <String, List<String>>{
    'ADAPTER': <String>['ICT', 'FT', 'CTO', 'AVI'],
    'SWITCH': <String>[
      'ICT',
      'ICT1',
      'BURN_SSD',
      'LED',
      'J_TAG',
      'WC_PRESSURE',
      'WC_WATER_FILL',
      'WC_KIT_PRESSURE',
      'WC_WASH_DRAIN_NITRO_FILL',
      'CTO',
      'FT',
      'AVI',
    ],
  };

  List<String> get availableGroups =>
      _groupOptions[selectedModelSerial.value] ?? const <String>[];

  bool get hasCustomRange => _dateRangeString != null;

  @override
  void onInit() {
    super.onInit();
    unawaited(initialize());
    _scheduleAutoRefresh();
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> initialize() async {
    await loadProducts();
    await loadOverview();
  }

  Future<void> loadProducts() async {
    try {
      final list = await _getStationProducts(selectedModelSerial.value);
      products.assignAll(list);
      models.assignAll(list.expand((item) => item.modelNames).toSet().toList()
        ..sort());
      selectedProduct.value = 'ALL';
      selectedModel.value = 'ALL';
      selectedGroup.value = 'ALL';
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> loadOverview() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = null;
    try {
      final StationOverviewFilter filter = _buildFilter();
      final result = await _getStationOverview(filter);
      _overview = result;
      _analysis = const <StationAnalysisData>[];
      _details = const <StationDetailData>[];
      highlightedStation.value = null;
      _emitViewState();
    } catch (e) {
      error.value = e.toString();
      _overview = const <StationOverviewData>[];
      _analysis = const <StationAnalysisData>[];
      _details = const <StationDetailData>[];
      _emitViewState();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshOverview() async {
    if (isRefreshing.value || isLoading.value) return;
    isRefreshing.value = true;
    try {
      final StationOverviewFilter filter = _buildFilter();
      final result = await _getStationOverview(filter);
      _overview = result;
      _emitViewState();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadStationAnalysis() async {
    final StationSummary? summary = highlightedStation.value;
    if (summary == null) {
      _analysis = const <StationAnalysisData>[];
      _emitViewState();
      return;
    }
    isLoadingStation.value = true;
    try {
      final StationOverviewFilter filter = StationOverviewFilter(
        modelSerial: selectedModelSerial.value,
        dateRange: _dateRangeString,
        productName:
            summary.productName.isEmpty ? null : summary.productName,
        groupNames: <String>[summary.groupName],
        stationName: summary.data.stationName,
      );
      final result = await _getStationAnalysis(filter);
      _analysis = result;
      _emitViewState();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingStation.value = false;
    }
  }

  Future<void> loadStationDetails() async {
    final StationSummary? summary = highlightedStation.value;
    if (summary == null) {
      _details = const <StationDetailData>[];
      _emitViewState();
      return;
    }
    isLoadingStation.value = true;
    try {
      final StationOverviewFilter filter = StationOverviewFilter(
        modelSerial: selectedModelSerial.value,
        dateRange: _dateRangeString,
        productName:
            summary.productName.isEmpty ? null : summary.productName,
        groupNames: <String>[summary.groupName],
        stationName: summary.data.stationName,
        detailType: selectedDetailType.value,
      );
      final result = await _getStationDetails(filter);
      _details = result;
      _emitViewState();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingStation.value = false;
    }
  }

  void selectStation(StationSummary summary) {
    highlightedStation.value = summary;
    unawaited(loadStationAnalysis());
    unawaited(loadStationDetails());
  }

  void changeModelSerial(String value) {
    if (value == selectedModelSerial.value) return;
    selectedModelSerial.value = value;
    selectedProduct.value = 'ALL';
    selectedModel.value = 'ALL';
    selectedGroup.value = 'ALL';
    highlightedStation.value = null;
    unawaited(loadProducts());
    unawaited(loadOverview());
  }

  void changeProduct(String value) {
    if (value == selectedProduct.value) return;
    selectedProduct.value = value;
    highlightedStation.value = null;
    unawaited(loadOverview());
  }

  void changeModel(String value) {
    if (value == selectedModel.value) return;
    selectedModel.value = value;
    highlightedStation.value = null;
    unawaited(loadOverview());
  }

  void changeGroup(String value) {
    if (value == selectedGroup.value) return;
    selectedGroup.value = value;
    highlightedStation.value = null;
    unawaited(loadOverview());
  }

  void changeDetailType(StationDetailType type) {
    selectedDetailType.value = type;
    unawaited(loadStationDetails());
  }

  Future<void> updateDateRange(DateTimeRange? range) async {
    selectedRange.value = range;
    if (range == null) {
      _dateRangeString = null;
    } else {
      final String start = _dateFormat.format(range.start);
      final String end = _dateFormat.format(range.end);
      _dateRangeString = '$start - $end';
    }
    highlightedStation.value = null;
    await loadOverview();
  }

  StationOverviewFilter _buildFilter() {
    final String? product = selectedProduct.value == 'ALL'
        ? null
        : selectedProduct.value;
    final String? model =
        selectedModel.value == 'ALL' ? null : selectedModel.value;
    final List<String> groups = selectedGroup.value == 'ALL'
        ? List<String>.from(availableGroups)
        : <String>[selectedGroup.value];

    return StationOverviewFilter(
      modelSerial: selectedModelSerial.value,
      dateRange: _dateRangeString,
      productName: product,
      modelName: model,
      groupNames: groups,
    );
  }

  void _emitViewState() {
    dashboard.value = StationOverviewDashboardViewState(
      overviewData: _overview,
      analysisData: _analysis,
      detailData: _details,
      rateConfig: rateConfig,
    );
  }

  void _scheduleAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (!hasCustomRange) {
        unawaited(refreshOverview());
      }
    });
  }
}
