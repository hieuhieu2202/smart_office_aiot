import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/datasources/resistor_machine_remote_data_source.dart';
import '../../data/repositories/resistor_machine_repository_impl.dart';
import '../../domain/entities/resistor_machine_entities.dart';
import '../../domain/usecases/get_machine_names.dart';
import '../../domain/usecases/get_record_by_id.dart';
import '../../domain/usecases/get_status_data.dart';
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
    _searchSerialNumbers =
        searchSerialNumbers ?? SearchResistorMachineSerialNumbers(repo);
  }

  final ResistorMachineRepositoryImpl _repository;
  late final GetResistorMachineNames _getMachineNames;
  late final GetResistorMachineTrackingData _getTrackingData;
  late final GetResistorMachineStatusData _getStatusData;
  late final GetResistorMachineRecordById _getRecordById;
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
  final Rxn<ResistorMachineSerialMatch> selectedSerial =
      Rxn<ResistorMachineSerialMatch>();
  final Rxn<ResistorMachineTestResult> selectedTestResult =
      Rxn<ResistorMachineTestResult>();
  final RxBool isLoadingRecord = false.obs;

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
      final request = _buildTrackingRequest();
      _logRequest('Tracking', request);
      final tracking = await _getTrackingData(request);
      _logTrackingData(tracking);
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
      final request = _buildStatusRequest();
      _logRequest('Status', request);
      final list = await _getStatusData(request);
      _logStatusData(list);
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

  void clearSerialSearch() {
    serialMatches.clear();
  }

  Future<void> loadRecordDetail(int id) async {
    isLoadingRecord.value = true;
    try {
      final record = await _getRecordById(id);
      if (record != null) {
        selectedRecord.value = record;
        final tests = _parseTestResults(record.dataDetails);
        recordTestResults.assignAll(tests);
        if (tests.isNotEmpty) {
          selectedTestResult.value = tests.first;
        } else {
          selectedTestResult.value = null;
        }
      } else {
        selectedRecord.value = null;
        recordTestResults.clear();
        selectedTestResult.value = null;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingRecord.value = false;
    }
  }

  Future<void> selectSerial(ResistorMachineSerialMatch match) async {
    selectedSerial.value = match;
    serialMatches.clear();
    await loadRecordDetail(match.id);
  }

  void clearSelectedSerial() {
    selectedSerial.value = null;
    selectedRecord.value = null;
    recordTestResults.clear();
    selectedTestResult.value = null;
  }

  void selectTestResult(ResistorMachineTestResult result) {
    selectedTestResult.value = result;
  }

  List<ResistorMachineTestResult> _parseTestResults(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const <ResistorMachineTestResult>[];
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((Map<String, dynamic> item) {
          final detailsRaw =
              (item['List_Result'] ?? const <dynamic>[]) as List<dynamic>;
          final details = detailsRaw
              .whereType<Map<String, dynamic>>()
              .map((Map<String, dynamic> detail) {
            double parseDouble(dynamic value) {
              if (value is int) return value.toDouble();
              if (value is double) return value;
              if (value is String) {
                return double.tryParse(value) ?? 0;
              }
              return 0;
            }

            return ResistorMachineResultDetail(
              name: (detail['Name'] ?? '') as String,
              row: (detail['Row'] ?? 0) as int,
              column: (detail['Column'] ?? 0) as int,
              measurementValue:
                  parseDouble(detail['Measurement_Value'] ?? detail['measurementValue']),
              lowSampleValue:
                  parseDouble(detail['Low_Sample_Value'] ?? detail['lowSampleValue']),
              highSampleValue:
                  parseDouble(detail['High_Sample_Value'] ?? detail['highSampleValue']),
              pass: (detail['Pass'] ?? false) as bool,
            );
          }).toList();

          return ResistorMachineTestResult(
            address: (item['Address'] ?? 0) as int,
            result: (item['Result'] ?? false) as bool,
            imagePath: (item['ImagePath'] ?? '') as String,
            details: details,
          );
        }).toList();
      }
    } catch (_) {
      // Ignore parsing errors.
    }

    return const <ResistorMachineTestResult>[];
  }

  void updateRange(DateTimeRange range) {
    selectedRange.value = range;
    selectedShift.value = _deriveShift(range.start);
    loadDashboard();
    loadStatus();
  }

  void updateShift(String shift) {
    if (shift == selectedShift.value) {
      return;
    }

    final current = selectedRange.value.start;
    final dayAnchor = DateTime(current.year, current.month, current.day);

    DateTimeRange newRange;
    if (shift == 'D') {
      final start = dayAnchor.add(const Duration(hours: 7, minutes: 30));
      final end = start.add(const Duration(hours: 12));
      newRange = DateTimeRange(start: start, end: end);
    } else {
      final start = dayAnchor.add(const Duration(hours: 19, minutes: 30));
      final end = start.add(const Duration(hours: 12));
      newRange = DateTimeRange(start: start, end: end);
    }

    updateRange(newRange);
  }

  void updateStatus(String status) {
    selectedStatus.value = status;
    loadDashboard();
    loadStatus();
  }

  void updateMachine(String machine) {
    selectedMachine.value = machine;
    loadDashboard();
    loadStatus();
  }

  ResistorMachineRequest _buildTrackingRequest() {
    final rangeText = _formatRange(selectedRange.value);
    final machine = _resolveSelection(selectedMachine.value);
    final status = _resolveSelection(selectedStatus.value);

    return ResistorMachineRequest(
      dateRange: rangeText,
      shift: selectedShift.value,
      machineName: machine,
      status: status,
    );
  }

  ResistorMachineRequest _buildStatusRequest() {
    final rangeText = _formatRange(selectedRange.value);
    final machine = _resolveSelection(selectedMachine.value);
    final status = _resolveSelection(selectedStatus.value);

    return ResistorMachineRequest(
      dateRange: rangeText,
      shift: selectedShift.value,
      machineName: machine,
      status: status,
    );
  }

  String _formatRange(DateTimeRange range) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final start = formatter.format(range.start);
    final end = formatter.format(range.end);
    return '$start - $end';
  }

  String _resolveSelection(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'ALL';
    }
    return trimmed.toUpperCase() == 'ALL' ? 'ALL' : trimmed;
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

  void _logTrackingData(ResistorMachineTrackingData tracking) {
    final summary = tracking.summary;
    debugPrint('[ResistorDashboard] Summary: total=${summary.total}, '
        'pass=${summary.pass}, fail=${summary.fail}, '
        'yieldRate=${summary.yieldRate}');
    debugPrint('[ResistorDashboard] Outputs (${tracking.outputs.length} items): '
        '${tracking.outputs.map((e) => {
              'label': e.displayLabel,
              'pass': e.pass,
              'fail': e.fail,
              'yr': e.yieldRate
            }).toList()}');
    debugPrint('[ResistorDashboard] Machines (${tracking.machines.length} items): '
        '${tracking.machines.map((e) => {
              'name': e.name,
              'pass': e.pass,
              'fail': e.fail,
              'yr': e.yieldRate
            }).toList()}');
  }

  void _logStatusData(List<ResistorMachineStatus> list) {
    debugPrint('[ResistorDashboard] Status entries (${list.length} items) loaded');
    if (list.isNotEmpty) {
      final preview = list.take(5).map((entry) => {
            'serial': entry.serialNumber,
            'machine': entry.machineName,
            'station': entry.stationSequence,
            'time': entry.inStationTime.toIso8601String(),
          });
      debugPrint('[ResistorDashboard] Status preview: ${preview.toList()}');
    }
  }

  void _logRequest(String label, ResistorMachineRequest request) {
    final payload = request.toBody();
    debugPrint('[ResistorDashboard] $label request payload: $payload');
  }

  static DateTimeRange _defaultRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 7, 30);
    final end = DateTime(now.year, now.month, now.day, 19, 30);
    return DateTimeRange(start: start, end: end);
  }

  String _deriveShift(DateTime date) {
    final totalMinutes = date.hour * 60 + date.minute;
    final dayStart = 7 * 60 + 30; // 07:30
    final nightStart = 19 * 60 + 30; // 19:30

    if (totalMinutes >= dayStart && totalMinutes < nightStart) {
      return 'D';
    }
    return 'N';
  }
}
