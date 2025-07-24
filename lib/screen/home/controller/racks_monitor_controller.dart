import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../service/lc_switch_rack_api.dart';

class RacksMonitorController extends GetxController
    with GetTickerProviderStateMixin {
  var racks = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;
  var summary = {}.obs;
  var modelSummary = <Map<String, dynamic>>[].obs;
  var slotStat = <Map<String, dynamic>>[].obs;

  late AnimationController yrAnimationController;
  late Animation<double> yrAnimation;

  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _initAnimation();
    loadRacks();
    _startAutoRefresh();
  }

  void _initAnimation() {
    yrAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    yrAnimationController.dispose();
    super.onClose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      loadRacks();
    });
  }

  Future<void> loadRacks() async {
    try {
      isLoading.value = true;
      error.value = '';
      final data = await LCSwitchRackApi.getRackMonitoring();
      final rackList = data['Data']?['RackDetails'];
      final sumData = data['Data']?['QuantitySummary'];
      final modelList = data['Data']?['ModelDetails'];
      final statList = data['Data']?['SlotStatic'];

      if (rackList is List) {
        racks.value = List<Map<String, dynamic>>.from(rackList);
      } else {
        racks.value = [];
      }

      if (sumData is Map) {
        summary.value = Map<String, dynamic>.from(sumData);
      } else {
        summary.value = {};
      }

      if (modelList is List) {
        modelSummary.value = List<Map<String, dynamic>>.from(modelList);
      } else {
        modelSummary.value = [];
      }

      if (statList is List) {
        slotStat.value = List<Map<String, dynamic>>.from(statList);
      } else {
        slotStat.value = [];
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
    // printAllDebugInfo();
  }

  // === Getter cho các trường của QuantitySummary ===
  double get totalUT =>
      double.tryParse(summary['UT']?.toString() ?? '0') ?? 0.0;

  double get totalYR =>
      double.tryParse(summary['YR']?.toString() ?? '0') ?? 0.0;

  int get totalWIP =>
      summary['WIP'] is int
          ? summary['WIP']
          : int.tryParse(summary['WIP'].toString()) ?? 0;

  int get totalInput =>
      summary['Input'] is int
          ? summary['Input']
          : int.tryParse(summary['Input'].toString()) ?? 0;

  int get totalFirstPass =>
      summary['First_Pass'] is int
          ? summary['First_Pass']
          : int.tryParse(summary['First_Pass'].toString()) ?? 0;

  int get totalSecondPass =>
      summary['Second_Pass'] is int
          ? summary['Second_Pass']
          : int.tryParse(summary['Second_Pass'].toString()) ?? 0;

  int get totalPass =>
      summary['Pass'] is int
          ? summary['Pass']
          : int.tryParse(summary['Pass'].toString()) ?? 0;

  int get totalRePass =>
      summary['Re_Pass'] is int
          ? summary['Re_Pass']
          : int.tryParse(summary['Re_Pass'].toString()) ?? 0;

  int get totalFail =>
      summary['Fail'] is int
          ? summary['Fail']
          : int.tryParse(summary['Fail'].toString()) ?? 0;

  int get totalFirstFail =>
      summary['First_Fail'] is int
          ? summary['First_Fail']
          : int.tryParse(summary['First_Fail'].toString()) ?? 0;

  int get totalTotalPass =>
      summary['Total_Pass'] is int
          ? summary['Total_Pass']
          : int.tryParse(summary['Total_Pass'].toString()) ?? 0;

  double get totalFPR =>
      double.tryParse(summary['FPR']?.toString() ?? '0') ?? 0.0;

  // === Getter cho SlotStatic (thống kê trạng thái slot) ===
  int get waitingSlot =>
      slotStat.firstWhereOrNull((e) => e['Status'] == 'Waiting')?['Value'] ?? 0;

  int get testingSlot =>
      slotStat.firstWhereOrNull((e) => e['Status'] == 'Testing')?['Value'] ?? 0;

  int get notUsedSlot =>
      slotStat.firstWhereOrNull((e) => e['Status'] == 'NotUsed')?['Value'] ?? 0;

  int get failSlot =>
      slotStat.firstWhereOrNull((e) => e['Status'] == 'Fail')?['Value'] ?? 0;

  int get passSlot =>
      slotStat.firstWhereOrNull((e) => e['Status'] == 'Pass')?['Value'] ?? 0;

  // Tổng số slot
  int get totalSlotCount => slotStat.fold(0, (int sum, item) {
    final value = item['Value'];
    if (value is int) return sum + value;
    if (value is String) return sum + (int.tryParse(value) ?? 0);
    return sum;
  });

  // === Getter cho ModelDetails ===
  // Lấy ra tổng pass theo model
  int getModelTotalPass(String modelName) {
    final model = modelSummary.firstWhereOrNull(
      (e) => e['ModelName'] == modelName,
    );
    if (model == null) return 0;
    return model['TotalPass'] is int
        ? model['TotalPass']
        : int.tryParse(model['TotalPass'].toString()) ?? 0;
  }
  void printAllDebugInfo() {
    print('======= DEBUG INFO RacksMonitorController =======');
    print('racks: $racks');
    print('isLoading: $isLoading');
    print('error: $error');
    print('summary: $summary');
    print('modelSummary: $modelSummary');
    print('slotStat: $slotStat');

    print('--- Summary (QuantitySummary) ---');
    print('totalUT: $totalUT');
    print('totalYR: $totalYR');
    print('totalWIP: $totalWIP');
    print('totalInput: $totalInput');
    print('totalFirstPass: $totalFirstPass');
    print('totalSecondPass: $totalSecondPass');
    print('totalPass: $totalPass');
    print('totalRePass: $totalRePass');
    print('totalFail: $totalFail');
    print('totalFirstFail: $totalFirstFail');
    print('totalTotalPass: $totalTotalPass');
    print('totalFPR: $totalFPR');

    print('--- Slot Static ---');
    print('waitingSlot: $waitingSlot');
    print('testingSlot: $testingSlot');
    print('notUsedSlot: $notUsedSlot');
    print('failSlot: $failSlot');
    print('passSlot: $passSlot');
    print('totalSlotCount: $totalSlotCount');

    print('--- Model Details ---');
    print('modelSummary:');
    for (var model in modelSummary) {
      print('  ModelName: ${model['ModelName']}, TotalPass: ${model['TotalPass']}');
    }

    print('===============================================');
  }
}



