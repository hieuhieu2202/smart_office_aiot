import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_factory/config/global_color.dart';

import 'package:smart_factory/service/camera/camera_service.dart';
import 'package:smart_factory/service/winscp_upload_service.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  final CameraService _cameraService = CameraService();
  final WinScpUploadService _uploadService = WinScpUploadService();

  bool _initializing = true;
  bool _hasCamera = false;
  bool _uploading = false;
  String _selectedFolder = '/';
  File? _previewFile;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _cameraService.initialize();
      _hasCamera = true;
    } on CameraException catch (_) {
      _hasCamera = false;
      Get.snackbar(
        'Camera',
        'No camera found',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Get.isDarkMode
            ? GlobalColors.cardDarkBg
            : GlobalColors.cardLightBg,
        colorText: Get.isDarkMode
            ? GlobalColors.darkPrimaryText
            : GlobalColors.lightPrimaryText,
      );
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }

    try {
      await _uploadService.listDirectories(_selectedFolder);
    } catch (_) {
      // Ignore directory preload errors; they will surface when the user opens the picker.
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _captureAndUpload() async {
    if (!_hasCamera || _uploading) {
      return;
    }

    try {
      setState(() {
        _uploading = true;
      });

      final controller = _cameraService.controller;
      if (controller == null || !controller.value.isInitialized) {
        throw CameraException('not_initialized', 'Camera is not ready');
      }

      final picture = await _cameraService.capturePhoto();
      final bytes = await picture.readAsBytes();
      _previewBytes = bytes;

      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'photo_$timestamp.jpg';
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      _previewFile = file;

      if (mounted) {
        setState(() {});
      }

      try {
        await _uploadService.uploadFile(
          file: file,
          remoteDirectory: _selectedFolder,
          remoteFileName: filename,
        );
        Get.snackbar(
          'Upload',
          'Upload successful ✅',
          snackStyle: SnackStyle.FLOATING,
          backgroundColor: Get.isDarkMode
              ? GlobalColors.cardDarkBg
              : GlobalColors.cardLightBg,
          colorText: Get.isDarkMode
              ? GlobalColors.darkPrimaryText
              : GlobalColors.lightPrimaryText,
        );
      } catch (_) {
        Get.snackbar(
          'Upload',
          'Upload failed ❌',
          snackStyle: SnackStyle.FLOATING,
          backgroundColor: Get.isDarkMode
              ? GlobalColors.cardDarkBg
              : GlobalColors.cardLightBg,
          colorText: Get.isDarkMode
              ? GlobalColors.darkPrimaryText
              : GlobalColors.lightPrimaryText,
        );
      }
    } on CameraException {
      Get.snackbar(
        'Camera',
        'No camera found',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText: Get.isDarkMode
            ? GlobalColors.darkPrimaryText
            : GlobalColors.lightPrimaryText,
      );
      _hasCamera = false;
    } catch (_) {
      Get.snackbar(
        'Upload',
        'Upload failed ❌',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText: Get.isDarkMode
            ? GlobalColors.darkPrimaryText
            : GlobalColors.lightPrimaryText,
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Capture'),
      ),
      floatingActionButton: _hasCamera
          ? FloatingActionButton(
              onPressed: _uploading ? null : _captureAndUpload,
              backgroundColor: GlobalColors.primaryButtonLight,
              child: _uploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_rounded),
            )
          : null,
      body: SafeArea(
        child: _initializing
            ? const Center(child: CircularProgressIndicator())
            : !_hasCamera
                ? _buildNoCameraState()
                : Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.25),
                                ),
                              ),
                              child: _cameraService.controller != null &&
                                      _cameraService.controller!.value
                                          .isInitialized
                                  ? CameraPreview(_cameraService.controller!)
                                  : const Center(
                                      child: Text(
                                        'Camera đang khởi tạo...',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _buildFolderSelector(context),
                      ),
                      if (_previewFile != null || _previewBytes != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _buildPreviewCard(),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildNoCameraState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam_off_rounded,
            size: 72,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'Không phát hiện thấy camera',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Vui lòng kết nối camera ngoài (ví dụ: Camo Studio) và thử lại.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _initializing = true;
              });
              _bootstrap();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSelector(BuildContext context) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _uploading ? null : _openFolderPicker,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.folder_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thư mục WinSCP',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFolder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.navigate_next_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final borderColor = Theme.of(context).colorScheme.primary.withOpacity(0.2);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 96,
              height: 72,
              child: _previewFile != null
                  ? Image.file(_previewFile!, fit: BoxFit.cover)
                  : (_previewBytes != null
                      ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                      : const SizedBox.shrink()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ảnh mới nhất',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _previewFile?.path.split(Platform.pathSeparator).last ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chọn thư mục đích',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _refresh,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _currentPath,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_currentPath),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Chọn thư mục này'),
            ),
            const SizedBox(height: 12),
            if (_currentPath != '/')
              ListTile(
                leading: const Icon(Icons.arrow_upward_rounded),
                title: const Text('Thư mục cha'),
                onTap: () {
                  final segments = _currentPath.split('/');
                  final parentSegments = segments
                      .where((segment) => segment.isNotEmpty)
                      .toList()
                    ..removeLast();
                  final parentPath = parentSegments.isEmpty
                      ? '/'
                      : '/${parentSegments.join('/')}';
                  setState(() {
                    _currentPath = parentPath;
                    _entriesFuture = widget.uploadService
                        .listDirectories(_currentPath);
                  });
                },
              ),
            Flexible(
              child: FutureBuilder<List<RemoteDirectoryEntry>>(
                future: _entriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Không thể tải thư mục: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  final entries = snapshot.data ?? const [];
                  if (entries.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text('Thư mục trống'),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        leading: const Icon(Icons.folder_open_rounded),
                        title: Text(entry.name),
                        trailing: const Icon(Icons.navigate_next_rounded),
                        onTap: () => _navigateTo(entry),
                      );
                    },
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
