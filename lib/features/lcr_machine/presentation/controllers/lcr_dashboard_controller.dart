import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/datasources/lcr_remote_data_source.dart';
import '../../data/repositories/lcr_repository_impl.dart';
import '../../domain/entities/lcr_entities.dart';
import '../../domain/usecases/get_analysis_data.dart';
import '../../domain/usecases/get_locations.dart';
import '../../domain/usecases/get_record.dart';
import '../../domain/usecases/get_tracking_data.dart';
import '../../domain/usecases/search_serial_numbers.dart';
import '../viewmodels/lcr_dashboard_view_state.dart';

class LcrDashboardController extends GetxController {
  LcrDashboardController({
    LcrRepositoryImpl? repository,
    GetLcrLocations? getLocations,
    GetLcrTrackingData? getTrackingData,
    GetLcrAnalysisData? getAnalysisData,
    SearchLcrSerialNumbers? searchSerialNumbers,
    GetLcrRecord? getRecord,
  }) : _repository = repository ??
            LcrRepositoryImpl(remoteDataSource: LcrRemoteDataSource()) {
    final repo = _repository;
    _getLocations = getLocations ?? GetLcrLocations(repo);
    _getTrackingData = getTrackingData ?? GetLcrTrackingData(repo);
    _getAnalysisData = getAnalysisData ?? GetLcrAnalysisData(repo);
    _searchSerialNumbers =
        searchSerialNumbers ?? SearchLcrSerialNumbers(repo);
    _getRecord = getRecord ?? GetLcrRecord(repo);
  }

  final LcrRepositoryImpl _repository;
  late final GetLcrLocations _getLocations;
  late final GetLcrTrackingData _getTrackingData;
  late final GetLcrAnalysisData _getAnalysisData;
  late final SearchLcrSerialNumbers _searchSerialNumbers;
  late final GetLcrRecord _getRecord;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  final RxList<LcrFactory> factories = <LcrFactory>[].obs;
  final RxList<LcrDepartment> departments = <LcrDepartment>[].obs;
  final RxList<int> machines = <int>[].obs;

  final RxString selectedFactory = 'ALL'.obs;
  final RxString selectedDepartment = 'ALL'.obs;
  final RxString selectedMachine = 'ALL'.obs;
  final RxString selectedStatus = 'ALL'.obs;
  final Rx<DateTimeRange> selectedDateRange =
      Rx<DateTimeRange>(_defaultDateRange());
  Timer? _midnightReset;
  Timer? _autoRefreshTimer;

  final RxList<LcrRecord> trackingRecords = <LcrRecord>[].obs;
  final Rxn<LcrDashboardViewState> dashboardView = Rxn<LcrDashboardViewState>();
  final RxList<LcrRecord> analysisRecords = <LcrRecord>[].obs;

  final RxList<LcrRecord> serialSearchResults = <LcrRecord>[].obs;
  final Rxn<LcrRecord> selectedRecord = Rxn<LcrRecord>();

  final RxBool isSearching = false.obs;
  final RxBool isLoadingRecord = false.obs;

  @override
  void onInit() {
    super.onInit();
    _applyDefaultShift();
    _scheduleMidnightReset();
    loadInitial();
    _startAutoRefresh();
  }

  @override
  void onClose() {
    _midnightReset?.cancel();
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> loadInitial() async {
    await loadLocations();
    await loadTrackingData();
  }

  Future<void> loadLocations() async {
    try {
      final list = await _getLocations();
      factories.assignAll(list);
      _refreshDepartmentMachineOptions();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> loadTrackingData() async {
    isLoading.value = true;
    error.value = null;
    try {
      final request = _buildRequest();
      final results = await Future.wait([
        _getTrackingData(request),
        _getAnalysisData(request),
      ]);
      trackingRecords.assignAll(results[0] as List<LcrRecord>);
      analysisRecords.assignAll(results[1] as List<LcrRecord>);
      dashboardView.value =
          LcrDashboardViewState.fromRecords(trackingRecords);
    } catch (e) {
      error.value = e.toString();
      dashboardView.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAnalysis() async {
    try {
      final request = _buildRequest();
      final list = await _getAnalysisData(request);
      analysisRecords.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<List<LcrRecord>> loadStatusRecords({required bool pass}) async {
    final baseRequest = _buildRequest();
    final override = baseRequest.copyWith(status: pass ? 'PASS' : 'FAIL');
    final list = await _getAnalysisData(override);
    return list;
  }

  Future<void> searchSerial(String query) async {
    if (query.trim().isEmpty) {
      serialSearchResults.clear();
      return;
    }
    isSearching.value = true;
    try {
      final results = await _searchSerialNumbers(query, take: 50);
      serialSearchResults.assignAll(results);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> selectRecord(int id) async {
    isLoadingRecord.value = true;
    try {
      final record = await _getRecord(id);
      selectedRecord.value = record;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingRecord.value = false;
    }
  }

  void updateFactory(String value) {
    selectedFactory.value = value;
    _refreshDepartmentMachineOptions();
  }

  void updateDepartment(String value) {
    selectedDepartment.value = value;
    _refreshMachineOptions();
  }

  void updateMachine(String value) {
    selectedMachine.value = value;
  }

  void updateStatus(String value) {
    selectedStatus.value = value;
  }

  Future<void> updateDateRange(DateTimeRange range) async {
    selectedDateRange.value = range;
    await loadTrackingData();
  }

  Future<void> resetToCurrentShiftAndReload() async {
    _applyDefaultShift();
    await loadTrackingData();
  }

  void _applyDefaultShift() {
    selectedDateRange.value = _defaultDateRange();
  }

  void _scheduleMidnightReset() {
    _midnightReset?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);
    _midnightReset = Timer(duration, () {
      _applyDefaultShift();
      _scheduleMidnightReset();
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!isLoading.value) {
        loadTrackingData();
      }
    });
  }

  static DateTimeRange _defaultDateRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 7, 30);
    final end = DateTime(now.year, now.month, now.day, 19, 30);
    return DateTimeRange(start: start, end: end);
  }

  LcrRequest _buildRequest() {
    final factory = _normalize(selectedFactory.value);
    final department = _normalize(selectedDepartment.value);
    final machine = _normalize(selectedMachine.value);
    final status = _normalize(selectedStatus.value);
    final range = selectedDateRange.value;
    final formattedRange = '${_fmt(range.start)} - ${_fmt(range.end)}';

    return LcrRequest(
      factory: factory,
      department: department,
      machineNo: machine,
      dateRange: formattedRange,
      status: status,
    );
  }

  void _refreshDepartmentMachineOptions() {
    final factory = selectedFactory.value;
    if (factory == 'ALL') {
      departments.assignAll(
        factories.expand((f) => f.departments).toList(),
      );
    } else {
      final match = _findFactory(factory);
      if (match != null) {
        departments.assignAll(match.departments);
      } else {
        departments.clear();
      }
    }
    if (!departments.any((d) => d.name == selectedDepartment.value)) {
      selectedDepartment.value = 'ALL';
    }
    _refreshMachineOptions();
  }

  void _refreshMachineOptions() {
    final dept = selectedDepartment.value;
    if (dept == 'ALL') {
      machines.assignAll(departments.expand((d) => d.machines).toSet().toList()
        ..sort());
    } else {
      final match = _findDepartment(dept);
      if (match != null) {
        final sorted = List<int>.from(match.machines)..sort();
        machines.assignAll(sorted);
      } else {
        machines.clear();
      }
    }
    if (selectedMachine.value != 'ALL' &&
        !machines.contains(int.tryParse(selectedMachine.value))) {
      selectedMachine.value = 'ALL';
    }
  }

  String _fmt(DateTime date) {
    return _dateFormatter.format(date);
  }

  String _normalize(String value) {
    return value.toUpperCase() == 'ALL' ? '' : value;
  }

  LcrFactory? _findFactory(String name) {
    for (final factory in factories) {
      if (factory.name == name) return factory;
    }
    return null;
  }

  LcrDepartment? _findDepartment(String name) {
    for (final dept in departments) {
      if (dept.name == name) return dept;
    }
    return null;
  }
}
