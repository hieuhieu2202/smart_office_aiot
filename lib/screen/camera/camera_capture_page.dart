import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/service/camera/camera_service.dart';
import 'package:smart_factory/service/winscp_upload_service.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

enum _NoticeType { info, success, error }

class _InlineNotice {
  const _InlineNotice({
    required this.id,
    required this.message,
    required this.type,
    required this.autoDismiss,
  });

  final int id;
  final String message;
  final _NoticeType type;
  final bool autoDismiss;
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  final CameraService _cameraService = CameraService();
  final WinScpUploadService _uploadService =
      WinScpUploadService(shareSessionWithStpModule: false);
  final DateFormat _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

  bool _initializing = true;
  bool _uploading = false;
  CameraException? _cameraError;
  CameraDescription? _selectedCamera;

  String _selectedFolder = '/';
  Uint8List? _latestPreviewBytes;
  DateTime? _lastUploadTime;
  String? _lastRemotePath;
  String? _lastUploadError;
  File? _pendingCaptureFile;
  Uint8List? _pendingPreviewBytes;
  String? _pendingFileName;
  bool _capturing = false;
  int _rotationTurns = 0;
  bool _animateFromRight = false;
  bool _contentVisible = false;
  final List<_InlineNotice> _activeNotices = [];
  int _nextNoticeId = 0;

  @override
  void initState() {
    super.initState();
    _animateFromRight = !kIsWeb && Platform.isWindows;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _contentVisible = true;
        });
      }
    });
    _initializeCamera();
  }

  @override
  void dispose() {
    final pendingFile = _pendingCaptureFile;
    if (pendingFile != null) {
      unawaited(pendingFile.delete());
    }
    unawaited(_cameraService.dispose());
    unawaited(_uploadService.dispose());
    super.dispose();
  }

  Future<void> _initializeCamera({CameraDescription? camera}) async {
    setState(() {
      _initializing = true;
      _cameraError = null;
    });

    final ready = await _cameraService.initialize(
      cameraDescription: camera,
      preset: ResolutionPreset.high,
    );

    if (!mounted) return;

    setState(() {
      _initializing = false;
      _selectedCamera = _cameraService.activeCamera;
      if (!ready) {
        _cameraError = _cameraService.lastError;
      }
    });

    if (!ready) {
      final lastError = _cameraService.lastError;
      if (lastError?.code == 'missing_plugin') {
        _showCameraUnsupportedNotice();
      } else {
        final description = lastError?.description ?? 'No camera found';
        _pushNotice(
          description,
          type: _NoticeType.error,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Future<void> _switchCamera(CameraDescription description) async {
    await _cameraService.dispose();
    await Future.delayed(const Duration(milliseconds: 150));
    await _initializeCamera(camera: description);
  }

  void _rotateLeft() {
    setState(() {
      _rotationTurns = (_rotationTurns + 3) % 4;
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationTurns = (_rotationTurns + 1) % 4;
    });
  }

  void _resetRotation() {
    setState(() {
      _rotationTurns = 0;
    });
  }

  Future<void> _capturePhoto() async {
    if (_capturing || _uploading) return;

    if (!_cameraService.isInitialized) {
      _pushNotice(
        'Camera chưa sẵn sàng',
        type: _NoticeType.error,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    setState(() {
      _capturing = true;
      _lastUploadError = null;
    });

    final timestamp = DateTime.now();
    final fileName = 'photo_${_fileNameFormat.format(timestamp)}.jpg';
    final rotationTurns = _rotationTurns % 4;

    try {
      final xFile = await _cameraService.capturePhoto();
      final file = await _persistCapture(
        xFile,
        fileName,
        rotationTurns,
      );
      final previewBytes = await file.readAsBytes();

      final previousFile = _pendingCaptureFile;
      if (previousFile != null && previousFile.path != file.path) {
        unawaited(previousFile.delete());
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingCaptureFile = file;
        _pendingPreviewBytes = previewBytes;
        _pendingFileName = fileName;
      });
    } on CameraException catch (error) {
      if (!mounted) return;

      setState(() {
        _cameraError = error;
      });

      if (error.code == 'missing_plugin') {
        _showCameraUnsupportedNotice();
      } else if (error.code == 'no_camera' || error.code == 'not_initialized') {
        _pushNotice(
          'No camera found',
          type: _NoticeType.error,
          duration: const Duration(seconds: 4),
        );
      } else {
        _pushNotice(
          'Chụp ảnh thất bại ❌',
          type: _NoticeType.error,
          duration: const Duration(seconds: 4),
        );
      }
    } on FileSystemException catch (error) {
      if (!mounted) return;

      setState(() {
        _lastUploadError = error.message;
      });

      _pushNotice(
        'Không thể lưu ảnh ❌',
        type: _NoticeType.error,
        duration: const Duration(seconds: 4),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _lastUploadError = '$error';
      });

      _pushNotice(
        'Không thể chụp ảnh ❌',
        type: _NoticeType.error,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
        });
      }
    }
  }

  Future<void> _uploadPendingCapture() async {
    final file = _pendingCaptureFile;
    final fileName = _pendingFileName;

    if (file == null || fileName == null) {
      _pushNotice(
        'Không có ảnh để tải lên',
        type: _NoticeType.info,
      );
      return;
    }

    if (_uploading) return;

    setState(() {
      _uploading = true;
      _lastUploadError = null;
    });

    try {
      final remotePath = await _uploadService.uploadFile(
        file: file,
        remoteDirectory: _selectedFolder,
        remoteFileName: fileName,
      );

      try {
        await file.delete();
      } catch (_) {}

      if (!mounted) {
        return;
      }

      setState(() {
        _lastUploadTime = DateTime.now();
        _lastRemotePath = remotePath;
        _latestPreviewBytes = _pendingPreviewBytes;
        _pendingPreviewBytes = null;
        _pendingCaptureFile = null;
        _pendingFileName = null;
      });

      _pushNotice(
        'Upload successful ✅',
        type: _NoticeType.success,
      );
    } on FileSystemException catch (error) {
      if (!mounted) return;

      setState(() {
        _lastUploadError = error.message;
      });

      _pushNotice(
        'Upload failed ❌',
        type: _NoticeType.error,
        duration: const Duration(seconds: 4),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _lastUploadError = '$error';
      });

      _pushNotice(
        'Upload failed ❌',
        type: _NoticeType.error,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _discardPendingCapture({
    bool deleteFile = true,
    bool silent = false,
  }) async {
    final file = _pendingCaptureFile;

    if (deleteFile && file != null) {
      try {
        await file.delete();
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _pendingCaptureFile = null;
      _pendingPreviewBytes = null;
      _pendingFileName = null;
    });

    if (!silent) {
      _pushNotice(
        'Đã xóa ảnh chờ gửi',
        type: _NoticeType.info,
      );
    }
  }

  Future<void> _retakeCapture() async {
    if (_uploading || _capturing) return;

    await _discardPendingCapture(deleteFile: true, silent: true);

    if (!mounted) return;

    unawaited(_capturePhoto());
  }

  Future<void> _previewPendingCapture() async {
    final bytes = _pendingPreviewBytes;

    if (bytes == null) {
      _pushNotice(
        'Không có ảnh để xem trước',
        type: _NoticeType.info,
      );
      return;
    }

    final media = MediaQuery.of(context);
    final targetWidth = media.size.width * 0.9;
    final targetHeight = media.size.height * 0.9;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: targetWidth,
            height: targetHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      tooltip: 'Đóng',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<File> _persistCapture(
    XFile file,
    String fileName,
    int rotationTurns,
  ) async {
    final directory = await getTemporaryDirectory();
    final targetPath = p.join(directory.path, fileName);
    final normalizedTurns = rotationTurns % 4;
    final needsRotation = normalizedTurns != 0;

    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        final fallback = File(targetPath);
        await fallback.writeAsBytes(bytes, flush: true);
        return fallback;
      }

      img.Image processed = decoded;

      if (needsRotation) {
        processed = img.copyRotate(
          processed,
          angle: normalizedTurns * 90,
        );
      }

      final encoded = img.encodeJpg(processed, quality: 95);
      final savedFile = File(targetPath);
      await savedFile.writeAsBytes(encoded, flush: true);
      return savedFile;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Không thể xử lý ảnh: $error');
      }

      final fallback = File(targetPath);
      await file.saveTo(targetPath);
      return fallback;
    }
  }

  Future<void> _chooseRemoteFolder() async {
    final selected = await _showRemoteDirectoryPicker();

    if (selected != null && mounted) {
      setState(() {
        _selectedFolder = selected;
      });
    }
  }

  Future<String?> _showRemoteDirectoryPicker() {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final useSideSheet = width >= 900 && height >= 600;

    final picker = _RemoteDirectoryPicker(
      initialPath: _selectedFolder,
      service: _uploadService,
      presentation: useSideSheet
          ? _DirectoryPickerPresentation.sideSheet
          : _DirectoryPickerPresentation.bottomSheet,
    );

    if (useSideSheet) {
      return showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Chọn thư mục đích',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          final media = MediaQuery.of(context);
          final dialogWidth = media.size.width;
          final sheetWidth = dialogWidth.isFinite
              ? math.max(340.0, math.min(dialogWidth * 0.4, 520.0))
              : 420.0;

          return SafeArea(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                  right: media.padding.right + 16,
                  top: 24,
                  bottom: 24,
                ),
                child: SizedBox(width: sheetWidth, child: picker),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                    .animate(curved),
            child: child,
          );
        },
      );
    }

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => picker,
    );
  }

  void _pushNotice(
    String message, {
    _NoticeType type = _NoticeType.info,
    Duration duration = const Duration(seconds: 3),
    bool persistent = false,
  }) {
    if (!mounted) return;

    final entry = _InlineNotice(
      id: _nextNoticeId++,
      message: message,
      type: type,
      autoDismiss: !persistent,
    );

    setState(() {
      if (_activeNotices.length >= 4) {
        _activeNotices.removeAt(0);
      }
      _activeNotices.add(entry);
    });

    if (!persistent) {
      Future<void>.delayed(duration, () {
        if (!mounted) {
          return;
        }
        setState(() {
          _activeNotices.remove(entry);
        });
      });
    }
  }

  void _dismissNotice(_InlineNotice notice) {
    if (!mounted) return;
    setState(() {
      _activeNotices.removeWhere((entry) => entry.id == notice.id);
    });
  }

  void _showCameraUnsupportedNotice() {
    _pushNotice(
      'Camera chưa được hỗ trợ trên nền tảng này. Vui lòng thử trên thiết bị khác.',
      type: _NoticeType.error,
      persistent: true,
    );
  }

  String _describeCamera(CameraDescription description) {
    final direction = description.lensDirection.name;
    final name = description.name;
    return '${direction[0].toUpperCase()}${direction.substring(1)} • $name';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới camera',
            onPressed: _initializing ? null : () async {
              await _cameraService.dispose();
              await Future.delayed(const Duration(milliseconds: 150));
              await _initializeCamera(camera: _selectedCamera);
            },
          ),
        ],
      ),
      floatingActionButton: _buildCaptureFab(context, theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  Widget content = LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final isCompact = width < 600;
                      final isWide = width >= 900;
                      final previewCard = _buildPreviewCard(theme);
                      final detailCard = _buildDetailsCard(theme);

                      if (isWide) {
                        final availableWidth = constraints.maxWidth;
                        final targetDetailWidth = availableWidth.isFinite
                            ? availableWidth * 0.2
                            : 300.0;
                        final detailWidth =
                            targetDetailWidth.clamp(240.0, 360.0).toDouble();

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: previewCard),
                              const SizedBox(width: 24),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: detailWidth,
                                  maxWidth: detailWidth,
                                ),
                                child: detailCard,
                              ),
                            ],
                          ),
                        );
                      }

                      if (!isCompact) {
                        final availableWidth = constraints.maxWidth;
                        final targetDetailWidth = availableWidth.isFinite
                            ? availableWidth * 0.26
                            : 300.0;
                        final detailWidth =
                            targetDetailWidth.clamp(250.0, 340.0).toDouble();

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: previewCard),
                              const SizedBox(width: 20),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: detailWidth,
                                  maxWidth: detailWidth,
                                ),
                                child: detailCard,
                              ),
                            ],
                          ),
                        );
                      }

                      final media = MediaQuery.of(context);
                      final screenHeight = media.size.height;
                      final previewHeight = screenHeight.isFinite
                          ? math.max(
                              math.min(screenHeight * 0.58, 540.0),
                              320.0,
                            )
                          : 420.0;
                      final detailsHeight = screenHeight.isFinite
                          ? math.max(
                              math.min(screenHeight * 0.48, 520.0),
                              280.0,
                            )
                          : 360.0;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 120),
                        child: Column(
                          children: [
                            SizedBox(
                              height: previewHeight,
                              width: double.infinity,
                              child: previewCard,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: detailsHeight,
                              width: double.infinity,
                              child: detailCard,
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (_animateFromRight) {
                    content = AnimatedSlide(
                      offset: _contentVisible ? Offset.zero : const Offset(0.2, 0),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                        opacity: _contentVisible ? 1 : 0,
                        child: content,
                      ),
                    );
                  }

                  return content;
                },
              ),
            ),
            if (_activeNotices.isNotEmpty)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final notice in _activeNotices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _NoticeBanner(
                          notice: notice,
                          onClose: () => _dismissNotice(notice),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureFab(BuildContext context, ThemeData theme) {
    final hasPendingCapture = _pendingCaptureFile != null;
    final isBusy =
        _initializing || _capturing || _uploading || !_cameraService.isInitialized;

    if (!hasPendingCapture) {
      return FloatingActionButton.extended(
        onPressed: isBusy ? null : _capturePhoto,
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        label: SizedBox(
          width: 160,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_capturing) ...[
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Đang chụp...'),
              ] else ...[
                const Icon(Icons.photo_camera_rounded),
                const SizedBox(width: 12),
                const Text('Chụp ảnh'),
              ],
            ],
          ),
        ),
      );
    }

    return _buildPostCaptureBar(context, theme);
  }

  Widget _buildPostCaptureBar(BuildContext context, ThemeData theme) {
    final media = MediaQuery.of(context);
    final availableWidth = math.max(media.size.width - 32, 280.0);
    final maxWidth = math.min(availableWidth, 620.0);
    final isUploading = _uploading;

    return SizedBox(
      width: maxWidth,
      child: Material(
        elevation: 6,
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: isUploading ? null : _uploadPendingCapture,
                icon: isUploading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(isUploading ? 'Đang tải...' : 'Tải lên'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              OutlinedButton.icon(
                onPressed: isUploading ? null : _previewPendingCapture,
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Xem trước'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 44),
                ),
              ),
              TextButton.icon(
                onPressed: isUploading ? null : _retakeCapture,
                icon: const Icon(Icons.camera_enhance_rounded),
                label: const Text('Chụp lại'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              TextButton.icon(
                onPressed: isUploading ? null : () => _discardPendingCapture(deleteFile: true),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Xóa ảnh'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    final controller = _cameraService.controller;
    final hasLivePreview = _cameraService.isInitialized && controller != null;

    // Nếu không có camera hoặc đang khởi tạo
    if (!hasLivePreview || !(controller?.value.isInitialized ?? false)) {
      Widget placeholder;
      if (_initializing) {
        placeholder = const _PreviewPlaceholder(
          icon: Icons.photo_camera_front_rounded,
          message: 'Đang khởi tạo camera...',
        );
      } else {
        final errorCode = _cameraError?.code;
        var errorMessage = _cameraError?.description ?? 'Không tìm thấy camera khả dụng.';
        if (errorCode == 'missing_plugin') {
          errorMessage = 'Camera chưa được hỗ trợ trên nền tảng này. Vui lòng thử trên thiết bị khác.';
        }
        placeholder = _PreviewPlaceholder(
          icon: Icons.videocam_off_rounded,
          message: errorMessage,
          action: TextButton.icon(
            onPressed: _initializing ? null : () => _initializeCamera(),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        );
      }

      return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: AspectRatio(
          aspectRatio: 1,
          child: placeholder,
        ),
      );
    }

    final liveController = controller;
    final rotationTurns = _rotationTurns % 4;
    final aspectRatio = liveController.value.aspectRatio;
    final displayAspectRatio = rotationTurns.isOdd ? 1 / aspectRatio : aspectRatio;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height;

          double previewWidth = maxWidth;
          double previewHeight = previewWidth / displayAspectRatio;

          if (previewHeight > maxHeight) {
            previewHeight = maxHeight;
            previewWidth = previewHeight * displayAspectRatio;
          }

          if (previewWidth.isNaN || previewWidth <= 0) {
            previewWidth = maxWidth;
          }

          if (previewHeight.isNaN || previewHeight <= 0) {
            previewHeight = maxHeight;
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: previewWidth,
                  height: previewHeight,
                  child: RotatedBox(
                    quarterTurns: rotationTurns,
                    child: ValueListenableBuilder<CameraValue>(
                      valueListenable: liveController,
                      builder: (context, value, child) {
                        if (value.isInitialized && !value.isRecordingVideo) {
                          Widget preview = CameraPreview(liveController);

                          if (_shouldCorrectPreviewMirror(
                              liveController.description)) {
                            preview = Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: preview,
                            );
                          }

                          return preview;
                        }
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _shouldCorrectPreviewMirror(CameraDescription description) {
    if (kIsWeb) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        switch (description.lensDirection) {
          case CameraLensDirection.front:
          case CameraLensDirection.external:
            return true;
          case CameraLensDirection.back:
            return false;
        }
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return false;
    }
  }


  Widget _buildDetailsCard(ThemeData theme) {
    final cameras = _cameraService.cameras;

    final cardContent = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Thiết bị camera',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (cameras.isEmpty)
            Text(
              'Không phát hiện camera nào. Hãy kết nối thiết bị và thử lại.',
              style: theme.textTheme.bodyMedium,
            )
          else
            DropdownButtonFormField<CameraDescription>(
              value: _selectedCamera ?? cameras.first,
              items: [
                for (final camera in cameras)
                  DropdownMenuItem(
                    value: camera,
                    child: Text(_describeCamera(camera)),
                  ),
              ],
              isExpanded: true,
              onChanged: _initializing ? null : (camera) {
                if (camera != null) {
                  _switchCamera(camera);
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          const SizedBox(height: 24),
          _buildRotationControls(theme),
          const SizedBox(height: 24),
          Text(
            'Thư mục WinSCP',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _chooseRemoteFolder,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Chọn thư mục'),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? GlobalColors.cardDarkBg.withOpacity(0.6)
                  : GlobalColors.cardLightBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.15),
              ),
            ),
            child: Text(
              _selectedFolder.isEmpty ? '/' : _selectedFolder,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          if (_pendingPreviewBytes != null) ...[
            Text(
              'Ảnh chờ gửi',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _pendingPreviewBytes!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _previewPendingCapture,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Xem'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 40),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _discardPendingCapture(deleteFile: true),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Xóa'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],
          if (_latestPreviewBytes != null) ...[
            Text(
              'Ảnh vừa chụp',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _latestPreviewBytes!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_lastRemotePath != null) ...[
            Text(
              'Tải lên gần nhất',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.cloud_done_rounded, color: Colors.green),
              title: Text(
                _lastRemotePath!,
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: _lastUploadTime != null
                  ? Text(DateFormat('HH:mm:ss dd/MM/yyyy').format(_lastUploadTime!))
                  : null,
            ),
          ],
          if (_lastUploadError != null) ...[
            const SizedBox(height: 12),
            Text(
              'Lỗi tải lên',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _lastUploadError!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = cardContent;
          if (constraints.maxWidth.isFinite) {
            content = ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: content,
            );
          }
          if (constraints.maxHeight.isFinite) {
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: content,
            );
          }
          return content;
        },
      ),
    );
  }

  Widget _buildRotationControls(ThemeData theme) {
      final rotationDegrees = (_rotationTurns % 4) * 90;
    final disableButtons = _initializing || !_cameraService.isInitialized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Góc xoay',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: disableButtons ? null : _rotateLeft,
              icon: const Icon(Icons.rotate_left_rounded),
              label: const Text('Trái 90°'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(0, 40),
              ),
            ),
            OutlinedButton.icon(
              onPressed: disableButtons ? null : _rotateRight,
              icon: const Icon(Icons.rotate_right_rounded),
              label: const Text('Phải 90°'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(0, 40),
              ),
            ),
            Chip(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              avatar: const Icon(Icons.explore_rounded, size: 18),
              label: Text('$rotationDegrees°'),
            ),
            if (rotationDegrees != 0)
              TextButton(
                onPressed: disableButtons ? null : _resetRotation,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Đặt lại'),
              ),
          ],
        ),
      ],
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.notice, required this.onClose});

  final _InlineNotice notice;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _NoticePalette.resolve(theme, notice.type);

    final closeTooltip = notice.autoDismiss ? 'Ẩn thông báo' : 'Đóng';

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: palette.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(palette.icon, color: palette.foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notice.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              splashRadius: 20,
              icon: Icon(Icons.close_rounded, color: palette.foreground),
              tooltip: closeTooltip,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticePalette {
  const _NoticePalette({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;

  static _NoticePalette resolve(ThemeData theme, _NoticeType type) {
    switch (type) {
      case _NoticeType.success:
        return _NoticePalette(
          background: theme.colorScheme.tertiaryContainer,
          foreground: theme.colorScheme.onTertiaryContainer,
          icon: Icons.check_circle_rounded,
        );
      case _NoticeType.error:
        return _NoticePalette(
          background: theme.colorScheme.errorContainer,
          foreground: theme.colorScheme.onErrorContainer,
          icon: Icons.error_outline_rounded,
        );
      case _NoticeType.info:
        return _NoticePalette(
          background: theme.colorScheme.primaryContainer,
          foreground: theme.colorScheme.onPrimaryContainer,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.center,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.white70),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

enum _DirectoryPickerPresentation { bottomSheet, sideSheet }

class _RemoteDirectoryPicker extends StatefulWidget {
  const _RemoteDirectoryPicker({
    required this.initialPath,
    required this.service,
    this.presentation = _DirectoryPickerPresentation.bottomSheet,
  });

  final String initialPath;
  final WinScpUploadService service;
  final _DirectoryPickerPresentation presentation;

  @override
  State<_RemoteDirectoryPicker> createState() => _RemoteDirectoryPickerState();
}

class _RemoteDirectoryPickerState extends State<_RemoteDirectoryPicker> {
  late String _currentPath;
  late Future<List<RemoteDirectoryEntry>> _pendingRequest;
  late final TextEditingController _searchController;
  late final VoidCallback _searchListener;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath.isEmpty ? '/' : widget.initialPath;
    _pendingRequest = widget.service.listDirectories(_currentPath);
    _searchController = TextEditingController();
    _searchListener = () {
      final next = _searchController.text.trim().toLowerCase();
      if (next != _searchTerm) {
        setState(() {
          _searchTerm = next;
        });
      }
    };
    _searchController.addListener(_searchListener);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSideSheet =
        widget.presentation == _DirectoryPickerPresentation.sideSheet;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = isSideSheet ? 0.0 : mediaQuery.viewInsets.bottom;
    final availableHeight =
        math.max(0.0, mediaQuery.size.height - bottomPadding);
    final targetHeight = isSideSheet
        ? availableHeight
        : (availableHeight == 0
            ? 420.0
            : math
                .min(520.0, math.max(360.0, availableHeight * 0.75)));

    final panelRadius = isSideSheet
        ? const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          );

    Widget buildDirectoryList(List<RemoteDirectoryEntry> directories) {
      if (directories.isEmpty) {
        return const _DirectoryEmpty();
      }

      final query = _searchTerm;
      final filtered = query.isEmpty
          ? directories
          : directories
              .where((entry) {
                final target = '${entry.name} ${entry.path}'.toLowerCase();
                return target.contains(query);
              })
              .toList();

      if (filtered.isEmpty) {
        return _DirectorySearchEmpty(query: _searchController.text);
      }

      return ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = filtered[index];
          return ListTile(
            leading: const Icon(Icons.folder_rounded, color: Colors.amber),
            title: Text(entry.name),
            subtitle: Text(entry.path),
            onTap: () => _navigateTo(entry.path),
          );
        },
      );
    }

    final content = SizedBox(
      height: targetHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, isSideSheet ? 24 : 20, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chọn thư mục đích',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _currentPath,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Tìm kiếm thư mục',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(_currentPath),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Chọn thư mục này'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
          if (_currentPath != '/')
            ListTile(
              leading: const Icon(Icons.arrow_upward_rounded),
              title: const Text('Lên một cấp'),
              onTap: () => _navigateTo(_parentPath(_currentPath)),
            ),
          Expanded(
            child: FutureBuilder<List<RemoteDirectoryEntry>>(
              future: _pendingRequest,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _DirectoryError(
                    message: '${snapshot.error}',
                    onRetry: () => _navigateTo(_currentPath),
                  );
                }

                final directories = snapshot.data ?? <RemoteDirectoryEntry>[];
                return buildDirectoryList(directories);
              },
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      top: isSideSheet,
      bottom: !isSideSheet,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Material(
          elevation: isSideSheet ? 12 : 0,
          color: theme.colorScheme.surface,
          borderRadius: panelRadius,
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchListener);
    _searchController.dispose();
    super.dispose();
  }

  void _navigateTo(String path) {
    final normalized = path.isEmpty ? '/' : path;
    setState(() {
      _currentPath = normalized;
      _pendingRequest = widget.service.listDirectories(_currentPath);
    });
  }

  String _parentPath(String path) {
    if (path.isEmpty || path == '/') {
      return '/';
    }

    final segments = path.split('/')..removeWhere((segment) => segment.isEmpty);
    if (segments.isEmpty) {
      return '/';
    }
    segments.removeLast();
    if (segments.isEmpty) {
      return '/';
    }
    return '/${segments.join('/')}';
  }
}

class _DirectoryEmpty extends StatelessWidget {
  const _DirectoryEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Thư mục này không có thư mục con. Bạn có thể chọn trực tiếp hoặc quay lại.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _DirectorySearchEmpty extends StatelessWidget {
  const _DirectorySearchEmpty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 42, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy thư mục phù hợp',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Từ khóa "${query.trim()}" không khớp với thư mục nào.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryError extends StatelessWidget {
  const _DirectoryError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 42, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Không thể tải danh sách thư mục.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
