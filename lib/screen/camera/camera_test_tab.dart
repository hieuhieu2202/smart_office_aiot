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
  bool _hasScannedQr = false;
  bool _showScanForm = false;

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
      if (_isScanMode) {
        _scanSession++;
        _safeSetState(() {
          _showCameraPreview = false;
          _hasScannedQr = false;
          _showScanForm = false;
          state = TestState.idle;
        });

        // In scan mode: if user cancels scanning, just leave this page.
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

    // Mark that QR has been scanned so we never show the scan prompt again in this cycle.
    _safeSetState(() {
      _hasScannedQr = true;
      _showScanForm = true; // Always show form immediately after scan
      _showCameraPreview = false;
      state = TestState.doneCapture;
    });

    unawaited(loadFactories());
  }

  bool _initializingCamera = false;

  // -----------------------------------------------------
  // INIT CAMERA + ZOOM
  // -----------------------------------------------------
  Future<void> initCamera() async {
    if (!mounted || _disposed || _disposingController || _initializingCamera) return;

    // If a controller already exists and is initialized, reuse it.
    if (controller != null && (controller?.value.isInitialized ?? false)) {
      return;
    }

    _initializingCamera = true;

    try {
      final cams = await availableCameras();
      if (!mounted || _disposed) return;

      if (cams.isEmpty) {
        Get.snackbar("Camera lỗi", "Không tìm thấy camera");
        return;
      }

      final CameraDescription selected = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      // Dispose previous controller only if it exists AND is different / broken.
      await _disposeControllerSafe();
      if (!mounted || _disposed) return;

      final newController = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );

      controller = newController;

      await newController.initialize();
      if (!mounted || _disposed) return;

      minZoom = await newController.getMinZoomLevel();
      maxZoom = await newController.getMaxZoomLevel();
      zoomLevel = 1.0;

      if (!mounted || _disposed) return;
      setState(() {
        state = TestState.readyToCapture;
      });
    } catch (e) {
      if (!mounted || _disposed) return;
      Get.snackbar("Camera lỗi", e.toString());

      // If camera fails in scan mode, close preview and keep the form.
      if (_isScanMode) {
        _safeSetState(() {
          _showCameraPreview = false;
          _showScanForm = true;
        });
      }
    } finally {
      _initializingCamera = false;
      if (mounted && !_disposed) {
        setState(() {});
      }
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
    // Two-step UX in scan mode: open preview AFTER a successful QR scan.
    if (_isScanMode) {
      if (!_hasScannedQr) {
        await scanQr();
        return;
      }

      // If preview is already open, do nothing here (actual shutter is in preview).
      if (_showCameraPreview) return;

      _safeSetState(() {
        _showCameraPreview = true;
        _showScanForm = true;
        state = TestState.doneCapture;
      });

      // Ensure camera controller exists.
      if (controller == null || !(controller?.value.isInitialized ?? false)) {
        await initCamera();
      }

      // If init failed, close preview and go back to form.
      if (!mounted || _disposed) return;
      if (controller == null || !(controller?.value.isInitialized ?? false)) {
        _safeSetState(() => _showCameraPreview = false);
      }
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
    if (controller == null || !controller!.value.isInitialized) {
      // Can't capture -> go back to form.
      _safeSetState(() => _showCameraPreview = false);
      return;
    }

    try {
      final photo = await controller!.takePicture();
      if (!mounted || _disposed) return;

      captured.add(photo);

      // After taking a photo, always return to the form.
      _safeSetState(() {
        state = TestState.doneCapture;
        _showCameraPreview = false;
        _showScanForm = true;
      });

      // IMPORTANT: do NOT dispose the controller here.
      // Disposing on emulator often causes surface-abandoned and breaks subsequent captures.
    } catch (e) {
      if (!mounted || _disposed) return;
      Get.snackbar("Chụp lỗi", e.toString());

      // Even on error, return to the form (don't leave user stuck in preview).
      _safeSetState(() {
        _showCameraPreview = false;
        _showScanForm = true;
      });
    }
  }

  void _closeCameraPreview() {
    // Cancel preview -> return to form.
    _safeSetState(() {
      _showCameraPreview = false;
      if (_isScanMode) {
        _showScanForm = _hasScannedQr;
        state = _hasScannedQr ? TestState.doneCapture : TestState.idle;
      }
    });
  }

  // -----------------------------------------------------
  // CAMERA + ZOOM
  // -----------------------------------------------------
  Widget _cameraUI() {
    // Scan mode: before scan -> show prompt. After scan -> show stable background.
    if (_isScanMode && !_showCameraPreview) {
      if (!_hasScannedQr) {
        return const Center(
          child: Text(
            "Vui lòng quét QR để bắt đầu.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        );
      }
      return const ColoredBox(color: Color(0xff0d0d11));
    }

    if (_isScanMode && _showCameraPreview && _initializingCamera) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller == null || !(controller?.value.isInitialized ?? false)) {
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
                                  _safeSetState(() {
                                    state = TestState.idle;
                                    _hasScannedQr = false;
                                    _showScanForm = false;
                                  });
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
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullImageView(path: captured[i].path),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(captured[i].path),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
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

            _safeSetState(() {
              state = TestState.idle;
              _hasScannedQr = false;
              _showScanForm = false;
            });

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

  Widget _phoneUI() {
    final bool isScanMode = widget.autoScan;

    // In scan mode, NEVER show the form overlay on top of the camera preview.
    final bool showFormOverlay = isScanMode
        ? (!_showCameraPreview && ((state == TestState.doneCapture || state == TestState.captured) || _showScanForm))
        : (state == TestState.doneCapture || state == TestState.captured);

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
        if (showFormOverlay) _formOverlay(),
        if (state == TestState.uploading)
          Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _tabletUI() {
    final bool isScanMode = widget.autoScan;

    // In scan mode, NEVER show the form overlay on top of the camera preview.
    final bool showFormOverlay = isScanMode
        ? (!_showCameraPreview && ((state == TestState.doneCapture || state == TestState.captured) || _showScanForm))
        : (state == TestState.doneCapture || state == TestState.captured);

    if (isScanMode) {
      return Stack(
        children: [
          Positioned.fill(child: _cameraUI()),
          if (showFormOverlay) _formOverlay(),
          if (state == TestState.uploading)
            Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
        ],
      );
    }

    // Non-scan tablet UI: keep using the same camera UI + overlay states.
    return Stack(
      children: [
        Positioned.fill(child: _cameraUI()),
        if (showFormOverlay) _formOverlay(),
        if (state == TestState.uploading)
          Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
      ],
    );
  }

  /// Standalone form (no Positioned) to safely render as a normal page body.
  /// This is used in scan mode right after QR scanned to avoid the "black screen" issue.
  Widget _formStandalone() {
    return Container(
      color: Colors.black87,
      child: SafeArea(
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
                        if (_isScanMode) {
                          captured.clear();
                          errorCodeCtrl.clear();
                          noteCtrl.clear();
                          status = "PASS";
                          product = null;
                          serialCtrl.clear();
                          _safeSetState(() {
                            state = TestState.idle;
                            _hasScannedQr = false;
                            _showScanForm = false;
                            _showCameraPreview = false;
                          });

                          final int session = ++_scanSession;
                          Future.delayed(const Duration(milliseconds: 150), () {
                            if (!mounted || _disposed || session != _scanSession) return;
                            scanQr();
                          });
                          return;
                        }

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
    );
  }

  // Main content for scan mode AFTER scanning.
  // Render standalone form (no Positioned.fill) to guarantee it shows up.
  Widget _scanBody() {
    return Stack(
      children: [
        const ColoredBox(color: Color(0xff0d0d11)),
        _formStandalone(),
        if (state == TestState.uploading)
          Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
      ],
    );
  }

  // -----------------------------------------------------
  // RESPONSIVE + ROOT BUILD
  // -----------------------------------------------------
  bool isTablet(BuildContext context) => MediaQuery.of(context).size.width > 900;

  bool get _isBusy => state == TestState.uploading;

  Future<bool> _onWillPop() async {
    // Block leaving while uploading.
    if (_isBusy) return false;

    if (_isScanMode) {
      // If camera preview is open -> just close preview.
      if (_showCameraPreview) {
        _closeCameraPreview();
        return false;
      }

      // If form is visible (after scan), treat back as cancel -> go back to scan.
      if (_hasScannedQr || _showScanForm) {
        captured.clear();
        errorCodeCtrl.clear();
        noteCtrl.clear();
        status = "PASS";
        product = null;
        serialCtrl.clear();

        _safeSetState(() {
          state = TestState.idle;
          _hasScannedQr = false;
          _showScanForm = false;
        });

        final int session = ++_scanSession;
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted || _disposed || session != _scanSession) return;
          scanQr();
        });

        return false;
      }

      // Nothing started yet -> allow leaving.
      return true;
    }

    // Non-scan mode: allow normal pop.
    return true;
  }


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
          child: _isScanMode && _showScanForm && !_showCameraPreview
              ? _scanBody()
              : (isTablet(context) ? _tabletUI() : _phoneUI()),
        ),
      ),
    );
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
