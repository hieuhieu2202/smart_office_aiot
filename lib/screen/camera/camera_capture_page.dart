import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/service/camera/camera_service.dart';
import 'package:smart_factory/service/screen/screen_capture_service.dart';
import 'package:smart_factory/service/winscp_upload_service.dart';

enum CaptureMode { camera, screenshot }

class UploadFeedback {
  const UploadFeedback.success({
    required this.timestamp,
    required this.remotePath,
  })  : success = true,
        errorMessage = null;

  const UploadFeedback.failure({
    required this.timestamp,
    required this.errorMessage,
  })  : success = false,
        remotePath = null;

  final bool success;
  final DateTime timestamp;
  final String? remotePath;
  final String? errorMessage;
}

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  final CameraService _cameraService = CameraService();
  final WinScpUploadService _uploadService = WinScpUploadService();
  final ScreenCaptureService _screenCaptureService = ScreenCaptureService();
  final DateFormat _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  CaptureMode _mode = CaptureMode.camera;
  bool _cameraInitializing = true;
  bool _cameraReady = false;
  CameraException? _cameraError;

  String _selectedFolder = '/';
  bool _uploading = false;
  File? _latestFile;
  Uint8List? _latestPreviewBytes;
  UploadFeedback? _lastFeedback;

  @override
  void initState() {
    super.initState();
    _prepareCamera();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _prepareCamera() async {
    setState(() {
      _cameraInitializing = true;
      _cameraReady = false;
      _cameraError = null;
    });

    final initialized = await _cameraService.initialize(
      preset: ResolutionPreset.high,
    );

    if (!mounted) return;

    setState(() {
      _cameraInitializing = false;
      _cameraReady = initialized;
      _cameraError = initialized ? null : _cameraService.lastError;
    });

    if (!initialized) {
      _showCameraMessage(_cameraService.lastError);
    }
  }

  Future<void> _switchCamera(CameraDescription description) async {
    setState(() {
      _cameraInitializing = true;
      _cameraReady = false;
      _cameraError = null;
    });

    final initialized = await _cameraService.switchCamera(description);

    if (!mounted) return;

    setState(() {
      _cameraInitializing = false;
      _cameraReady = initialized;
      _cameraError = initialized ? null : _cameraService.lastError;
    });

    if (!initialized) {
      _showCameraMessage(
        _cameraService.lastError,
        fallbackMessage: 'Không thể chuyển camera',
      );
    }
  }

  Future<void> _onCapturePressed() async {
    if (_uploading) return;

    if (_mode == CaptureMode.camera && !_cameraReady) {
      _showCameraMessage(
        _cameraError,
        fallbackMessage: 'Camera chưa sẵn sàng',
      );
      return;
    }

    setState(() {
      _uploading = true;
    });

    final timestamp = DateTime.now();
    final fileName = 'photo_${_fileNameFormat.format(timestamp)}.jpg';

    try {
      final File file;

      if (_mode == CaptureMode.camera) {
        final xFile = await _cameraService.capturePhoto();
        file = await _persistCameraCapture(xFile, fileName);
      } else {
        file = await _screenCaptureService.captureJpeg(fileName: fileName);
      }

      final previewBytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _latestFile = file;
        _latestPreviewBytes = previewBytes;
      });

      final remotePath = await _uploadService.uploadFile(
        file: file,
        remoteDirectory: _selectedFolder,
        remoteFileName: fileName,
      );

      if (!mounted) return;

      setState(() {
        _lastFeedback = UploadFeedback.success(
          timestamp: DateTime.now(),
          remotePath: remotePath,
        );
      });

      _showUploadMessage(success: true);
    } on CameraException catch (error) {
      await _handleCameraFailure(error);
    } on ScreenCaptureException catch (error) {
      if (!mounted) return;
      setState(() {
        _lastFeedback = UploadFeedback.failure(
          timestamp: DateTime.now(),
          errorMessage: error.message,
        );
      });
      _showScreenshotMessage(error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _lastFeedback = UploadFeedback.failure(
          timestamp: DateTime.now(),
          errorMessage: '$error',
        );
      });
      _showUploadMessage(success: false);
    } finally {
      if (!mounted) return;
      setState(() {
        _uploading = false;
      });
    }
  }

  Future<File> _persistCameraCapture(XFile file, String fileName) async {
    final directory = await getTemporaryDirectory();
    final path = p.join(directory.path, fileName);
    await file.saveTo(path);
    return File(path);
  }

  Future<void> _handleCameraFailure(CameraException error) async {
    await _cameraService.dispose();
    if (!mounted) return;

    setState(() {
      _cameraReady = false;
      _cameraError = error;
      _lastFeedback = UploadFeedback.failure(
        timestamp: DateTime.now(),
        errorMessage: error.description,
      );
    });

    _showCameraMessage(error);
  }

  void _showCameraMessage(CameraException? error, {String? fallbackMessage}) {
    final message = switch (error?.code) {
      'CameraAccessDenied' => 'Không được cấp quyền truy cập camera',
      'cameraDisconnected' => 'Camera đã ngắt kết nối',
      'cameraUnavailable' => 'Camera đang bận, vui lòng thử lại',
      'no_camera' => 'Không tìm thấy camera phù hợp',
      _ => fallbackMessage ?? error?.description ?? 'Không thể sử dụng camera',
    };

    Get.snackbar(
      'Camera',
      message,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor:
          Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      colorText: Get.isDarkMode
          ? GlobalColors.darkPrimaryText
          : GlobalColors.lightPrimaryText,
    );
  }

  void _showUploadMessage({required bool success}) {
    Get.snackbar(
      'Upload',
      success ? 'Upload successful ✅' : 'Upload failed ❌',
      snackStyle: SnackStyle.FLOATING,
      backgroundColor:
          Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      colorText: Get.isDarkMode
          ? GlobalColors.darkPrimaryText
          : GlobalColors.lightPrimaryText,
    );
  }

  void _showScreenshotMessage(String message) {
    Get.snackbar(
      'Screen capture',
      message,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor:
          Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      colorText: Get.isDarkMode
          ? GlobalColors.darkPrimaryText
          : GlobalColors.lightPrimaryText,
    );
  }

  Future<void> _pickFolder() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => RemoteFolderPicker(
        initialPath: _selectedFolder,
        uploadService: _uploadService,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedFolder = selected;
      });
    }
  }

  Future<void> _pickCamera() async {
    final cameras = _cameraService.cameras;
    if (cameras.length <= 1) return;

    final selected = await showModalBottomSheet<CameraDescription>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chọn camera',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...cameras.map(
                (camera) => ListTile(
                  leading: Icon(_iconForDirection(camera.lensDirection)),
                  title: Text(_cameraLabel(camera)),
                  onTap: () => Navigator.of(context).pop(camera),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await _switchCamera(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isWide = mediaQuery.size.width >= 900;

    final fabIcon = _uploading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.camera_alt_rounded);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Capture'),
        actions: [
          IconButton(
            tooltip: 'Chọn thư mục WinSCP',
            onPressed: _uploading ? null : _pickFolder,
            icon: const Icon(Icons.folder_special_rounded),
          ),
          if (_mode == CaptureMode.camera && _cameraService.cameras.length > 1)
            IconButton(
              tooltip: 'Đổi camera',
              onPressed: _cameraInitializing ? null : _pickCamera,
              icon: const Icon(Icons.cameraswitch_rounded),
            ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: isWide
          ? FloatingActionButton.extended(
              onPressed: _uploading ? null : _onCapturePressed,
              icon: fabIcon,
              label: Text(_uploading ? 'Đang xử lý...' : 'Chụp & tải lên'),
            )
          : FloatingActionButton(
              onPressed: _uploading ? null : _onCapturePressed,
              child: fabIcon,
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isWide) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildCaptureSurface(),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _InformationColumn(
                        selectedFolder: _selectedFolder,
                        lastFeedback: _lastFeedback,
                        latestPreviewBytes: _latestPreviewBytes,
                        latestFile: _latestFile,
                        timeFormat: _timeFormat,
                        onPickFolder: _uploading ? null : _pickFolder,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCaptureSurface(),
                  const SizedBox(height: 16),
                  _InformationColumn(
                    selectedFolder: _selectedFolder,
                    lastFeedback: _lastFeedback,
                    latestPreviewBytes: _latestPreviewBytes,
                    latestFile: _latestFile,
                    timeFormat: _timeFormat,
                    onPickFolder: _uploading ? null : _pickFolder,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCaptureSurface() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _mode == CaptureMode.camera ? 'Camera trực tiếp' : 'Chụp màn hình',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SegmentedButton<CaptureMode>(
                  segments: const [
                    ButtonSegment(
                      value: CaptureMode.camera,
                      icon: Icon(Icons.photo_camera_rounded),
                      label: Text('Camera'),
                    ),
                    ButtonSegment(
                      value: CaptureMode.screenshot,
                      icon: Icon(Icons.monitor_rounded),
                      label: Text('Màn hình'),
                    ),
                  ],
                  selected: <CaptureMode>{_mode},
                  onSelectionChanged: (selection) async {
                    final mode = selection.first;
                    if (mode == _mode) return;
                    setState(() {
                      _mode = mode;
                    });
                    if (mode == CaptureMode.camera) {
                      await _prepareCamera();
                    } else {
                      await _cameraService.dispose();
                      if (!mounted) return;
                      setState(() {
                        _cameraReady = false;
                        _cameraError = null;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: _mode == CaptureMode.screenshot
                ? _ScreenshotPlaceholder(onCapture: _uploading ? null : _onCapturePressed)
                : _buildCameraPreview(),
          ),
          if (_mode == CaptureMode.camera)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCameraStatus(),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cameraReady && _cameraService.controller != null) {
      return CameraPreview(_cameraService.controller!);
    }
    return _UnavailablePlaceholder(
      message: _cameraError?.description ??
          'Vui lòng kết nối camera ngoài (ví dụ: Camo Studio) và thử lại.',
      onRetry: _prepareCamera,
    );
  }

  Widget _buildCameraStatus() {
    if (_cameraInitializing) {
      return const _StatusPill(
        icon: Icons.downloading_rounded,
        label: 'Đang khởi tạo camera...',
      );
    }
    if (_cameraReady) {
      return _StatusPill(
        icon: Icons.check_circle_rounded,
        label:
            'Sẵn sàng - ${_cameraLabel(_cameraService.activeCamera ?? _cameraService.controller?.description)}',
        color: Theme.of(context).colorScheme.primary,
      );
    }
    return _StatusPill(
      icon: Icons.warning_rounded,
      label: _cameraError?.description ?? 'Không tìm thấy camera',
      color: Theme.of(context).colorScheme.error,
    );
  }

  String _cameraLabel(CameraDescription? description) {
    if (description == null) {
      return 'Chưa xác định';
    }

    final facing = switch (description.lensDirection) {
      CameraLensDirection.back => 'Camera sau',
      CameraLensDirection.front => 'Camera trước',
      CameraLensDirection.external => 'Camera ngoài',
      _ => description.lensDirection.name,
    };

    return '$facing (${description.name})';
  }

  IconData _iconForDirection(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return Icons.photo_camera_back_rounded;
      case CameraLensDirection.front:
        return Icons.photo_camera_front_rounded;
      case CameraLensDirection.external:
        return Icons.videocam_rounded;
      default:
        return Icons.camera_alt_rounded;
    }
  }
}

class _ScreenshotPlaceholder extends StatelessWidget {
  const _ScreenshotPlaceholder({required this.onCapture});

  final VoidCallback? onCapture;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart_rounded,
              size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Nhấn "Chụp & tải lên" để lưu ảnh màn hình hiện tại.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Ứng dụng sẽ tự động tải ảnh lên thư mục đã chọn trên máy chủ.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.camera_rounded),
            label: const Text('Chụp màn hình ngay'),
          ),
        ],
      ),
    );
  }
}

class _UnavailablePlaceholder extends StatelessWidget {
  const _UnavailablePlaceholder({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_rounded,
              size: 56, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy camera',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = (color ?? theme.colorScheme.surfaceVariant).withOpacity(0.2);
    final foreground = color ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationColumn extends StatelessWidget {
  const _InformationColumn({
    required this.selectedFolder,
    required this.lastFeedback,
    required this.latestPreviewBytes,
    required this.latestFile,
    required this.timeFormat,
    required this.onPickFolder,
  });

  final String selectedFolder;
  final UploadFeedback? lastFeedback;
  final Uint8List? latestPreviewBytes;
  final File? latestFile;
  final DateFormat timeFormat;
  final Future<void> Function()? onPickFolder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FolderCard(
          selectedFolder: selectedFolder,
          onTap: onPickFolder,
        ),
        const SizedBox(height: 16),
        if (lastFeedback != null)
          _UploadStatusCard(
            feedback: lastFeedback!,
            timeFormat: timeFormat,
          ),
        if (latestPreviewBytes != null || latestFile != null) ...[
          const SizedBox(height: 16),
          _PreviewCard(
            previewBytes: latestPreviewBytes,
            file: latestFile,
          ),
        ],
      ],
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.selectedFolder, required this.onTap});

  final String selectedFolder;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.folder_rounded, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thư mục WinSCP',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedFolder,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.navigate_next_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadStatusCard extends StatelessWidget {
  const _UploadStatusCard({
    required this.feedback,
    required this.timeFormat,
  });

  final UploadFeedback feedback;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = feedback.success;
    final color = success
        ? theme.colorScheme.primary.withOpacity(0.12)
        : theme.colorScheme.error.withOpacity(0.12);
    final icon = success ? Icons.cloud_done_rounded : Icons.error_outline_rounded;
    final message = success
        ? 'Đã tải lên thành công lúc ${timeFormat.format(feedback.timestamp)}'
        : 'Tải lên thất bại lúc ${timeFormat.format(feedback.timestamp)}';

    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    color: success
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (success && feedback.remotePath != null) ...[
              const SizedBox(height: 12),
              Text(
                feedback.remotePath!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (!success && feedback.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                feedback.errorMessage!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.previewBytes,
    required this.file,
  });

  final Uint8List? previewBytes;
  final File? file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 110,
                height: 82,
                child: previewBytes != null
                    ? Image.memory(previewBytes!, fit: BoxFit.cover)
                    : (file != null
                        ? Image.file(file!, fit: BoxFit.cover)
                        : const SizedBox.shrink()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ảnh mới nhất',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    file != null ? p.basename(file!.path) : '',
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RemoteFolderPicker extends StatefulWidget {
  const RemoteFolderPicker({
    super.key,
    required this.initialPath,
    required this.uploadService,
  });

  final String initialPath;
  final WinScpUploadService uploadService;

  @override
  State<RemoteFolderPicker> createState() => _RemoteFolderPickerState();
}

class _RemoteFolderPickerState extends State<RemoteFolderPicker> {
  late String _currentPath;
  late Future<List<RemoteDirectoryEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath.isEmpty ? '/' : widget.initialPath;
    _entriesFuture = widget.uploadService.listDirectories(_currentPath);
  }

  Future<void> _refresh() async {
    setState(() {
      _entriesFuture = widget.uploadService.listDirectories(_currentPath);
    });
  }

  Future<void> _navigateTo(RemoteDirectoryEntry entry) async {
    setState(() {
      _currentPath = entry.path;
      _entriesFuture = widget.uploadService.listDirectories(_currentPath);
    });
  }

  void _goToParent() {
    if (_currentPath == '/' || _currentPath.isEmpty) {
      return;
    }
    final segments = _currentPath.split('/').where((e) => e.isNotEmpty).toList();
    if (segments.isEmpty) {
      setState(() {
        _currentPath = '/';
        _entriesFuture = widget.uploadService.listDirectories(_currentPath);
      });
      return;
    }
    segments.removeLast();
    final parent = segments.isEmpty ? '/' : '/${segments.join('/')}';
    setState(() {
      _currentPath = parent;
      _entriesFuture = widget.uploadService.listDirectories(_currentPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.7;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 52,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chọn thư mục đích',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Tải lại',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _currentPath,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_currentPath),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Chọn thư mục này'),
              ),
            ),
            if (_currentPath != '/')
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                child: ListTile(
                  leading: const Icon(Icons.arrow_upward_rounded),
                  title: const Text('Thư mục cha'),
                  onTap: _goToParent,
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<RemoteDirectoryEntry>>(
                future: _entriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Không thể tải thư mục: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _refresh,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  final entries = snapshot.data ?? const [];
                  if (entries.isEmpty) {
                    return const Center(child: Text('Thư mục trống'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        leading: const Icon(Icons.folder_open_rounded),
                        title: Text(entry.name),
                        trailing: const Icon(Icons.navigate_next_rounded),
                        onTap: () => _navigateTo(entry),
                      );
                    },
                    separatorBuilder: (context, _) => const Divider(height: 1),
                    itemCount: entries.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
