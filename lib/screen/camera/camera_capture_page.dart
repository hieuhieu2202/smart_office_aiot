import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_factory/config/global_color.dart';

import 'package:smart_factory/service/camera/camera_service.dart';
import 'package:smart_factory/service/winscp_upload_service.dart';

enum _CameraBootstrapStatus { loading, ready, unavailable }

class _UploadSummary {
  const _UploadSummary({
    required this.success,
    required this.timestamp,
    this.remotePath,
    this.errorMessage,
  });

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

  _CameraBootstrapStatus _status = _CameraBootstrapStatus.loading;
  bool _uploading = false;
  String _selectedFolder = '/';
  File? _latestFile;
  Uint8List? _latestPreviewBytes;
  _UploadSummary? _lastUploadSummary;
  CameraException? _lastCameraError;

  final DateFormat _timestampFormat = DateFormat('yyyyMMdd_HHmmss');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    setState(() {
      _status = _CameraBootstrapStatus.loading;
      _lastCameraError = null;
    });

    final initialized = await _cameraService.initialize(
      preset: ResolutionPreset.high,
    );

    if (!mounted) return;

    setState(() {
      if (initialized) {
        _status = _CameraBootstrapStatus.ready;
        _lastCameraError = null;
      } else {
        _status = _CameraBootstrapStatus.unavailable;
        _lastCameraError = _cameraService.lastError;
      }
    });

    if (!initialized) {
      _showCameraMessage(
        _cameraService.lastError,
        fallbackMessage: 'No camera found',
      );
    }

    try {
      await _uploadService.listDirectories(_selectedFolder);
    } catch (_) {
      // Ignore preload failures; the picker will handle displaying errors.
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  bool get _canCapture =>
      _status == _CameraBootstrapStatus.ready &&
      _cameraService.isInitialized &&
      !_uploading;

  Future<void> _captureAndUpload() async {
    if (!_canCapture) {
      return;
    }

    setState(() {
      _uploading = true;
    });

    try {
      final capturedFile = await _cameraService.capturePhoto();
      final captureMoment = DateTime.now();
      final fileName = _buildFilename(captureMoment);
      final persistedFile = await _persistCapture(capturedFile, fileName);
      final previewBytes = await persistedFile.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _latestFile = persistedFile;
        _latestPreviewBytes = previewBytes;
      });

      final remotePath = await _uploadService.uploadFile(
        file: persistedFile,
        remoteDirectory: _selectedFolder,
        remoteFileName: fileName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lastUploadSummary = _UploadSummary(
          success: true,
          timestamp: DateTime.now(),
          remotePath: remotePath,
        );
      });

      _showUploadMessage(success: true);
    } on CameraException catch (error) {
      await _handleCameraException(error);
    } catch (error) {
      if (mounted) {
        setState(() {
          _lastUploadSummary = _UploadSummary(
            success: false,
            timestamp: DateTime.now(),
            errorMessage: '$error',
          );
        });
      }
      _showUploadMessage(success: false);
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _handleCameraException(CameraException error) async {
    _showCameraMessage(error);
    await _cameraService.dispose();

    if (!mounted) return;

    setState(() {
      _status = _CameraBootstrapStatus.unavailable;
      _lastCameraError = error;
    });
  }

  Future<File> _persistCapture(XFile capturedFile, String filename) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$filename';
    await capturedFile.saveTo(filePath);
    return File(filePath);
  }

  String _buildFilename(DateTime timestamp) {
    final formatted = _timestampFormat.format(timestamp);
    return 'photo_$formatted.jpg';
  }

  Future<void> _openFolderPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return RemoteFolderPicker(
          initialPath: _selectedFolder,
          uploadService: _uploadService,
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedFolder = selected;
      });
    }
  }

  Future<void> _openCameraPicker() async {
    final cameras = _cameraService.cameras;
    if (cameras.length <= 1) {
      return;
    }

    final selected = await showModalBottomSheet<CameraDescription>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chọn camera',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                for (final camera in cameras)
                  ListTile(
                    leading: Icon(_iconForLensDirection(camera.lensDirection)),
                    title: Text(_cameraLabel(camera)),
                    onTap: () => Navigator.of(context).pop(camera),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await _switchCamera(selected);
    }
  }

  Future<void> _switchCamera(CameraDescription camera) async {
    if (!mounted) return;

    setState(() {
      _status = _CameraBootstrapStatus.loading;
    });

    final initialized = await _cameraService.switchCamera(camera);

    if (!mounted) return;

    setState(() {
      if (initialized) {
        _status = _CameraBootstrapStatus.ready;
        _lastCameraError = null;
      } else {
        _status = _CameraBootstrapStatus.unavailable;
        _lastCameraError = _cameraService.lastError;
      }
    });

    if (!initialized) {
      _showCameraMessage(
        _cameraService.lastError,
        fallbackMessage: 'Không thể chuyển camera',
      );
    }
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
      colorText:
          Get.isDarkMode ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText,
    );
  }

  void _showUploadMessage({required bool success}) {
    Get.snackbar(
      'Upload',
      success ? 'Upload successful ✅' : 'Upload failed ❌',
      snackStyle: SnackStyle.FLOATING,
      backgroundColor:
          Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      colorText:
          Get.isDarkMode ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText,
    );
  }

  String _cameraLabel(CameraDescription? description) {
    if (description == null) {
      return 'Đang khởi tạo...';
    }

    final facing = switch (description.lensDirection) {
      CameraLensDirection.back => 'Camera sau',
      CameraLensDirection.front => 'Camera trước',
      CameraLensDirection.external => 'Camera ngoài',
      _ => description.lensDirection.name,
    };

    return '$facing (${description.name})';
  }

  IconData _iconForLensDirection(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return Icons.photo_camera_back_rounded;
      case CameraLensDirection.front:
        return Icons.photo_camera_front_rounded;
      case CameraLensDirection.external:
        return Icons.connected_tv_rounded;
      default:
        return Icons.camera_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isWide = mediaQuery.size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Capture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_special_rounded),
            tooltip: 'Chọn thư mục WinSCP',
            onPressed: _uploading ? null : _openFolderPicker,
          ),
          if (_cameraService.cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.cameraswitch_rounded),
              tooltip: 'Đổi camera',
              onPressed: _status == _CameraBootstrapStatus.loading
                  ? null
                  : _openCameraPicker,
            ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: _status == _CameraBootstrapStatus.ready
          ? (isWide
              ? FloatingActionButton.extended(
                  onPressed: _canCapture ? _captureAndUpload : null,
                  icon: _uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_rounded),
                  label: Text(_uploading ? 'Đang xử lý...' : 'Chụp & tải lên'),
                )
              : FloatingActionButton(
                  onPressed: _canCapture ? _captureAndUpload : null,
                  child: _uploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_rounded),
                ))
          : null,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_status) {
            _CameraBootstrapStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            _CameraBootstrapStatus.unavailable =>
              _buildUnavailableState(),
            _CameraBootstrapStatus.ready => _buildReadyState(isWide),
          },
        ),
      ),
    );
  }

  Widget _buildReadyState(bool isWide) {
    if (isWide) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildCameraPreview(),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: _buildInformationCards(),
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
          _buildCameraPreview(),
          const SizedBox(height: 16),
          _buildInformationCards(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraService.controller;
    final aspectRatio = controller?.value.aspectRatio ?? (3 / 4);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: controller != null && controller.value.isInitialized
                  ? CameraPreview(controller)
                  : const Center(
                      child: Text(
                        'Camera đang khởi tạo...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForLensDirection(
                            _cameraService.activeCamera?.lensDirection ??
                                CameraLensDirection.back),
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _cameraLabel(_cameraService.activeCamera),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_uploading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFolderCard(),
        const SizedBox(height: 16),
        if (_lastUploadSummary != null) _buildUploadSummaryCard(),
        if (_latestPreviewBytes != null || _latestFile != null) ...[
          const SizedBox(height: 16),
          _buildPreviewCard(),
        ],
      ],
    );
  }

  Widget _buildFolderCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: _uploading ? null : _openFolderPicker,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.folder_rounded, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thư mục WinSCP',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedFolder,
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

  Widget _buildUploadSummaryCard() {
    final summary = _lastUploadSummary!;
    final theme = Theme.of(context);
    final success = summary.success;
    final color = success
        ? theme.colorScheme.primary.withOpacity(0.12)
        : theme.colorScheme.error.withOpacity(0.12);

    final icon = success
        ? Icons.cloud_done_rounded
        : Icons.error_outline_rounded;

    final message = success
        ? 'Đã tải lên thành công lúc ${_timeFormat.format(summary.timestamp)}'
        : 'Tải lên thất bại lúc ${_timeFormat.format(summary.timestamp)}';

    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
            if (success && summary.remotePath != null) ...[
              const SizedBox(height: 12),
              Text(
                summary.remotePath!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (!success && summary.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                summary.errorMessage!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 110,
                height: 82,
                child: _latestPreviewBytes != null
                    ? Image.memory(
                        _latestPreviewBytes!,
                        fit: BoxFit.cover,
                      )
                    : (_latestFile != null
                        ? Image.file(
                            _latestFile!,
                            fit: BoxFit.cover,
                          )
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
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _latestFile != null
                        ? _latestFile!.path.split(Platform.pathSeparator).last
                        : '',
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

  Widget _buildUnavailableState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              size: 72,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Không phát hiện thấy camera',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              _lastCameraError?.description ??
                  'Vui lòng kết nối camera ngoài (ví dụ: Camo Studio) và thử lại.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _bootstrap,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
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

  void _refresh() {
    setState(() {
      _entriesFuture = widget.uploadService.listDirectories(_currentPath);
    });
  }

  void _navigateTo(RemoteDirectoryEntry entry) {
    setState(() {
      _currentPath = entry.path;
      _entriesFuture = widget.uploadService.listDirectories(_currentPath);
    });
  }

  void _goToParent() {
    if (_currentPath == '/') {
      return;
    }

    final segments = _currentPath.split('/')
      ..removeWhere((segment) => segment.isEmpty);
    if (segments.isNotEmpty) {
      segments.removeLast();
    }
    final parentPath = segments.isEmpty ? '/' : '/${segments.join('/')}';

    setState(() {
      _currentPath = parentPath;
      _entriesFuture = widget.uploadService.listDirectories(_currentPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double height = max(320, min(size.height * 0.8, 560));

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
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                _currentPath,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_currentPath),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Chọn thư mục này'),
              ),
            ),
            if (_currentPath != '/') ...[
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                child: ListTile(
                  leading: const Icon(Icons.arrow_upward_rounded),
                  title: const Text('Thư mục cha'),
                  onTap: _goToParent,
                ),
              ),
            ],
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
                      padding: const EdgeInsets.all(24.0),
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
                    return const Center(
                      child: Text('Thư mục trống'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
