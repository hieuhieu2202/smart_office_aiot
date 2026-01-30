import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

  final String apiUrl = "http://192.168.0.74:9090/api/ProductCapture/upload";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fillUserFromToken();

    if (widget.autoScan) {
      Future.delayed(const Duration(milliseconds: 300), () => scanQr());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState stateLifecycle) {
    if (controller == null) return;
    if (stateLifecycle == AppLifecycleState.resumed) {
      if (!controller!.value.isInitialized) initCamera();
    }
  }

  Future<void> _fillUserFromToken() async {
    final token = TokenManager().civetToken.value;
    if (token.isEmpty) return;

    try {
      final decoded = JwtDecoder.decode(token);
      final username = decoded["FoxconnID"] ?? decoded["UserName"] ?? decoded["sub"];
      if (username != null) userCtrl.text = username.toString();
    } catch (_) {}
  }

  // -----------------------------------------------------
  // QR SCAN
  // -----------------------------------------------------
  Future<void> scanQr() async {
    final qr = await Get.to(() => const ScanTestScreen());
    if (qr == null) {
      Get.snackbar("Lỗi", "Không đọc được mã QR");
      return;
    }

    product = qr;
    serialCtrl.text = product?["serial"] ?? "";

    await initCamera();
    state = TestState.productDetected;
    setState(() {});
  }

  // -----------------------------------------------------
  // INIT CAMERA + ZOOM
  // -----------------------------------------------------
  Future<void> initCamera() async {
    try {
      final cams = await availableCameras();
      CameraDescription selected = cams.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();

      minZoom = await controller!.getMinZoomLevel();
      maxZoom = await controller!.getMaxZoomLevel();
      zoomLevel = 1.0;

      if (!mounted) return;

      setState(() => state = TestState.readyToCapture);
    } catch (e) {
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
    setState(() {});
  }

  Future<void> zoomOut() async {
    if (controller == null) return;
    zoomLevel = max(minZoom, zoomLevel - 0.2);
    await controller!.setZoomLevel(zoomLevel);
    setState(() {});
  }

  // -----------------------------------------------------
  // CAPTURE
  // -----------------------------------------------------
  Future<void> capture() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      final photo = await controller!.takePicture();
      captured.add(photo);
      setState(() => state = TestState.captured);
    } catch (e) {
      Get.snackbar("Chụp lỗi", e.toString());
    }
  }

  // -----------------------------------------------------
  // FINISH
  // -----------------------------------------------------
  void finishCapture() {
    setState(() => state = TestState.doneCapture);
  }

  // -----------------------------------------------------
  // SEND API
  // -----------------------------------------------------
  Future<void> sendToApi(List<XFile> images) async {
    if (status == "FAIL" && images.isEmpty) {
      Get.snackbar("Lỗi", "Chưa có ảnh");
      return;
    }
    if (status == "FAIL" && errorCodeCtrl.text.trim().isEmpty) {
      Get.snackbar("Lỗi", "Vui lòng nhập ErrorCode");
      return;
    }

    setState(() => state = TestState.uploading);

    try {
      final payload = {
        "Serial": serialCtrl.text,
        "Status": status,
        "UserName": userCtrl.text,
        "Time": DateTime.now().toIso8601String(),
        "Note": noteCtrl.text,
      };
      if (status == "FAIL") {
        List<String> listBase64 = [];

        for (var file in images) {
          final compressed = await FlutterImageCompress.compressWithFile(
            file.path,
            quality: 60,
          );

          listBase64.add(
            base64Encode(compressed ?? await File(file.path).readAsBytes()),
          );
        }

        payload["Images"] = listBase64;
      }

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        _successDialog();
      } else {
        Get.snackbar("API lỗi", "Code: ${res.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Upload lỗi", e.toString());
    }

    if (mounted) setState(() => state = TestState.doneCapture);
  }

  void _successDialog() {
    Get.defaultDialog(
      title: "Thành công",
      content: const Text("Upload thành công"),
      textConfirm: "OK",
      onConfirm: () async {
        Get.back();

        await controller?.dispose();
        controller = null;

        captured.clear();
        serialCtrl.clear();
        noteCtrl.clear();
        status = "PASS";
        product = null;

        setState(() => state = TestState.idle);

        await Future.delayed(const Duration(milliseconds: 250));
        await scanQr();
      },
    );
  }

  // -----------------------------------------------------
  // RESPONSIVE
  // -----------------------------------------------------
  bool isTablet(BuildContext context) => MediaQuery.of(context).size.width > 900;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0d0d11),
      appBar: AppBar(
        backgroundColor: const Color(0xff0d0d11),
        title: const Text("Capture"),
      ),
      body: SafeArea(
        child: isTablet(context) ? _tabletUI() : _phoneUI(),
      ),
    );
  }

  // -----------------------------------------------------
  // PHONE UI
  // -----------------------------------------------------
  Widget _phoneUI() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: _cameraUI()),
            _thumbnailRow(),
            _phoneButtons(),
          ],
        ),
        if (state == TestState.doneCapture) _formOverlay(),
        if (state == TestState.uploading)
          Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
      ],
    );
  }

  // -----------------------------------------------------
  // TABLET UI
  // -----------------------------------------------------
  Widget _tabletUI() {
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
        if (state == TestState.doneCapture) _formOverlay(),
        if (state == TestState.uploading)
          Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
      ],
    );
  }

  // -----------------------------------------------------
  // CAMERA + ZOOM
  // -----------------------------------------------------
  Widget _cameraUI() {
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
              if (controller == null) return;
              zoomLevel = (zoomLevel * details.scale).clamp(minZoom, maxZoom);
              await controller!.setZoomLevel(zoomLevel);

              setState(() {});
            },
            child: CameraPreview(controller!),
          ),
        ),

        // NÚT ZOOM + / -
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
          onPressed: () {
            if (captured.isEmpty) {
              Get.snackbar("Lỗi", "Chưa chụp ảnh");
              return;
            }
            finishCapture();
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
          onPressed: () {
            if (captured.isEmpty) {
              Get.snackbar("Lỗi", "Chưa chụp ảnh");
              return;
            }
            finishCapture();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: captured.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(captured[i].path),
                          width: 90, height: 90, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _formContent(),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      onPressed: () {
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => sendToApi(captured),
                      child: const Text("Gửi API"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formContent() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: factoryCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle("Factory"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: floorCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle("Floor"),
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
        const SizedBox(height: 12),

        TextField(
          controller: productNameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _inputStyle("ProductName"),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: modelCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _inputStyle("Model"),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: serialCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _inputStyle("Serial"),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: status,
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          decoration: _inputStyle("Status"),
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

        if (status == "FAIL") ...[
          TextField(
            controller: errorCodeCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _inputStyle("ErrorCode"),
          ),
          const SizedBox(height: 12),
        ],

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
