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
import 'package:smart_factory/config/bantha.dart';

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
  final stationCtrl = TextEditingController();
  final serialCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final errorCodeCtrl = TextEditingController();
  final errorNameCtrl = TextEditingController();
  final errorDescCtrl = TextEditingController();
  String result = "PASS";

// Xử lý Factory và Floor
  List<String> factories = [];
  List<String> floors = [];

  String? selectedFactory;
  String? selectedFloor;

  // URL API
  final String apiUrl = "http://192.168.0.117:2222/api/NVIDIA/SFCService/APP_PassVIStation";

  // Used to cancel delayed callbacks (auto-scan / rescan) when screen is disposed.
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

    factories = BanthaConfig.factories;

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
    stationCtrl.dispose();
    errorDescCtrl.dispose();
    serialCtrl.dispose();
    userCtrl.dispose();
    noteCtrl.dispose();
    errorCodeCtrl.dispose();
    errorNameCtrl.dispose();
    super.dispose();
  }


  // QR SCAN
  Future<void> scanQr() async {
    final int session = ++_scanSession;

    final qr = await Get.to(() => const ScanTestScreen());
    if (!mounted || _disposed || session != _scanSession) return;

    if (qr != null && qr["manual"] == true) {
      _enterManualSn();
      return;
    }

    if (qr == null) {
      if (_isScanMode) {
        _scanSession++;
        _safeSetState(() {
          _showCameraPreview = false;
          _hasScannedQr = false;
          _showScanForm = false;
          state = TestState.idle;
        });

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

    product = qr;
    serialCtrl.text = product?["serial"] ?? "";

    _safeSetState(() {
      _hasScannedQr = true;
      _showScanForm = true;
      _showCameraPreview = false;
      state = TestState.doneCapture;
    });
  }
  bool _initializingCamera = false;


  // MANUAL SN (Không quét được QR)
  void _enterManualSn() {
    _safeSetState(() {
      product = null;
      serialCtrl.clear();
      _hasScannedQr = true;
      _showScanForm = true;
      _showCameraPreview = false;
      state = TestState.doneCapture;
    });
  }

  // INIT CAMERA + ZOOM

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


  // ZOOM BUTTONS
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


  // CAPTURE
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

  void _openErrorCodeSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F13),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final searchCtrl = TextEditingController();
        List<ErrorItem> filtered = BanthaConfig.errorCodes;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void onSearch(String q) {
              setSheetState(() {
                final s = q.toLowerCase();
                filtered = BanthaConfig.errorCodes.where((e) {
                  return e.code.toLowerCase().contains(s) ||
                      e.name.toLowerCase().contains(s);
                }).toList();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      onChanged: onSearch,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Tìm Error Code / Error Name",
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                        const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        return ListTile(
                          title: Text(
                            e.code,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            e.name,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onTap: () {
                            setState(() {
                              errorCodeCtrl.text = e.code;
                              errorNameCtrl.text = e.name;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // CAMERA + ZOOM
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
                      // _imagePreviewStrip(),
                      // const SizedBox(height: 16),
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
                                  result = "PASS";
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
                              child: const Text("🚀 Gửi dữ liệu"),
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

  // Widget _imagePreviewStrip() {
  //   if (captured.isEmpty) {
  //     return Container(
  //       width: double.infinity,
  //       padding: const EdgeInsets.all(14),
  //       decoration: BoxDecoration(
  //         color: const Color(0xFF101014),
  //         borderRadius: BorderRadius.circular(14),
  //         border: Border.all(color: Colors.white.withOpacity(0.06)),
  //       ),
  //       child: const Text(
  //         "Chưa có ảnh. Nếu FAIL, vui lòng chụp hoặc chọn ảnh ở bên dưới.",
  //         style: TextStyle(color: Colors.white70),
  //       ),
  //     );
  //   }
  //
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.symmetric(vertical: 10),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF101014),
  //       borderRadius: BorderRadius.circular(14),
  //       border: Border.all(color: Colors.white.withOpacity(0.06)),
  //     ),
  //     child: SizedBox(
  //       height: 96,
  //       child: ListView.separated(
  //         padding: const EdgeInsets.symmetric(horizontal: 10),
  //         scrollDirection: Axis.horizontal,
  //         itemCount: captured.length,
  //         separatorBuilder: (_, __) => const SizedBox(width: 10),
  //         itemBuilder: (_, i) {
  //           return Stack(
  //             children: [
  //               GestureDetector(
  //                 onTap: () => Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (_) => FullImageView(path: captured[i].path),
  //                   ),
  //                 ),
  //                 child: ClipRRect(
  //                   borderRadius: BorderRadius.circular(10),
  //                   child: Image.file(
  //                     File(captured[i].path),
  //                     width: 96,
  //                     height: 96,
  //                     fit: BoxFit.cover,
  //                   ),
  //                 ),
  //               ),
  //               Positioned(
  //                 right: 6,
  //                 top: 6,
  //                 child: GestureDetector(
  //                   onTap: () => setState(() => captured.removeAt(i)),
  //                   child: Container(
  //                     padding: const EdgeInsets.all(4),
  //                     decoration: BoxDecoration(
  //                       color: Colors.black.withOpacity(0.55),
  //                       shape: BoxShape.circle,
  //                       border: Border.all(color: Colors.white.withOpacity(0.2)),
  //                     ),
  //                     child: const Icon(Icons.close, size: 14, color: Colors.white),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

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


  // FORM CONTENT

  Widget _formContent() {
    final bool isFail = result == "FAIL";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        //  IMAGE CARD
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFail ? const Color(0xFF1A0F0F) : const Color(0xFF0F1A12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFail
                  ? Colors.redAccent.withOpacity(0.6)
                  : Colors.greenAccent.withOpacity(0.5),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // HEADER
              Row(
                children: [
                  Text(
                    isFail
                        ? "Ảnh lỗi (bắt buộc khi FAIL)"
                        : "Ảnh kiểm tra",
                    style: TextStyle(
                      color: isFail ? Colors.redAccent : Colors.greenAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 10),

              // THUMBNAILS
              if (captured.isNotEmpty)
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: captured.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(captured[i].path),
                            width: 86,
                            height: 86,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => captured.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    isFail
                        ? "Chưa có ảnh. FAIL bắt buộc phải có ảnh."
                        : "Chưa có ảnh.",
                    style: TextStyle(
                      color: isFail
                          ? Colors.redAccent
                          : Colors.white70,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // ACTION BUTTONS
              _imageActionRow(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // PRODUCT INFO
        _sectionCard(
          title: "📦 Thông tin sản phẩm",
          child: Column(
            children: [
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
                        child: Text(
                          f,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          selectedFactory = val;
                          factoryCtrl.text = val;
                          floors = BanthaConfig.floorsOf(val);
                          selectedFloor = null;
                          floorCtrl.clear();
                          stationCtrl.clear();
                        });
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
                        child: Text(
                          f,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          selectedFloor = val;
                          floorCtrl.text = val;
                          stationCtrl.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: userCtrl,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white54),
                      decoration: _inputStyle("Username"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value:
                stationCtrl.text.isEmpty ? null : stationCtrl.text,
                decoration: _inputStyle("Station"),
                dropdownColor: Colors.black,
                items: BanthaConfig
                    .stationsOf(
                    selectedFactory ?? "", selectedFloor ?? "")
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s,
                    style:
                    const TextStyle(color: Colors.white),
                  ),
                ))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => stationCtrl.text = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: serialCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle("Serial Number"),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // RESULT
        _sectionCard(
          title: "🧪 Kết quả kiểm tra",
          highlightFail: isFail,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: result,
                decoration: _inputStyle("Result"),
                dropdownColor: Colors.black,
                items: const [
                  DropdownMenuItem(value: "PASS", child: Text("PASS")),
                  DropdownMenuItem(value: "FAIL", child: Text("FAIL")),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    result = v;
                    if (result == "PASS") {
                      errorCodeCtrl.clear();
                      errorNameCtrl.clear();
                      errorDescCtrl.clear();
                      captured.clear();
                    }
                  });
                },
              ),
              if (isFail) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _openErrorCodeSearch,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: errorCodeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle("Error Code").copyWith(
                        suffixIcon: const Icon(Icons.search, color: Colors.white54),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: errorNameCtrl,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white70),
                  decoration: _inputStyle("Error Name"),
                ),

                const SizedBox(height: 14),
                TextField(
                  controller: errorDescCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                  _inputStyle("Error Description"),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // COMMENT
        _sectionCard(
          title: "📝 Ghi chú",
          child: TextField(
            controller: noteCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: _inputStyle("Comment"),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    bool highlightFail = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlightFail
            ? const Color(0xFF1A0F0F)
            : const Color(0xFF101014),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlightFail
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: highlightFail
                      ? Colors.redAccent
                      : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
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
    if (!mounted || _disposed) return;
    _safeSetState(() {
      state = TestState.doneCapture;
    });
  }


  // SEND API
  Future<void> sendToApi(List<XFile> images) async {
    if (factoryCtrl.text.trim().isEmpty ||
        floorCtrl.text.trim().isEmpty ||
        stationCtrl.text.trim().isEmpty ||
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

    _safeSetState(() => state = TestState.uploading);

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse(apiUrl),
      );

      // Fields đúng DTO
      request.fields.addAll({
        "factory": factoryCtrl.text.trim(),
        "floor": floorCtrl.text.trim(),
        "serialNumber": serialCtrl.text.trim(),
        "station": stationCtrl.text.trim(),
        "result": result,
        "comment": noteCtrl.text.trim(),
        "username": userCtrl.text.trim(),
      });

      if (result == "FAIL") {
        request.fields["errorcode"] = errorCodeCtrl.text.trim();
        request.fields["errorname"] = errorNameCtrl.text.trim();
        request.fields["errordescription"] = errorDescCtrl.text.trim();

        for (final img in images) {
          request.files.add(
            await http.MultipartFile.fromPath(
              "images",
              img.path,
              filename: img.name,
            ),
          );
        }
      }

      final streamedRes = await request.send();
      final resBody = await streamedRes.stream.bytesToString();

      if (!mounted || _disposed) return;

      if (streamedRes.statusCode == 200) {
        Get.defaultDialog(
          title: "Thành công",
          content: const Text("Upload thành công"),
          textConfirm: "OK",
          onConfirm: () async {
            Get.back();

            if (!mounted || _disposed) return;

            await _disposeControllerSafe();
            if (!mounted || _disposed) return;

            // Reset form
            captured.clear();
            serialCtrl.clear();
            stationCtrl.clear();
            noteCtrl.clear();
            errorCodeCtrl.clear();
            errorDescCtrl.clear();
            result = "PASS";
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
        Get.snackbar(
          "API lỗi",
          "Code: ${streamedRes.statusCode}\n$resBody",
        );
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
              // _imagePreviewStrip(),
              // const SizedBox(height: 16),
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
                          result = "PASS";
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
                      child: const Text("🚀 Gửi dữ liệu"),
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
        result = "PASS";
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
