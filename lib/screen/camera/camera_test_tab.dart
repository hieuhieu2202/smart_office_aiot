import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smart_factory/screen/home/widget/qr/scan_test_screen.dart';
import 'package:smart_factory/service/auth/token_manager.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class CameraTestTab extends StatefulWidget {
  final bool autoScan;
  const CameraTestTab({super.key, this.autoScan = false});

  @override
  State<CameraTestTab> createState() => _CameraTestTabState();
}

enum TestState { idle, productDetected, readyToCapture, captured, doneCapture, uploading }

class _CameraTestTabState extends State<CameraTestTab> with WidgetsBindingObserver {
  TestState state = TestState.idle;

  bool get _isScanMode => widget.autoScan;

  bool _showCameraPreview = false;

  Map<String, dynamic>? product;
  CameraController? controller;
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
  String status = "PASS";

// Xử lý Factory và Floor
  List<String> factories = [];
  List<String> floors = [];

  String? selectedFactory;
  String? selectedFloor;
// Xử lý ProductName và Model
  List<String> productNames = [];
  List<String> models = [];

  String? selectedProductName;
  String? selectedModel;
// Load Factory và Floor từ API
  Future<void> loadFactories() async {
    try {
      final res = await http.get(
        Uri.parse("http://192.168.0.62:2020/api/Data/factories"),
      );
      print("FACTORY API: ${res.body}");
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (!mounted || _disposed) return;
        setState(() {
          factories = data.cast<String>();
        });
      }
    } catch (e) {
      if (!mounted || _disposed) return;
      Get.snackbar("Lỗi", "Không load được Factory");
    }
  }
  Future<void> loadFloors(String factory) async {
    try {
      final res = await http.get(
        Uri.parse("http://192.168.0.62:2020/api/Data/floors?factory=$factory"),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (!mounted || _disposed) return;
        setState(() {
          floors = data.cast<String>();
        });
      }
    } catch (e) {
      if (!mounted || _disposed) return;
      Get.snackbar("Lỗi", "Không load được Floor");
    }
  }
  // Load ProductName và Model từ API
  Future<void> loadProductNames({
    required String factory,
    required String floor,
  }) async {
    try {
      final res = await http.get(
        Uri.parse(
          "http://192.168.0.62:2020/api/Data/product-names"
              "?factory=$factory&floor=$floor",
        ),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (!mounted || _disposed) return;
        setState(() {
          productNames = data.cast<String>();
        });
      }
    } catch (e) {
      if (!mounted || _disposed) return;
      Get.snackbar("Lỗi", "Không load được ProductName");
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
          "http://192.168.0.62:2020/api/Data/models"
              "?factory=$factory&floor=$floor&productName=$productName",
        ),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (!mounted || _disposed) return;
        setState(() {
          models = data.cast<String>();
        });
      }
    } catch (e) {
      if (!mounted || _disposed) return;
      Get.snackbar("Lỗi", "Không load được Model");
    }
  }

  // URL API upload
  final String apiUrl = "http://192.168.0.62:2020/api/Detail/upload";

  /// Used to cancel delayed callbacks (auto-scan / rescan) when screen is disposed.
  bool _disposed = false;
  int _scanSession = 0;

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _disposed) return;
    setState(fn);
  }

  Future<void> _fillUserFromToken() async {
    final token = TokenManager().civetToken.value;
    if (token.isEmpty) return;

    try {
      final decoded = JwtDecoder.decode(token);
      final username = decoded["FoxconnID"] ?? decoded["UserName"] ?? decoded["sub"];
      if (username == null) return;
      if (!mounted || _disposed) return;
      userCtrl.text = username.toString();
    } catch (_) {
      // ignore invalid token
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fillUserFromToken();
    loadFactories();

    if (widget.autoScan) {
      final int session = ++_scanSession;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || _disposed || session != _scanSession) return;
        scanQr();
      });
    }
  }

  bool _disposingController = false;

  Future<void> _disposeControllerSafe() async {
    final c = controller;
    if (c == null) return;

    controller = null;
    _disposingController = true;

    try {
      if (c.value.isStreamingImages) {
        await c.stopImageStream();
      }
    } catch (_) {
      // ignore
    }

    try {
      await c.dispose();
    } catch (_) {
      // ignore
    }

    _disposingController = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _scanSession++;
    WidgetsBinding.instance.removeObserver(this);

    // Dispose camera controller safely to avoid surface/GL callbacks after route is gone.
    // Fire-and-forget is OK here because widget is being disposed.
    _disposeControllerSafe();

    factoryCtrl.dispose();
    floorCtrl.dispose();
    productNameCtrl.dispose();
    modelCtrl.dispose();
    serialCtrl.dispose();
    userCtrl.dispose();
    noteCtrl.dispose();
    errorCodeCtrl.dispose();
    super.dispose();
  }

  // -----------------------------------------------------
  // QR SCAN
  // -----------------------------------------------------
  Future<void> scanQr() async {
    final int session = ++_scanSession;

    final qr = await Get.to(() => const ScanTestScreen());
    if (!mounted || _disposed || session != _scanSession) return;

    if (qr == null) {
      // User likely pressed back / closed scanner. In auto-scan flow,
      // we don't want to stay on this screen showing an empty placeholder.
      if (_isScanMode) {
        // Prevent any pending actions from re-opening scan.
        _scanSession++;
        _safeSetState(() {
          _showCameraPreview = false;
          state = TestState.idle;
        });
        await _disposeControllerSafe();

        // Close this tab/screen.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Get.back();
        }
        return;
      }

      Get.snackbar("Lỗi", "Không đọc được mã QR");
      return;
    }

    // 1) set product + fill serial
    product = qr;
    serialCtrl.text = product?["serial"] ?? "";

    // 2) Immediately move to the next UI (form overlay) and load needed data there.
    // Do NOT force camera init here; user can choose Capture/Choose image in the form.
    _safeSetState(() {
      state = TestState.doneCapture;
    });

    // Load lists for dropdowns (async) – safe guards are inside loadFactories().
    unawaited(loadFactories());
  }

  // -----------------------------------------------------
  // INIT CAMERA + ZOOM
  // -----------------------------------------------------
  Future<void> initCamera() async {
    if (!mounted || _disposed || _disposingController) return;

    try {
      final cams = await availableCameras();
      if (!mounted || _disposed) return;

      CameraDescription selected = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      // Ensure any previous controller is fully disposed before creating a new one.
      await _disposeControllerSafe();
      if (!mounted || _disposed) return;

      controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();
      if (!mounted || _disposed) return;

      minZoom = await controller!.getMinZoomLevel();
      maxZoom = await controller!.getMaxZoomLevel();
      zoomLevel = 1.0;

      if (!mounted || _disposed) return;
      setState(() => state = TestState.readyToCapture);
    } catch (e) {
      if (!mounted || _disposed) return;
      Get.snackbar("Camera lỗi", e.toString());
    }
  }

  // -----------------------------------------------------
  // ZOOM BUTTONS
  // -----------------------------------------------------
  Future<void> zoomIn() async {
    if (controller == null) return;
    zoomLevel = min(maxZoom, zoomLevel + 0.2);
    await controller!.setZoomLevel(zoomLevel);
    if (!mounted || _disposed) return;
    setState(() {});
  }

  Future<void> zoomOut() async {
    if (controller == null) return;
    zoomLevel = max(minZoom, zoomLevel - 0.2);
    await controller!.setZoomLevel(zoomLevel);
    if (!mounted || _disposed) return;
    setState(() {});
  }

  // -----------------------------------------------------
  // CAPTURE
  // -----------------------------------------------------
  Future<void> capture() async {
    // Two-step UX: first tap opens camera preview, second tap (shutter) takes the photo.
    if (_isScanMode) {
      if (!_showCameraPreview) {
        _safeSetState(() => _showCameraPreview = true);
      }

      if (controller == null || !controller!.value.isInitialized) {
        await initCamera();
        if (!mounted || _disposed) return;
      }

      // Do NOT auto-take picture in scan mode on first tap.
      return;
    }

    // Normal mode keeps old behavior.
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      final photo = await controller!.takePicture();
      if (!mounted || _disposed) return;
      captured.add(photo);
      setState(() => state = TestState.doneCapture);
    } catch (e) {
      if (!mounted || _disposed) return;
      Get.snackbar("Chụp lỗi", e.toString());
    }
  }

  Future<void> _takePhotoFromPreview() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      final photo = await controller!.takePicture();
      if (!mounted || _disposed) return;
      captured.add(photo);
      _safeSetState(() {
        state = TestState.doneCapture;
        _showCameraPreview = false;
      });

      // After taking a photo, we can dispose camera to avoid emulator issues.
      await _disposeControllerSafe();
    } catch (e) {
      if (!mounted || _disposed) return;
      Get.snackbar("Chụp lỗi", e.toString());
    }
  }

  void _closeCameraPreview() {
    _safeSetState(() => _showCameraPreview = false);
    _disposeControllerSafe();
  }


  // -----------------------------------------------------
  // RESPONSIVE
  // -----------------------------------------------------
  bool isTablet(BuildContext context) => MediaQuery.of(context).size.width > 900;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isBusy,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final allow = await _onWillPop();
        if (allow && mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xff0d0d11),
        appBar: AppBar(
          backgroundColor: const Color(0xff0d0d11),
          title: const Text("Capture"),
        ),
        body: SafeArea(
          child: isTablet(context) ? _tabletUI() : _phoneUI(),
        ),
      ),
    );
  }

  bool get _isBusy => state == TestState.uploading;

  Future<bool> _onWillPop() async {
    // Block leaving while uploading to avoid half-sent data / state corruption.
    if (_isBusy) return false;

    // In scan mode, handle back in a predictable way.
    if (_isScanMode) {
      // If camera preview is open -> close preview only.
      if (_showCameraPreview) {
        _closeCameraPreview();
        return false;
      }

      // If form overlay is open -> treat back like "Hủy" in scan mode: go back to scanner.
      if (state == TestState.doneCapture || state == TestState.captured) {
        captured.clear();
        errorCodeCtrl.clear();
        noteCtrl.clear();
        status = "PASS";
        product = null;
        serialCtrl.clear();
        _safeSetState(() => state = TestState.idle);
        await _disposeControllerSafe();

        final int session = ++_scanSession;
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted || _disposed || session != _scanSession) return;
          scanQr();
        });
        return false;
      }

      // If we're on this tab with nothing yet, allow pop.
      return true;
    }

    // Non-scan mode: allow normal pop.
    return true;
  }

  // -----------------------------------------------------
  // PHONE UI
  // -----------------------------------------------------
  Widget _phoneUI() {
    final bool isScanMode = widget.autoScan;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: _cameraUI()),

            // In scan mode, hide capture thumbnails + buttons to avoid confusing UI.
            if (!isScanMode) ...[
              _thumbnailRow(),
              _phoneButtons(),
            ],
          ],
        ),
        if (state == TestState.doneCapture || state == TestState.captured) _formOverlay(),
        if (state == TestState.uploading)
          Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
      ],
    );
  }

  // -----------------------------------------------------
  // TABLET UI
  // -----------------------------------------------------
  Widget _tabletUI() {
    final bool isScanMode = widget.autoScan;

    // When scanning, render a simple full camera view.
    if (isScanMode) {
      return Stack(
        children: [
          Positioned.fill(child: _cameraUI()),
          if (state == TestState.doneCapture || state == TestState.captured) _formOverlay(),
          if (state == TestState.uploading)
            Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
        ],
      );
    }

    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _cameraUI(),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(child: _thumbnailGrid()),
                  const SizedBox(height: 12),
                  _tabletButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
        if (state == TestState.doneCapture || state == TestState.captured) _formOverlay(),
        if (state == TestState.uploading)
          Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
      ],
    );
  }

  // -----------------------------------------------------
  // CAMERA + ZOOM
  // -----------------------------------------------------
  Widget _cameraUI() {
    // In scan mode, before scanning (state idle) show a more accurate instruction.
    if (_isScanMode && !_showCameraPreview && state == TestState.idle) {
      return const Center(
        child: Text(
          "Vui lòng quét QR để bắt đầu.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // In scan mode after scanned but before opening preview show the correct instruction.
    if (_isScanMode && !_showCameraPreview && state != TestState.idle) {
      return const Center(
        child: Text(
          "Quét QR xong. Vui lòng nhập thông tin và chọn Chụp ảnh/Chọn ảnh ở bên dưới.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    if (controller == null || !controller!.value.isInitialized) {
      return const Center(
        child: Text("Đang khởi tạo camera...", style: TextStyle(color: Colors.white70)),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onScaleUpdate: (details) async {
              if (controller == null || !controller!.value.isInitialized) return;
              if (!mounted || _disposed) return;

              zoomLevel = (zoomLevel * details.scale).clamp(minZoom, maxZoom);
              await controller!.setZoomLevel(zoomLevel);

              if (!mounted || _disposed) return;
              setState(() {});
            },
            child: CameraPreview(controller!),
          ),
        ),

        // Scan mode preview controls (close + shutter)
        if (_isScanMode && _showCameraPreview) ...[
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              tooltip: "Đóng camera",
              onPressed: _closeCameraPreview,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePhotoFromPreview,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
          ),
        ],

        // NÚT ZOOM + / -
        if (!_isScanMode || !_showCameraPreview)
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                _zoomBtn(Icons.add, zoomIn),
                const SizedBox(height: 10),
                _zoomBtn(Icons.remove, zoomOut),
              ],
            ),
          ),
      ],
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // -----------------------------------------------------
  // THUMBNAILS – PHONE
  // -----------------------------------------------------
  Widget _thumbnailRow() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: captured.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.all(6),
          child: _thumbnail(i, 80),
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // THUMBNAILS – TABLET GRID
  // -----------------------------------------------------
  Widget _thumbnailGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: captured.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) => Center(
        child: _thumbnail(i, 130), // Force thumbnail fixed size
      ),
    );
  }

  // -----------------------------------------------------
  // THUMBNAIL ITEM
  // -----------------------------------------------------
  Widget _thumbnail(int i, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FullImageView(path: captured[i].path)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(captured[i].path),
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => setState(() => captured.removeAt(i)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------
  // BUTTONS – PHONE
  // -----------------------------------------------------
  Widget _phoneButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: "btn_cancel_phone",
          backgroundColor: Colors.red,
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.close),
        ),
        FloatingActionButton(
          heroTag: "btn_capture_phone",
          backgroundColor: Colors.blue,
          onPressed: capture,
          child: const Icon(Icons.camera_alt),
        ),
        FloatingActionButton(
          heroTag: "btn_done_phone",
          backgroundColor: Colors.green,
          onPressed: () async {
            if (captured.isEmpty) {
              Get.snackbar("Lỗi", "Chưa chụp ảnh");
              return;
            }
            await finishCapture();
          },
          child: const Icon(Icons.check),
        ),
      ],
    );
  }

  // -----------------------------------------------------
  // BUTTONS – TABLET
  // -----------------------------------------------------
  Widget _tabletButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: "btn_cancel_tablet",
          backgroundColor: Colors.red,
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.close),
        ),
        FloatingActionButton(
          heroTag: "btn_capture_tablet",
          backgroundColor: Colors.blue,
          onPressed: capture,
          child: const Icon(Icons.camera_alt),
        ),
        FloatingActionButton(
          heroTag: "btn_done_tablet",
          backgroundColor: Colors.green,
          onPressed: () async {
            if (captured.isEmpty) {
              Get.snackbar("Lỗi", "Chưa chụp ảnh");
              return;
            }
            await finishCapture();
          },
          child: const Icon(Icons.check),
        ),
      ],
    );
  }

  // -----------------------------------------------------
  // FORM OVERLAY
  // -----------------------------------------------------
  Widget _formOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: SafeArea(
          child: Stack(
            children: [
              // Content
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      _imagePreviewStrip(),
                      const SizedBox(height: 16),
                      _formContent(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade800,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                // In scan mode: cancel should go back to scanning (not to camera/placeholder).
                                if (_isScanMode) {
                                  captured.clear();
                                  errorCodeCtrl.clear();
                                  noteCtrl.clear();
                                  status = "PASS";
                                  product = null;
                                  serialCtrl.clear();
                                  _safeSetState(() => state = TestState.idle);
                                  _disposeControllerSafe();
                                  final int session = ++_scanSession;
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    if (!mounted || _disposed || session != _scanSession) return;
                                    scanQr();
                                  });
                                  return;
                                }

                                // Normal mode behavior.
                                captured.clear();
                                state = TestState.readyToCapture;
                                initCamera();
                                setState(() {});
                              },
                              child: const Text("Hủy"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => sendToApi(captured),
                              child: const Text("Gửi API"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // NOTE: Removed the top-right close (X) button as requested.
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePreviewStrip() {
    if (captured.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF101014),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: const Text(
          "Chưa có ảnh. Nếu FAIL, vui lòng chụp hoặc chọn ảnh ở bên dưới.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          scrollDirection: Axis.horizontal,
          itemCount: captured.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(captured[i].path),
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => captured.removeAt(i)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _imageActionRow() {
    final caption = captured.isEmpty
        ? "Chưa có ảnh"
        : "Đã thêm ${captured.length} ảnh";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(caption, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: capture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Chụp ảnh"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: pickImagesFromDevice,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Chọn ảnh"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------
  // FORM CONTENT
  // -----------------------------------------------------
  Widget _formContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------- ROW: FACTORY / FLOOR / USER ----------
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedFactory,
                decoration: _inputStyle("Factory"),
                dropdownColor: Colors.black,
                items: factories
                    .map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(f,
                      style: const TextStyle(color: Colors.white)),
                ))
                    .toList(),
                onChanged: (val) async {
                  if (val == null) return;

                  setState(() {
                    selectedFactory = val;
                    factoryCtrl.text = val;

                    selectedFloor = null;
                    selectedProductName = null;
                    selectedModel = null;

                    floorCtrl.clear();
                    productNameCtrl.clear();
                    modelCtrl.clear();

                    floors = [];
                    productNames = [];
                    models = [];
                  });

                  await loadFloors(val);
                },
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedFloor,
                decoration: _inputStyle("Floor"),
                dropdownColor: Colors.black,
                items: floors
                    .map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(f,
                      style: const TextStyle(color: Colors.white)),
                ))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;

                  setState(() {
                    selectedFloor = val;
                    floorCtrl.text = val;

                    selectedProductName = null;
                    selectedModel = null;
                    productNameCtrl.clear();
                    modelCtrl.clear();
                    productNames = [];
                    models = [];
                  });

                  loadProductNames(
                    factory: selectedFactory!,
                    floor: val,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              flex: 3,
              child: TextField(
                controller: userCtrl,
                readOnly: true,
                style: const TextStyle(color: Colors.white70),
                decoration: _inputStyle("Người thực hiện"),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ---------- PRODUCT NAME ----------
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: selectedProductName,
          decoration: _inputStyle("ProductName"),
          dropdownColor: Colors.black,
          items: productNames
              .map((p) => DropdownMenuItem(
            value: p,
            child: Text(p,
                style: const TextStyle(color: Colors.white)),
          ))
              .toList(),
          onChanged: productNames.isEmpty
              ? null
              : (val) {
            if (val == null) return;

            setState(() {
              selectedProductName = val;
              productNameCtrl.text = val;

              selectedModel = null;
              modelCtrl.clear();
              models = [];
            });

            loadModels(
              factory: selectedFactory!,
              floor: selectedFloor!,
              productName: val,
            );
          },
        ),

        const SizedBox(height: 14),

        // ---------- MODEL ----------
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: selectedModel,
          decoration: _inputStyle("Model"),
          dropdownColor: Colors.black,
          items: models
              .map((m) => DropdownMenuItem(
            value: m,
            child: Text(m,
                style: const TextStyle(color: Colors.white)),
          ))
              .toList(),
          onChanged: models.isEmpty
              ? null
              : (val) {
            if (val == null) return;
            setState(() {
              selectedModel = val;
              modelCtrl.text = val;
            });
          },
        ),

        const SizedBox(height: 14),

        // ---------- SERIAL ----------
        TextField(
          controller: serialCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _inputStyle("Serial"),
        ),

        const SizedBox(height: 14),

        // ---------- STATUS ----------
        DropdownButtonFormField<String>(
          value: status,
          decoration: _inputStyle("Status"),
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(value: "PASS", child: Text("PASS")),
            DropdownMenuItem(value: "FAIL", child: Text("FAIL")),
          ],
          onChanged: (v) => setState(() {
            status = v!;
            if (status == "PASS") {
              errorCodeCtrl.clear();
              captured.clear();
            }
          }),
        ),

        const SizedBox(height: 12),
        _imageActionRow(),

        if (status == "FAIL") ...[
          const SizedBox(height: 14),
          TextField(
            controller: errorCodeCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _inputStyle("ErrorCode"),
          ),
        ],

        const SizedBox(height: 14),

        // ---------- NOTE ----------
        TextField(
          controller: noteCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: _inputStyle("Ghi chú"),
        ),
      ],
    );
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF111111),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> pickImagesFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (!mounted || _disposed) return;

    final paths = result?.paths.whereType<String>().toList();
    if (paths == null || paths.isEmpty) return;

    _safeSetState(() {
      for (final path in paths) {
        captured.add(XFile(path));
      }
      state = TestState.doneCapture;
    });
  }

  // FINISH (used by old non-scan capture flow)
  Future<void> finishCapture() async {
    await loadFactories();
    if (!mounted || _disposed) return;
    _safeSetState(() {
      state = TestState.doneCapture;
    });
  }

  // SEND API
  Future<void> sendToApi(List<XFile> images) async {
    if (serialCtrl.text.trim().isEmpty) {
      if (!mounted || _disposed) return;
      Get.snackbar("Lỗi", "Serial không được để trống");
      return;
    }

    if (status == "FAIL") {
      if (errorCodeCtrl.text.trim().isEmpty) {
        if (!mounted || _disposed) return;
        Get.snackbar("Lỗi", "Vui lòng nhập ErrorCode");
        return;
      }
      if (images.isEmpty) {
        if (!mounted || _disposed) return;
        Get.snackbar("Lỗi", "FAIL phải có ít nhất 1 ảnh");
        return;
      }
    }

    _safeSetState(() => state = TestState.uploading);

    try {
      final Map<String, dynamic> payload = {
        "factory": factoryCtrl.text.trim(),
        "floor": floorCtrl.text.trim(),
        "productName": productNameCtrl.text.trim(),
        "model": modelCtrl.text.trim(),
        "sn": serialCtrl.text.trim(),
        "time": DateTime.now().toIso8601String(),
        "userName": userCtrl.text.trim(),
        "status": status,
        "comment": noteCtrl.text.trim(),
      };

      if (status == "FAIL") {
        final List<String> listBase64 = [];

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

        payload["errorCode"] = errorCodeCtrl.text.trim();
        payload["images"] = listBase64;
      }

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (!mounted || _disposed) return;

      if (res.statusCode == 200) {
        Get.defaultDialog(
          title: "Thành công",
          content: const Text("Upload thành công"),
          textConfirm: "OK",
          onConfirm: () async {
            Get.back();
            if (!mounted || _disposed) return;

            await _disposeControllerSafe();
            if (!mounted || _disposed) return;

            captured.clear();
            serialCtrl.clear();
            noteCtrl.clear();
            errorCodeCtrl.clear();
            status = "PASS";
            product = null;
            _showCameraPreview = false;

            _safeSetState(() => state = TestState.idle);

            if (_isScanMode) {
              final int session = ++_scanSession;
              Future.delayed(const Duration(milliseconds: 250), () {
                if (!mounted || _disposed || session != _scanSession) return;
                scanQr();
              });
            }
          },
        );
      } else {
        Get.snackbar("API lỗi", "Code: ${res.statusCode}\n${res.body}");
      }
    } catch (e) {
      if (!mounted || _disposed) return;
      Get.snackbar("Upload lỗi", e.toString());
    }

    _safeSetState(() => state = TestState.doneCapture);
  }
}

// ---------------------------------------------------------
// VIEW FULL IMAGE
// ---------------------------------------------------------
class FullImageView extends StatelessWidget {
  final String path;
  const FullImageView({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}
