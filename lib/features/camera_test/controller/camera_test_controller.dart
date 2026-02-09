import 'dart:math';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:smart_factory/config/bantha.dart';
import 'package:smart_factory/features/camera_test/model/capture_payload.dart';
import 'package:smart_factory/features/camera_test/service/camera_service.dart';
import 'package:smart_factory/features/camera_test/service/capture_api_service.dart';
import 'package:smart_factory/features/camera_test/service/scan_service.dart';
import 'package:smart_factory/service/auth/token_manager.dart';

enum TestState { idle, productDetected, readyToCapture, captured, doneCapture, uploading }

class CameraTestController extends GetxController with WidgetsBindingObserver {
  CameraTestController({
    required this.autoScan,
    CameraService? cameraService,
    ScanService? scanService,
    CaptureApiService? captureApiService,
  })  : _cameraService = cameraService ?? CameraService(),
        _scanService = scanService ?? ScanService(),
        _captureApiService = captureApiService ?? CaptureApiService();

  final bool autoScan;
  final CameraService _cameraService;
  final ScanService _scanService;
  final CaptureApiService _captureApiService;

  TestState state = TestState.idle;

  bool get isScanMode => autoScan;

  bool showCameraPreview = false;
  bool hasScannedQr = false;
  bool showScanForm = false;

  Map<String, dynamic>? product;
  final List<XFile> captured = [];

  double zoomLevel = 1.0;
  double minZoom = 1.0;
  double maxZoom = 1.0;

  final factoryCtrl = TextEditingController();
  final floorCtrl = TextEditingController();
  final stationCtrl = TextEditingController();
  final modelnameCtrl = TextEditingController();
  final serialCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final errorCodeCtrl = TextEditingController();
  final errorNameCtrl = TextEditingController();
  final errorDescCtrl = TextEditingController();
  String result = "PASS";

  List<String> factories = [];
  List<String> floors = [];

  String? selectedFactory;
  String? selectedFloor;

  bool _disposed = false;
  int _scanSession = 0;
  bool _initializingCamera = false;

  CameraController? get cameraController => _cameraService.controller;
  bool get isInitializingCamera => _initializingCamera;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _fillUserFromToken();

    factories = BanthaConfig.factories;

    if (autoScan) {
      _scheduleScan(const Duration(milliseconds: 300));
    }
  }

  @override
  void onClose() {
    _disposed = true;
    _scanSession++;
    WidgetsBinding.instance.removeObserver(this);

    _cameraService.disposeControllerSafe();

    factoryCtrl.dispose();
    floorCtrl.dispose();
    stationCtrl.dispose();
    errorDescCtrl.dispose();
    modelnameCtrl.dispose();
    serialCtrl.dispose();
    userCtrl.dispose();
    noteCtrl.dispose();
    errorCodeCtrl.dispose();
    errorNameCtrl.dispose();
    super.onClose();
  }

  void _safeUpdate([VoidCallback? fn]) {
    if (_disposed) return;
    fn?.call();
    update();
  }

  Future<void> _fillUserFromToken() async {
    final token = TokenManager().civetToken.value;
    if (token.isEmpty) return;

    try {
      final decoded = JwtDecoder.decode(token);
      final username = decoded["FoxconnID"] ?? decoded["UserName"] ?? decoded["sub"];
      if (username == null) return;
      if (_disposed) return;
      userCtrl.text = username.toString();
    } catch (_) {
      // ignore invalid token
    }
  }

  void _scheduleScan(Duration delay) {
    final int session = ++_scanSession;
    Future.delayed(delay, () {
      if (_disposed || session != _scanSession) return;
      scanQr();
    });
  }

  Future<void> scanQr() async {
    final int session = ++_scanSession;

    final qr = await _scanService.scanQr();
    if (_disposed || session != _scanSession) return;

    if (qr != null && qr["manual"] == true) {
      _enterManualSn();
      return;
    }

    if (qr == null) {
      if (isScanMode) {
        _scanSession++;
        _safeUpdate(() {
          showCameraPreview = false;
          hasScannedQr = false;
          showScanForm = false;
          state = TestState.idle;
        });

        final context = Get.context;
        if (context != null && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Get.back();
        }
        return;
      }

      Get.snackbar("Lỗi", "Không đọc được mã QR");
      return;
    }

    product = qr;
    serialCtrl.text = product?["serial"] ?? "";
    modelnameCtrl.text = product?["model"] ?? "";

    _safeUpdate(() {
      hasScannedQr = true;
      showScanForm = true;
      showCameraPreview = false;
      state = TestState.doneCapture;
    });
  }

  void _enterManualSn() {
    _safeUpdate(() {
      product = null;
      serialCtrl.clear();
      hasScannedQr = true;
      showScanForm = true;
      showCameraPreview = false;
      state = TestState.doneCapture;
    });
  }

  Future<void> initCamera() async {
    if (_disposed || _cameraService.isDisposing || _initializingCamera) return;

    if (cameraController != null && (cameraController?.value.isInitialized ?? false)) {
      return;
    }

    _initializingCamera = true;

    try {
      final initResult = await _cameraService.initializeCamera();
      if (_disposed) return;
      if (initResult == null) {
        if (isScanMode) {
          _safeUpdate(() {
            showCameraPreview = false;
            showScanForm = true;
          });
        }
        return;
      }

      minZoom = initResult.minZoom;
      maxZoom = initResult.maxZoom;
      zoomLevel = initResult.zoomLevel;

      _safeUpdate(() {
        state = TestState.readyToCapture;
      });
    } finally {
      _initializingCamera = false;
      if (!_disposed) {
        update();
      }
    }
  }

  Future<void> zoomIn() async {
    if (cameraController == null) return;
    zoomLevel = min(maxZoom, zoomLevel + 0.2);
    await _cameraService.setZoomLevel(zoomLevel);
    if (_disposed) return;
    update();
  }

  Future<void> zoomOut() async {
    if (cameraController == null) return;
    zoomLevel = max(minZoom, zoomLevel - 0.2);
    await _cameraService.setZoomLevel(zoomLevel);
    if (_disposed) return;
    update();
  }

  Future<void> updateZoom(double scale) async {
    if (cameraController == null) return;
    zoomLevel = (zoomLevel * scale).clamp(minZoom, maxZoom);
    await _cameraService.setZoomLevel(zoomLevel);
    if (_disposed) return;
    update();
  }

  Future<void> capture() async {
    if (isScanMode) {
      if (!hasScannedQr) {
        await scanQr();
        return;
      }

      if (showCameraPreview) return;

      _safeUpdate(() {
        showCameraPreview = true;
        showScanForm = true;
        state = TestState.doneCapture;
      });

      if (cameraController == null || !(cameraController?.value.isInitialized ?? false)) {
        await initCamera();
      }

      if (_disposed) return;
      if (cameraController == null || !(cameraController?.value.isInitialized ?? false)) {
        _safeUpdate(() => showCameraPreview = false);
      }
      return;
    }

    if (cameraController == null || !cameraController!.value.isInitialized) return;

    try {
      final photo = await _cameraService.capturePhoto();
      if (_disposed) return;
      if (photo != null) {
        captured.add(photo);
        _safeUpdate(() => state = TestState.doneCapture);
      }
    } catch (e) {
      if (_disposed) return;
      Get.snackbar("Chụp lỗi", e.toString());
    }
  }

  Future<void> takePhotoFromPreview() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      _safeUpdate(() => showCameraPreview = false);
      return;
    }

    try {
      final photo = await _cameraService.capturePhoto();
      if (_disposed) return;

      if (photo != null) {
        captured.add(photo);
      }

      _safeUpdate(() {
        state = TestState.doneCapture;
        showCameraPreview = false;
        showScanForm = true;
      });
    } catch (e) {
      if (_disposed) return;
      Get.snackbar("Chụp lỗi", e.toString());

      _safeUpdate(() {
        showCameraPreview = false;
        showScanForm = true;
      });
    }
  }

  void closeCameraPreview() {
    _safeUpdate(() {
      showCameraPreview = false;
      if (isScanMode) {
        showScanForm = hasScannedQr;
        state = hasScannedQr ? TestState.doneCapture : TestState.idle;
      }
    });
  }

  void onFactoryChanged(String? val) {
    _safeUpdate(() {
      selectedFactory = val;
      selectedFloor = null;
      floorCtrl.clear();
      stationCtrl.clear();
      floors = val == null ? [] : BanthaConfig.floorsOf(val);
    });
  }

  void onFloorChanged(String? val) {
    _safeUpdate(() {
      selectedFloor = val;
      floorCtrl.text = val ?? "";
      stationCtrl.clear();
    });
  }

  void onStationChanged(String val) {
    _safeUpdate(() {
      stationCtrl.text = val;
    });
  }

  Future<void> pickImagesFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (_disposed) return;

    final paths = result?.paths.whereType<String>().toList();
    if (paths == null || paths.isEmpty) return;

    _safeUpdate(() {
      for (final path in paths) {
        captured.add(XFile(path));
      }
      state = TestState.doneCapture;
    });
  }

  Future<void> finishCapture() async {
    if (_disposed) return;
    _safeUpdate(() {
      state = TestState.doneCapture;
    });
  }

  Future<void> sendToApi(List<XFile> images) async {
    if (factoryCtrl.text.trim().isEmpty ||
        floorCtrl.text.trim().isEmpty ||
        stationCtrl.text.trim().isEmpty ||
        modelnameCtrl.text.trim().isEmpty ||
        serialCtrl.text.trim().isEmpty) {
      Get.snackbar("Lỗi", "Vui lòng nhập đầy đủ Factory / Floor / Station / Serial");
      return;
    }

    if (result == "FAIL") {
      if (errorCodeCtrl.text.trim().isEmpty) {
        Get.snackbar("Lỗi", "Vui lòng nhập Error Code");
        return;
      }
      if (images.isEmpty) {
        Get.snackbar("Lỗi", "FAIL phải có ít nhất 1 ảnh");
        return;
      }
    }

    _safeUpdate(() => state = TestState.uploading);

    try {
      final payload = CapturePayload(
        factory: factoryCtrl.text.trim(),
        floor: floorCtrl.text.trim(),
        modelName: modelnameCtrl.text.trim(),
        serialNumber: serialCtrl.text.trim(),
        station: stationCtrl.text.trim(),
        result: result,
        comment: noteCtrl.text.trim(),
        username: userCtrl.text.trim(),
        errorCode: result == "FAIL" ? errorCodeCtrl.text.trim() : null,
        errorName: result == "FAIL" ? errorNameCtrl.text.trim() : null,
        errorDescription: result == "FAIL" ? errorDescCtrl.text.trim() : null,
      );

      final response = await _captureApiService.sendCapture(
        payload: payload,
        images: images,
      );

      if (_disposed) return;

      if (response.isSuccess) {
        Get.defaultDialog(
          title: "Thành công",
          content: const Text("Upload thành công"),
          textConfirm: "OK",
          onConfirm: () async {
            Get.back();

            if (_disposed) return;

            await _cameraService.disposeControllerSafe();
            if (_disposed) return;

            captured.clear();
            modelnameCtrl.clear();
            serialCtrl.clear();
            stationCtrl.clear();
            noteCtrl.clear();
            errorCodeCtrl.clear();
            errorDescCtrl.clear();
            result = "PASS";
            product = null;
            showCameraPreview = false;

            _safeUpdate(() {
              state = TestState.idle;
              hasScannedQr = false;
              showScanForm = false;
            });

            if (isScanMode) {
              _scheduleScan(const Duration(milliseconds: 250));
            }
          },
        );
      } else {
        Get.snackbar(
          "API lỗi",
          "Code: ${response.statusCode}\n${response.body}",
        );
      }
    } catch (e) {
      if (_disposed) return;
      Get.snackbar("Upload lỗi", e.toString());
    }

    _safeUpdate(() => state = TestState.doneCapture);
  }

  void removeCapturedAt(int index) {
    if (index < 0 || index >= captured.length) return;
    _safeUpdate(() {
      captured.removeAt(index);
    });
  }

  void clearCaptured() {
    _safeUpdate(() {
      captured.clear();
    });
  }

  void setResult(String value) {
    _safeUpdate(() {
      result = value;
      if (result == "PASS") {
        errorCodeCtrl.clear();
        errorNameCtrl.clear();
        errorDescCtrl.clear();
        captured.clear();
      }
    });
  }

  void cancelCapture() {
    if (isScanMode) {
      captured.clear();
      errorCodeCtrl.clear();
      noteCtrl.clear();
      result = "PASS";
      product = null;
      serialCtrl.clear();
      modelnameCtrl.clear();

      _safeUpdate(() {
        state = TestState.idle;
        hasScannedQr = false;
        showScanForm = false;
        showCameraPreview = false;
      });

      _cameraService.disposeControllerSafe();
      _scheduleScan(const Duration(milliseconds: 200));
      return;
    }

    captured.clear();
    state = TestState.readyToCapture;
    initCamera();
    update();
  }

  Future<bool> handleWillPop() async {
    if (isScanMode) {
      if (showCameraPreview) {
        closeCameraPreview();
        return false;
      }

      if (hasScannedQr || showScanForm) {
        captured.clear();
        errorCodeCtrl.clear();
        noteCtrl.clear();
        result = "PASS";
        product = null;
        serialCtrl.clear();
        modelnameCtrl.clear();

        _safeUpdate(() {
          state = TestState.idle;
          hasScannedQr = false;
          showScanForm = false;
        });

        _scheduleScan(const Duration(milliseconds: 150));
        return false;
      }

      return true;
    }

    return true;
  }
}
