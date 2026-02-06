import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:smart_factory/features/camera_test/model/capture_payload.dart';
import 'package:smart_factory/features/camera_test/service/camera_service.dart';
import 'package:smart_factory/features/camera_test/service/capture_api_service.dart';
import 'package:smart_factory/features/camera_test/service/scan_service.dart';
import 'package:smart_factory/service/auth/token_manager.dart';

enum TestState { idle, productDetected, readyToCapture, captured, doneCapture, uploading }

class CameraTestController extends GetxController {
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
  final productNameCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final serialCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final errorCodeCtrl = TextEditingController();
  String status = 'PASS';

  List<String> factories = [];
  List<String> floors = [];

  String? selectedFactory;
  String? selectedFloor;

  List<String> productNames = [];
  List<String> models = [];

  String? selectedProductName;
  String? selectedModel;

  bool _disposed = false;
  int _scanSession = 0;
  bool _disposingController = false;
  bool _initializingCamera = false;

  CameraController? get cameraController => _cameraService.controller;

  @override
  void onInit() {
    super.onInit();
    _fillUserFromToken();
    loadFactories();

    if (autoScan) {
      final int session = ++_scanSession;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_disposed || session != _scanSession) return;
        scanQr();
      });
    }
  }

  @override
  void onClose() {
    _disposed = true;
    factoryCtrl.dispose();
    floorCtrl.dispose();
    productNameCtrl.dispose();
    modelCtrl.dispose();
    serialCtrl.dispose();
    userCtrl.dispose();
    noteCtrl.dispose();
    errorCodeCtrl.dispose();
    _cameraService.dispose();
    super.onClose();
  }

  void safeUpdate() {
    if (!_disposed && !isClosed) {
      update();
    }
  }

  Future<void> _fillUserFromToken() async {
    final token = TokenManager().civetToken.value;
    if (token.isEmpty) return;

    try {
      final decoded = JwtDecoder.decode(token);
      final username = decoded['FoxconnID'] ?? decoded['UserName'] ?? decoded['sub'];
      if (username == null) return;
      if (_disposed) return;
      userCtrl.text = username.toString();
      safeUpdate();
    } catch (_) {
      // ignore invalid token
    }
  }

  Future<void> loadFactories() async {
    try {
      final res = await http.get(
        Uri.parse('http://192.168.0.62:2020/api/Data/factories'),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (_disposed) return;
        factories = data.cast<String>();
        safeUpdate();
      }
    } catch (e) {
      if (_disposed) return;
      Get.snackbar('Lỗi', 'Không load được Factory');
    }
  }

  Future<void> loadFloors(String factory) async {
    try {
      final res = await http.get(
        Uri.parse('http://192.168.0.62:2020/api/Data/floors?factory=$factory'),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (_disposed) return;
        floors = data.cast<String>();
        safeUpdate();
      }
    } catch (e) {
      if (_disposed) return;
      Get.snackbar('Lỗi', 'Không load được Floor');
    }
  }

  Future<void> loadProductNames({
    required String factory,
    required String floor,
  }) async {
    try {
      final res = await http.get(
        Uri.parse(
          'http://192.168.0.62:2020/api/Data/product-names'
          '?factory=$factory&floor=$floor',
        ),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (_disposed) return;
        productNames = data.cast<String>();
        safeUpdate();
      }
    } catch (e) {
      if (_disposed) return;
      Get.snackbar('Lỗi', 'Không load được ProductName');
    }
  }

  Future<void> loadModels({
    required String factory,
    required String floor,
    required String productName,
  }) async {
    try {
      final res = await http.get(
        Uri.parse(
          'http://192.168.0.62:2020/api/Data/models'
          '?factory=$factory&floor=$floor&productName=$productName',
        ),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (_disposed) return;
        models = data.cast<String>();
        safeUpdate();
      }
    } catch (e) {
      if (_disposed) return;
      Get.snackbar('Lỗi', 'Không load được Model');
    }
  }

  Future<void> scanQr() async {
    final int session = ++_scanSession;

    final qr = await _scanService.scanQr();
    if (_disposed || session != _scanSession) return;

    if (qr == null) {
      if (autoScan) {
        _scanSession++;
        showCameraPreview = false;
        hasScannedQr = false;
        showScanForm = false;
        state = TestState.idle;
        safeUpdate();
        Get.back();
        return;
      }

      Get.snackbar('Lỗi', 'Không đọc được mã QR');
      return;
    }

    product = qr;
    serialCtrl.text = product?['serial'] ?? '';

    hasScannedQr = true;
    showScanForm = true;
    showCameraPreview = false;
    state = TestState.doneCapture;
    safeUpdate();

    unawaited(loadFactories());
  }

  Future<void> initCamera() async {
    if (_disposed || _disposingController || _initializingCamera) return;
    if (_cameraService.isInitialized) return;

    _initializingCamera = true;

    try {
      final ok = await _cameraService.initialize(preset: ResolutionPreset.high);
      if (_disposed) return;

      if (!ok) {
        Get.snackbar('Camera lỗi', 'Không tìm thấy camera');
        return;
      }

      final controller = _cameraService.controller;
      if (controller == null || !controller.value.isInitialized) return;

      minZoom = await controller.getMinZoomLevel();
      maxZoom = await controller.getMaxZoomLevel();
      zoomLevel = 1.0;

      state = TestState.readyToCapture;
      safeUpdate();
    } catch (e) {
      if (_disposed) return;
      Get.snackbar('Camera lỗi', e.toString());

      if (autoScan) {
        showCameraPreview = false;
        showScanForm = true;
        safeUpdate();
      }
    } finally {
      _initializingCamera = false;
      if (!_disposed) {
        safeUpdate();
      }
    }
  }

  Future<void> zoomIn() async {
    final controller = _cameraService.controller;
    if (controller == null) return;
    zoomLevel = min(maxZoom, zoomLevel + 0.2);
    await controller.setZoomLevel(zoomLevel);
    safeUpdate();
  }

  Future<void> zoomOut() async {
    final controller = _cameraService.controller;
    if (controller == null) return;
    zoomLevel = max(minZoom, zoomLevel - 0.2);
    await controller.setZoomLevel(zoomLevel);
    safeUpdate();
  }

  Future<void> handleScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_disposed) return;

    zoomLevel = (zoomLevel * details.scale).clamp(minZoom, maxZoom);
    await controller.setZoomLevel(zoomLevel);
    safeUpdate();
  }

  Future<void> capture() async {
    if (autoScan) {
      if (!hasScannedQr) {
        await scanQr();
        return;
      }

      if (showCameraPreview) return;

      showCameraPreview = true;
      showScanForm = true;
      state = TestState.doneCapture;
      safeUpdate();

      if (!_cameraService.isInitialized) {
        await initCamera();
      }

      if (_disposed) return;
      if (!_cameraService.isInitialized) {
        showCameraPreview = false;
        safeUpdate();
      }
      return;
    }

    if (!_cameraService.isInitialized) return;

    try {
      final photo = await _cameraService.capturePhoto();
      if (_disposed) return;
      captured.add(photo);
      state = TestState.doneCapture;
      safeUpdate();
    } catch (e) {
      if (_disposed) return;
      Get.snackbar('Chụp lỗi', e.toString());
    }
  }

  Future<void> takePhotoFromPreview() async {
    if (!_cameraService.isInitialized) {
      showCameraPreview = false;
      safeUpdate();
      return;
    }

    try {
      final photo = await _cameraService.capturePhoto();
      if (_disposed) return;

      captured.add(photo);

      state = TestState.doneCapture;
      showCameraPreview = false;
      showScanForm = true;
      safeUpdate();
    } catch (e) {
      if (_disposed) return;
      Get.snackbar('Chụp lỗi', e.toString());

      showCameraPreview = false;
      showScanForm = true;
      safeUpdate();
    }
  }

  void closeCameraPreview() {
    showCameraPreview = false;
    if (autoScan) {
      showScanForm = hasScannedQr;
      state = hasScannedQr ? TestState.doneCapture : TestState.idle;
    }
    safeUpdate();
  }

  Future<void> pickImagesFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (_disposed) return;

    final paths = result?.paths.whereType<String>().toList();
    if (paths == null || paths.isEmpty) return;

    for (final path in paths) {
      captured.add(XFile(path));
    }
    state = TestState.doneCapture;
    safeUpdate();
  }

  Future<void> finishCapture() async {
    await loadFactories();
    if (_disposed) return;
    state = TestState.doneCapture;
    safeUpdate();
  }

  Future<void> sendToApi(List<XFile> images) async {
    if (serialCtrl.text.trim().isEmpty) {
      if (_disposed) return;
      Get.snackbar('Lỗi', 'Serial không được để trống');
      return;
    }

    if (status == 'FAIL') {
      if (errorCodeCtrl.text.trim().isEmpty) {
        if (_disposed) return;
        Get.snackbar('Lỗi', 'Vui lòng nhập ErrorCode');
        return;
      }
      if (images.isEmpty) {
        if (_disposed) return;
        Get.snackbar('Lỗi', 'FAIL phải có ít nhất 1 ảnh');
        return;
      }
    }

    state = TestState.uploading;
    safeUpdate();

    try {
      List<String>? listBase64;
      String? errorCode;

      if (status == 'FAIL') {
        listBase64 = [];
        for (final file in images) {
          final compressed = await FlutterImageCompress.compressWithFile(
            file.path,
            quality: 60,
          );

          listBase64.add(
            base64Encode(
              compressed ?? await File(file.path).readAsBytes(),
            ),
          );
        }
        errorCode = errorCodeCtrl.text.trim();
      }

      final payload = CapturePayload(
        factory: factoryCtrl.text.trim(),
        floor: floorCtrl.text.trim(),
        productName: productNameCtrl.text.trim(),
        model: modelCtrl.text.trim(),
        sn: serialCtrl.text.trim(),
        time: DateTime.now().toIso8601String(),
        userName: userCtrl.text.trim(),
        status: status,
        comment: noteCtrl.text.trim(),
        errorCode: errorCode,
        images: listBase64,
      );

      final res = await _captureApiService.send(payload);

      if (_disposed) return;

      if (res.statusCode == 200) {
        Get.defaultDialog(
          title: 'Thành công',
          content: const Text('Upload thành công'),
          textConfirm: 'OK',
          onConfirm: () async {
            Get.back();
            if (_disposed) return;

            await _cameraService.dispose();
            if (_disposed) return;

            captured.clear();
            serialCtrl.clear();
            noteCtrl.clear();
            errorCodeCtrl.clear();
            status = 'PASS';
            product = null;
            showCameraPreview = false;

            state = TestState.idle;
            hasScannedQr = false;
            showScanForm = false;
            safeUpdate();

            if (autoScan) {
              final int session = ++_scanSession;
              Future.delayed(const Duration(milliseconds: 250), () {
                if (_disposed || session != _scanSession) return;
                scanQr();
              });
            }
          },
        );
      } else {
        Get.snackbar('API lỗi', 'Code: ${res.statusCode}\n${res.body}');
      }
    } catch (e) {
      if (_disposed) return;
      Get.snackbar('Upload lỗi', e.toString());
    }

    state = TestState.doneCapture;
    safeUpdate();
  }

  void setStatus(String value) {
    status = value;
    safeUpdate();
  }

  void setSelectedFactory(String? value) {
    selectedFactory = value;
    factoryCtrl.text = value ?? '';
    selectedFloor = null;
    floors = [];
    selectedProductName = null;
    productNames = [];
    selectedModel = null;
    models = [];
    if (value != null) {
      unawaited(loadFloors(value));
    }
    safeUpdate();
  }

  void setSelectedFloor(String? value) {
    selectedFloor = value;
    floorCtrl.text = value ?? '';
    selectedProductName = null;
    productNames = [];
    selectedModel = null;
    models = [];
    if (value != null && selectedFactory != null) {
      unawaited(loadProductNames(factory: selectedFactory!, floor: value));
    }
    safeUpdate();
  }

  void setSelectedProductName(String? value) {
    selectedProductName = value;
    productNameCtrl.text = value ?? '';
    selectedModel = null;
    models = [];
    if (value != null && selectedFactory != null && selectedFloor != null) {
      unawaited(loadModels(
        factory: selectedFactory!,
        floor: selectedFloor!,
        productName: value,
      ));
    }
    safeUpdate();
  }

  void setSelectedModel(String? value) {
    selectedModel = value;
    modelCtrl.text = value ?? '';
    safeUpdate();
  }

  void removeCapturedAt(int index) {
    captured.removeAt(index);
    safeUpdate();
  }

  void resetCaptureState() {
    captured.clear();
    serialCtrl.clear();
    noteCtrl.clear();
    errorCodeCtrl.clear();
    status = 'PASS';
    state = TestState.idle;
    hasScannedQr = false;
    showScanForm = false;
    showCameraPreview = false;
    safeUpdate();
  }
}
