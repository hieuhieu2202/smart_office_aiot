import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/datasources/resistor_machine_remote_data_source.dart';
import '../../data/repositories/resistor_machine_repository_impl.dart';
import '../../domain/entities/resistor_machine_entities.dart';
import '../../domain/usecases/get_machine_names.dart';
import '../../domain/usecases/get_record_by_id.dart';
import '../../domain/usecases/get_status_data.dart';
import '../../domain/usecases/get_test_results.dart';
import '../../domain/usecases/get_tracking_data.dart';
import '../../domain/usecases/search_serial_numbers.dart';
import '../viewmodels/resistor_dashboard_view_state.dart';

class AutomationResistorDashboardController extends GetxController {
  AutomationResistorDashboardController({
    ResistorMachineRepositoryImpl? repository,
    GetResistorMachineNames? getMachineNames,
    GetResistorMachineTrackingData? getTrackingData,
    GetResistorMachineStatusData? getStatusData,
    GetResistorMachineRecordById? getRecordById,
    GetResistorMachineTestResults? getTestResults,
    SearchResistorMachineSerialNumbers? searchSerialNumbers,
  }) : _repository = repository ??
            ResistorMachineRepositoryImpl(
              remoteDataSource: ResistorMachineRemoteDataSource(),
            ) {
    final repo = _repository;
    _getMachineNames = getMachineNames ?? GetResistorMachineNames(repo);
    _getTrackingData = getTrackingData ?? GetResistorMachineTrackingData(repo);
    _getStatusData = getStatusData ?? GetResistorMachineStatusData(repo);
    _getRecordById = getRecordById ?? GetResistorMachineRecordById(repo);
    _getTestResults = getTestResults ?? GetResistorMachineTestResults(repo);
    _searchSerialNumbers =
        searchSerialNumbers ?? SearchResistorMachineSerialNumbers(repo);
  }

  final ResistorMachineRepositoryImpl _repository;
  late final GetResistorMachineNames _getMachineNames;
  late final GetResistorMachineTrackingData _getTrackingData;
  late final GetResistorMachineStatusData _getStatusData;
  late final GetResistorMachineRecordById _getRecordById;
  late final GetResistorMachineTestResults _getTestResults;
  late final SearchResistorMachineSerialNumbers _searchSerialNumbers;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingStatus = false.obs;
  final RxBool isSearchingSerial = false.obs;
  final RxnString error = RxnString();

  final RxList<String> machineNames = <String>['ALL'].obs;
  final RxString selectedMachine = 'ALL'.obs;
  final RxString selectedShift = 'D'.obs;
  final RxString selectedStatus = 'ALL'.obs;
  final Rx<DateTimeRange> selectedRange =
      Rx<DateTimeRange>(_defaultRange());

  final Rxn<ResistorDashboardViewState> dashboardView =
      Rxn<ResistorDashboardViewState>();
  final Rx<ResistorMachineTrackingData?> rawTracking =
      Rx<ResistorMachineTrackingData?>(null);
  final RxList<ResistorMachineStatus> statusEntries =
      <ResistorMachineStatus>[].obs;
  final RxList<ResistorMachineSerialMatch> serialMatches =
      <ResistorMachineSerialMatch>[].obs;
  final Rxn<ResistorMachineRecord> selectedRecord =
      Rxn<ResistorMachineRecord>();
  final RxList<ResistorMachineTestResult> recordTestResults =
      <ResistorMachineTestResult>[].obs;

  Timer? _autoRefresh;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
    _startAutoRefresh();
  }

  @override
  void onClose() {
    _autoRefresh?.cancel();
    super.onClose();
  }

  Future<void> loadInitial() async {
    await Future.wait([_loadMachines(), loadDashboard()]);
    await loadStatus();
  }

  Future<void> _loadMachines() async {
    try {
      final names = await _getMachineNames();
      machineNames
        ..clear()
        ..add('ALL')
        ..addAll(names);
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    error.value = null;
    try {
      final request = _buildRequest();
      final tracking = await _getTrackingData(request);
      rawTracking.value = tracking;
      dashboardView.value =
          ResistorDashboardViewState.fromTracking(tracking);
    } catch (e) {
      error.value = e.toString();
      dashboardView.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStatus() async {
    isLoadingStatus.value = true;
    try {
      final request = _buildRequest();
      final list = await _getStatusData(request);
      statusEntries.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingStatus.value = false;
    }
  }

  Future<void> searchSerial(String query) async {
    if (query.trim().isEmpty) {
      serialMatches.clear();
      return;
    }
    isSearchingSerial.value = true;
    try {
      final results = await _searchSerialNumbers(query, take: 30);
      serialMatches.assignAll(results);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSearchingSerial.value = false;
    }
  }

  Future<void> loadRecordDetail(int id) async {
    try {
      final record = await _getRecordById(id);
      if (record != null) {
        selectedRecord.value = record;
        final tests = await _getTestResults(id);
        recordTestResults.assignAll(tests);
      } else {
        selectedRecord.value = null;
        recordTestResults.clear();
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  void updateRange(DateTimeRange range) {
    selectedRange.value = range;
    loadDashboard();
    loadStatus();
  }

  void updateShift(String shift) {
    selectedShift.value = shift;
    loadDashboard();
    loadStatus();
  }

  void updateStatus(String status) {
    selectedStatus.value = status;
    loadStatus();
  }

  void updateMachine(String machine) {
    selectedMachine.value = machine;
    loadDashboard();
    loadStatus();
  }

  ResistorMachineRequest _buildRequest() {
    final formatter = DateFormat('yyyy-MM-dd');
    final start = formatter.format(selectedRange.value.start);
    final end = formatter.format(selectedRange.value.end);
    final range = '$start - $end';

    return ResistorMachineRequest(
      dateRange: range,
      shift: selectedShift.value,
      machineName: selectedMachine.value,
      status: selectedStatus.value,
    );
  }

  void _startAutoRefresh() {
    _autoRefresh?.cancel();
    _autoRefresh = Timer.periodic(const Duration(minutes: 5), (_) {
      loadDashboard();
      if (statusEntries.isNotEmpty) {
        loadStatus();
      }
    });
  }

  static DateTimeRange _defaultRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: start, end: now);
  }
}
