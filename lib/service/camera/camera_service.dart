import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// A thin wrapper around the [camera] plugin that exposes a
/// lazily-initialized [CameraController] for image capture scenarios and
/// captures the most recent error for UI feedback.
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = const [];
  CameraDescription? _activeCamera;
  ResolutionPreset _resolutionPreset = ResolutionPreset.medium;
  CameraException? _lastError;

  CameraController? get controller => _controller;

  List<CameraDescription> get cameras => _availableCameras;

  CameraDescription? get activeCamera => _activeCamera;

  CameraException? get lastError => _lastError;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Initializes the first available camera (or the requested one when
  /// provided). Returns `true` when the controller is ready and `false` when
  /// no camera could be prepared.
  Future<bool> initialize({
    CameraDescription? cameraDescription,
    ResolutionPreset preset = ResolutionPreset.medium,
  }) async {
    await dispose();

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        _lastError = CameraException('no_camera', 'No camera found');
        return false;
      }

      final targetCamera = cameraDescription ??
          _activeCamera ??
          _pickBestCamera(_availableCameras) ??
          _availableCameras.first;

      _activeCamera = targetCamera;
      _resolutionPreset = preset;

      final controller = CameraController(
        targetCamera,
        preset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;
      await controller.initialize();
      _lastError = null;
      return true;
    } on CameraException catch (error, stackTrace) {
      _lastError = error;
      _logCameraError('Camera initialization failed', error, stackTrace);
      await dispose();
      return false;
    } catch (error, stackTrace) {
      final cameraError = CameraException('init_failure', '$error');
      _lastError = cameraError;
      _logCameraError('Unexpected camera initialization error', cameraError, stackTrace);
      await dispose();
      return false;
    }
  }

  /// Attempts to reinitialize the controller using the last known camera and
  /// preset.
  Future<bool> refresh() {
    return initialize(
      cameraDescription: _activeCamera,
      preset: _resolutionPreset,
    );
  }

  /// Switches to a different camera description if available.
  Future<bool> switchCamera(CameraDescription camera) async {
    if (_availableCameras.isEmpty) {
      _availableCameras = await availableCameras();
    }

    if (!_availableCameras.contains(camera)) {
      return false;
    }

    return initialize(cameraDescription: camera, preset: _resolutionPreset);
  }

  /// Captures a single still image from the active camera.
  Future<XFile> capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      final error = CameraException(
        'not_initialized',
        'Camera has not been initialized',
      );
      _lastError = error;
      throw error;
    }

    if (controller.value.isTakingPicture) {
      final error = CameraException(
        'in_progress',
        'A capture is already in progress',
      );
      _lastError = error;
      throw error;
    }

    try {
      final file = await controller.takePicture();
      _lastError = null;
      return file;
    } on CameraException catch (error, stackTrace) {
      _lastError = error;
      _logCameraError('Camera capture failed', error, stackTrace);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _activeCamera = null;
    _availableCameras = const [];
  }

  CameraDescription? _pickBestCamera(List<CameraDescription> cameras) {
    CameraDescription? findByDirection(CameraLensDirection direction) {
      for (final camera in cameras) {
        if (camera.lensDirection == direction) {
          return camera;
        }
      }
      return null;
    }

    return findByDirection(CameraLensDirection.external) ??
        findByDirection(CameraLensDirection.back) ??
        findByDirection(CameraLensDirection.front);
  }

  void _logCameraError(
    String message,
    CameraException error,
    StackTrace stackTrace,
  ) {
    if (kDebugMode) {
      debugPrint('$message (${error.code}): ${error.description}');
      debugPrint('$stackTrace');
    }
  }
}
