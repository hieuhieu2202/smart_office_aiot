import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = const [];
  CameraDescription? _activeCamera;
  ResolutionPreset _resolutionPreset = ResolutionPreset.medium;
  CameraException? _lastError;
  Future<void>? _initializingFuture;

  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => List.unmodifiable(_availableCameras);
  CameraDescription? get activeCamera => _activeCamera;
  CameraException? get lastError => _lastError;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Initialize camera safely — ensures previous controller is fully disposed first
  Future<bool> initialize({
    CameraDescription? cameraDescription,
    ResolutionPreset preset = ResolutionPreset.medium,
  }) async {
    // tránh gọi song song nhiều lần
    if (_initializingFuture != null) await _initializingFuture;

    final completer = Completer<void>();
    _initializingFuture = completer.future;

    try {
      // 🔸 Dispose controller cũ thật sự trước khi tạo mới
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final discoveredCameras = await availableCameras();
      if (discoveredCameras.isEmpty) {
        _lastError = CameraException('no_camera', 'No camera found');
        return false;
      }

      _availableCameras = List.unmodifiable(discoveredCameras..sort(_compareCameras));

      final targetCamera = cameraDescription ??
          _activeCamera ??
          _pickBestCamera(_availableCameras) ??
          _availableCameras.first;

      _activeCamera = targetCamera;
      final presetsToTry = _presetsInPriorityOrder(preset);

      for (final p in presetsToTry) {
        try {
          final controller = CameraController(
            targetCamera,
            p,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );
          await controller.initialize();
          _controller = controller;
          _resolutionPreset = p;
          _lastError = null;
          return true;
        } on CameraException catch (e, st) {
          _lastError = e;
          _logCameraError('Init failed', e, st);
          await _controller?.dispose();
          _controller = null;

          if (e.description?.contains('already exists') ?? false) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }
      }
      return false;
    } catch (e, st) {
      final err = CameraException('init_failure', '$e');
      _lastError = err;
      _logCameraError('Unexpected init error', err, st);
      await _disposeController(preserveCameraCache: true);
      return false;
    } finally {
      completer.complete();
      _initializingFuture = null;
    }
  }

  Future<bool> refresh() =>
      initialize(cameraDescription: _activeCamera, preset: _resolutionPreset);

  Future<bool> switchCamera(CameraDescription camera) async {
    if (_availableCameras.isEmpty) {
      final discovered = await availableCameras();
      _availableCameras = List.unmodifiable(discovered..sort(_compareCameras));
    }
    if (!_availableCameras.contains(camera)) return false;
    return initialize(cameraDescription: camera, preset: _resolutionPreset);
  }

  Future<XFile> capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw CameraException('not_initialized', 'Camera not initialized');
    }
    if (controller.value.isTakingPicture) {
      throw CameraException('in_progress', 'Capture already in progress');
    }

    try {
      final file = await controller.takePicture();

      try {
        final bytes = await file.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final shouldFlip = controller.description.lensDirection ==
                  CameraLensDirection.front ||
              controller.description.lensDirection ==
                  CameraLensDirection.external;

          final processed = shouldFlip ? img.flipHorizontal(decoded) : decoded;
          final encoded = img.encodeJpg(processed);
          await file.writeAsBytes(encoded, flush: true);
        }
      } catch (e, st) {
        debugPrint('Failed to post-process captured image: $e');
        debugPrint('$st');
      }

      _lastError = null;
      return file;
    } on CameraException catch (e, st) {
      _lastError = e;
      _logCameraError('Capture failed', e, st);
      rethrow;
    }
  }

  Future<void> dispose({bool clearCache = true}) async {
    await _disposeController(preserveCameraCache: !clearCache);
    if (clearCache) {
      _activeCamera = null;
      _availableCameras = const [];
    }
  }

  Future<void> _disposeController({required bool preserveCameraCache}) async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        await controller.dispose();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e, st) {
        debugPrint('Dispose failed: $e\n$st');
      }
    }
    if (!preserveCameraCache) {
      _activeCamera = null;
      _availableCameras = const [];
    }
  }

  int _compareCameras(CameraDescription a, CameraDescription b) {
    final priorityDiff =
        _lensPriority(a.lensDirection) - _lensPriority(b.lensDirection);
    return priorityDiff != 0 ? priorityDiff : a.name.compareTo(b.name);
  }

  List<ResolutionPreset> _presetsInPriorityOrder(ResolutionPreset preferred) {
    final ordered = <ResolutionPreset>{
      preferred,
      if (preferred.index > ResolutionPreset.medium.index)
        ResolutionPreset.medium,
      ResolutionPreset.low,
    };
    return ordered.toList();
  }

  int _lensPriority(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.external:
        return 0;
      case CameraLensDirection.back:
        return 1;
      case CameraLensDirection.front:
        return 2;
    }
  }

  CameraDescription? _pickBestCamera(List<CameraDescription> cameras) {
    CameraDescription? find(CameraLensDirection dir) {
      try {
        return cameras.firstWhere((c) => c.lensDirection == dir);
      } catch (_) {
        return null;
      }
    }

    return find(CameraLensDirection.external) ??
        find(CameraLensDirection.back) ??
        find(CameraLensDirection.front);
  }

  void _logCameraError(String message, CameraException error, StackTrace st) {
    debugPrint('❌ $message (${error.code}): ${error.description}');
    debugPrint('$st');
  }
}
