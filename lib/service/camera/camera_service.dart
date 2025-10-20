import 'package:camera/camera.dart';

/// A thin wrapper around the [camera] plugin that exposes a
/// lazily-initialized [CameraController] for image capture scenarios.
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = const [];

  CameraController? get controller => _controller;

  List<CameraDescription> get cameras => _availableCameras;

  /// Initializes the first available camera.
  Future<void> initialize() async {
    _availableCameras = await availableCameras();
    if (_availableCameras.isEmpty) {
      throw const CameraException('no_camera', 'No camera found');
    }

    final camera = _availableCameras.first;
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;
    await controller.initialize();
  }

  /// Captures a single still image from the active camera.
  Future<XFile> capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const CameraException(
        'not_initialized',
        'Camera has not been initialized',
      );
    }
    if (controller.value.isTakingPicture) {
      throw const CameraException(
        'in_progress',
        'A capture is already in progress',
      );
    }
    return controller.takePicture();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _availableCameras = const [];
  }
}
