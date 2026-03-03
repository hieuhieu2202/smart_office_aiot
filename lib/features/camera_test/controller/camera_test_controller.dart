import 'dart:math';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:smart_factory/config/bantha.dart';
import 'package:smart_factory/features/camera_test/model/capture_payload.dart';
import 'package:smart_factory/features/camera_test/service/camera_service.dart';
import 'package:smart_factory/features/camera_test/service/capture_api_service.dart';
import 'package:smart_factory/service/auth/token_manager.dart';
import '../view/camera_capture_screen.dart';
import 'package:flutter/services.dart';

enum TestState { idle, readyToCapture, doneCapture, uploading }

class CameraTestController extends GetxController
    with WidgetsBindingObserver {
  CameraTestController({
    CameraService? cameraService,
    CaptureApiService? captureApiService,
  })  : _cameraService = cameraService ?? CameraService(),
        _captureApiService =
            captureApiService ?? CaptureApiService();

  final CameraService _cameraService;
  final CaptureApiService _captureApiService;

  TestState state = TestState.idle;

  final List<XFile> captured = [];

  double zoomLevel = 1.0;
  double minZoom = 1.0;
  double maxZoom = 1.0;

  final factoryCtrl = TextEditingController();
  final floorCtrl = TextEditingController();
  final stationCtrl = TextEditingController();
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
  bool _initializingCamera = false;

  CameraController? get cameraController =>
      _cameraService.controller;
  bool get isInitializingCamera => _initializingCamera;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    factories = BanthaConfig.factories;
    _fillUserFromToken();
  }

  @override
  void onClose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.disposeControllerSafe();

    factoryCtrl.dispose();
    floorCtrl.dispose();
    stationCtrl.dispose();
    serialCtrl.dispose();
    userCtrl.dispose();
    noteCtrl.dispose();
    errorCodeCtrl.dispose();
    errorNameCtrl.dispose();
    errorDescCtrl.dispose();
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
      final username =
          decoded["FoxconnID"] ??
              decoded["UserName"] ??
              decoded["sub"];

      if (username != null && !_disposed) {
        userCtrl.text = username.toString();
      }
    } catch (_) {}
  }

  // CAMERA

  Future<void> initCamera() async {
    if (_disposed || _cameraService.isDisposing || _initializingCamera)
      return;

    if (cameraController != null &&
        (cameraController?.value.isInitialized ?? false)) {
      return;
    }

    _initializingCamera = true;

    try {
      final initResult =
      await _cameraService.initializeCamera();
      if (_disposed) return;
      if (initResult == null) return;

      minZoom = initResult.minZoom;
      maxZoom = initResult.maxZoom;
      zoomLevel = initResult.zoomLevel;

      _safeUpdate(() {
        state = TestState.readyToCapture;
      });
    } finally {
      _initializingCamera = false;
      if (!_disposed) update();
    }
  }

  Future<void> capture() async {
    final result = await Get.to<XFile>(
          () => const CameraCaptureScreen(),
    );

    if (result != null) {
      captured.add(result);
      update();
    }
  }

  Future<void> zoomIn() async {
    if (cameraController == null) return;
    zoomLevel = min(maxZoom, zoomLevel + 0.2);
    await _cameraService.setZoomLevel(zoomLevel);
    if (!_disposed) update();
  }

  Future<void> zoomOut() async {
    if (cameraController == null) return;
    zoomLevel = max(minZoom, zoomLevel - 0.2);
    await _cameraService.setZoomLevel(zoomLevel);
    if (!_disposed) update();
  }

  // DROPDOWN

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

  void removeCapturedAt(int index) {
    if (index < 0 || index >= captured.length) return;
    captured.removeAt(index);
    update();
  }

  void setResult(String value) {
    result = value;

    if (result == "PASS") {
      errorCodeCtrl.clear();
      errorNameCtrl.clear();
      errorDescCtrl.clear();
      captured.clear();
    }

    update();
  }

  // IMAGE PICK

  Future<void> pickImagesFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (_disposed) return;

    final paths =
    result?.paths.whereType<String>().toList();
    if (paths == null || paths.isEmpty) return;

    _safeUpdate(() {
      for (final path in paths) {
        captured.add(XFile(path));
      }
      state = TestState.doneCapture;
    });
  }

  //  API

  Future<void> sendToApi(List<XFile> images) async {
    if (factoryCtrl.text.trim().isEmpty ||
        floorCtrl.text.trim().isEmpty ||
        stationCtrl.text.trim().isEmpty ||
        serialCtrl.text.trim().isEmpty) {
      Get.snackbar(
        "Lỗi",
        "Vui lòng nhập đầy đủ Factory / Floor / Station / Serial",
      );
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

    try {
      _safeUpdate(() => state = TestState.uploading);

      final payload = CapturePayload(
        factory: factoryCtrl.text.trim(),
        floor: floorCtrl.text.trim(),
        serialNumber: serialCtrl.text.trim(),
        station: stationCtrl.text.trim(),
        result: result,
        comment: noteCtrl.text.trim(),
        username: userCtrl.text.trim(),
        errorCode: result == "FAIL" ? errorCodeCtrl.text.trim() : "",
        errorName: result == "FAIL" ? errorNameCtrl.text.trim() : "",
        errorDescription:
        result == "FAIL" ? errorDescCtrl.text.trim() : "",
      );

      final response = await _captureApiService.sendCapture(
        payload: payload,
        images: images,
      );

      if (_disposed) return;

      final bodyJson = jsonDecode(response.body);
      final apiCode = bodyJson["Code"] ?? bodyJson["code"] ?? -1;
      final apiMessage =
          bodyJson["Message"] ?? bodyJson["message"] ?? "Unknown error";

      if (response.statusCode == 200 && apiCode == 0) {

        // RUNG PDA
        HapticFeedback.vibrate();

        Get.snackbar(
          "Thành công",
          apiMessage,
          snackPosition: SnackPosition.BOTTOM,
        );

        //  RESET FORM DATA
        captured.clear();
        serialCtrl.clear();
        noteCtrl.clear();
        errorCodeCtrl.clear();
        errorNameCtrl.clear();
        errorDescCtrl.clear();
        result = "PASS";

      } else {
        Get.snackbar(
          "Thông báo",
          apiMessage,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

    } catch (e) {
      if (!_disposed) {
        Get.snackbar("Upload lỗi", e.toString());
      }
    } finally {
      if (!_disposed) {
        _safeUpdate(() => state = TestState.idle);
      }
    }
  }
}