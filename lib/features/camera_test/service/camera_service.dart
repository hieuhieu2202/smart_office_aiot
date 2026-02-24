import 'package:camera/camera.dart';
import 'package:get/get.dart';

class CameraInitResult {
  final double minZoom;
  final double maxZoom;
  final double zoomLevel;

  const CameraInitResult({
    required this.minZoom,
    required this.maxZoom,
    required this.zoomLevel,
  });
}

class CameraService {
  CameraController? _controller;
  bool _disposingController = false;

  CameraController? get controller => _controller;
  bool get isDisposing => _disposingController;

  Future<void> disposeControllerSafe() async {
    final c = _controller;
    if (c == null) return;

    _controller = null;
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

  Future<CameraInitResult?> initializeCamera() async {
    if (_disposingController) return null;

    if (_controller != null && (_controller?.value.isInitialized ?? false)) {
      return CameraInitResult(
        minZoom: await _controller!.getMinZoomLevel(),
        maxZoom: await _controller!.getMaxZoomLevel(),
        zoomLevel: 1.0,
      );
    }

    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        Get.snackbar("Camera lỗi", "Không tìm thấy camera");
        return null;
      }

      final CameraDescription selected = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      await disposeControllerSafe();

      final newController = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _controller = newController;
      await newController.initialize();

      final minZoom = await newController.getMinZoomLevel();
      final maxZoom = await newController.getMaxZoomLevel();

      return CameraInitResult(minZoom: minZoom, maxZoom: maxZoom, zoomLevel: 1.0);
    } catch (e) {
      Get.snackbar("Camera lỗi", e.toString());
      return null;
    }
  }

  Future<XFile?> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    return _controller!.takePicture();
  }

  Future<void> setZoomLevel(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.setZoomLevel(zoom);
  }
}
