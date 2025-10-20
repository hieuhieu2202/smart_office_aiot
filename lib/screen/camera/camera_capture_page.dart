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
  int _rotationTurns = 0;
  bool _animateFromRight = false;
  bool _contentVisible = false;

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
        _showCameraUnsupportedBanner();
      } else {
        final description = lastError?.description ?? 'No camera found';
        _showSnackBar(description);
      }
    }
  }

  Future<void> _switchCamera(CameraDescription description) async {
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

  Future<void> _captureAndUpload() async {
    if (_uploading) return;

    if (!_cameraService.isInitialized) {
      _showSnackBar('Camera chưa sẵn sàng');
      return;
    }

    setState(() {
      _uploading = true;
      _lastUploadError = null;
    });

    final timestamp = DateTime.now();
    final fileName = 'photo_${_fileNameFormat.format(timestamp)}.jpg';
    final rotationTurns = _rotationTurns % 4;

    try {
      final xFile = await _cameraService.capturePhoto();
      final file = await _persistCapture(xFile, fileName, rotationTurns);
      final previewBytes = await file.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _latestPreviewBytes = previewBytes;
      });

      final remotePath = await _uploadService.uploadFile(
        file: file,
        remoteDirectory: _selectedFolder,
        remoteFileName: fileName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lastUploadTime = DateTime.now();
        _lastRemotePath = remotePath;
        _lastUploadError = null;
      });

      _showSnackBar('Upload successful ✅');
    } on CameraException catch (error) {
      if (!mounted) return;

      setState(() {
        _cameraError = error;
      });

      if (error.code == 'missing_plugin') {
        _showCameraUnsupportedBanner();
      } else if (error.code == 'no_camera' || error.code == 'not_initialized') {
        _showSnackBar('No camera found');
      } else {
        _showSnackBar('Upload failed ❌');
      }
    } on FileSystemException catch (error) {
      if (!mounted) return;

      setState(() {
        _lastUploadError = error.message;
      });

      _showSnackBar('Upload failed ❌');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _lastUploadError = '$error';
      });

      _showSnackBar('Upload failed ❌');
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<File> _persistCapture(
    XFile file,
    String fileName,
    int rotationTurns,
  ) async {
    final directory = await getTemporaryDirectory();
    final targetPath = p.join(directory.path, fileName);
    await file.saveTo(targetPath);
    final savedFile = File(targetPath);

    if (rotationTurns % 4 != 0) {
      try {
        final bytes = await savedFile.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final rotated = img.copyRotate(
            decoded,
            angle: rotationTurns * 90,
          );
          final encoded = img.encodeJpg(rotated);
          await savedFile.writeAsBytes(encoded, flush: true);
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Không thể xoay ảnh: $error');
        }
      }
    }

    return savedFile;
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
    final picker = _RemoteDirectoryPicker(
      initialPath: _selectedFolder,
      service: _uploadService,
      presentation: (!kIsWeb && Platform.isWindows)
          ? _DirectoryPickerPresentation.sideSheet
          : _DirectoryPickerPresentation.bottomSheet,
    );

    if (!kIsWeb && Platform.isWindows) {
      return showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Chọn thư mục đích',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          final media = MediaQuery.of(context);
          final width = media.size.width;
          final sheetWidth = width >= 1200
              ? 460.0
              : math.min(width * 0.7, 460.0);

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

  void _showSnackBar(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showCameraUnsupportedBanner() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..clearMaterialBanners();

    final theme = Theme.of(context);
    final banner = MaterialBanner(
      backgroundColor: theme.colorScheme.errorContainer,
      contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onErrorContainer,
        fontWeight: FontWeight.w600,
      ),
      leading: Icon(
        Icons.warning_amber_rounded,
        color: theme.colorScheme.onErrorContainer,
      ),
      content: const Text(
        'Camera chưa được hỗ trợ trên nền tảng này. Vui lòng thử trên thiết bị khác.',
      ),
      actions: [
        TextButton(
          onPressed: () => messenger.hideCurrentMaterialBanner(),
          child: const Text('Đóng'),
        ),
      ],
    );

    messenger.showMaterialBanner(banner);

    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!mounted) {
        return;
      }
      messenger.hideCurrentMaterialBanner();
    });
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
            onPressed: _initializing ? null : () => _initializeCamera(camera: _selectedCamera),
          ),
        ],
      ),
      floatingActionButton: _buildCaptureFab(theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            Widget content = LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final previewCard = _buildPreviewCard(theme);
                final detailCard = _buildDetailsCard(theme);

                if (isWide) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: previewCard),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: detailCard),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  children: [
                    previewCard,
                    const SizedBox(height: 16),
                    detailCard,
                  ],
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
    );
  }

  Widget _buildCaptureFab(ThemeData theme) {
    final isEnabled = _cameraService.isInitialized && !_uploading && !_initializing;

    return FloatingActionButton.extended(
      onPressed: isEnabled ? _captureAndUpload : null,
      backgroundColor: theme.colorScheme.primary,
      label: _uploading
          ? const SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Đang tải lên...'),
                ],
              ),
            )
          : const SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded),
                  SizedBox(width: 12),
                  Text('Chụp & Upload'),
                ],
              ),
            ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    final controller = _cameraService.controller;
    final hasLivePreview = _cameraService.isInitialized && controller != null;
    final rotationTurns = _rotationTurns % 4;
    final rotationDegrees = rotationTurns * 90;

    double aspectRatio = 1;
    if (hasLivePreview) {
      final ratio = controller!.value.aspectRatio;
      if (ratio.isFinite && ratio > 0) {
        aspectRatio = ratio;
      }
    }
    final displayAspectRatio = rotationTurns.isOdd ? 1 / aspectRatio : aspectRatio;

    if (!hasLivePreview) {
      Widget placeholder;
      if (_initializing) {
        placeholder = _PreviewPlaceholder(
          icon: Icons.photo_camera_front_rounded,
          message: 'Đang khởi tạo camera...',
        );
      } else {
        final errorCode = _cameraError?.code;
        var errorMessage =
            _cameraError?.description ?? 'Không tìm thấy camera khả dụng.';
        if (errorCode == 'missing_plugin') {
          errorMessage =
              'Camera chưa được hỗ trợ trên nền tảng này. Vui lòng thử trên thiết bị khác.';
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

    final liveController = controller!;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double side;
            if (constraints.maxWidth.isFinite && constraints.maxHeight.isFinite) {
              side = math.min(constraints.maxWidth, constraints.maxHeight);
            } else if (constraints.maxWidth.isFinite) {
              side = constraints.maxWidth;
            } else if (constraints.maxHeight.isFinite) {
              side = constraints.maxHeight;
            } else {
              side = 360;
            }
            if (!side.isFinite || side <= 0) {
              side = 360;
            }
            var previewWidth = side;
            var previewHeight = side;
            if (displayAspectRatio >= 1) {
              previewWidth = side * displayAspectRatio;
              previewHeight = side;
            } else {
              previewHeight = side / displayAspectRatio;
              previewWidth = side;
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
                      child: CameraPreview(liveController),
                    ),
                  ),
                ),
                if (!_initializing && rotationDegrees != 0)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          '$rotationDegrees°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!_initializing)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          'Nhấn nút chụp để lưu ảnh và tải lên máy chủ WinSCP.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailsCard(ThemeData theme) {
    final cameras = _cameraService.cameras;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
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
            ),
            OutlinedButton.icon(
              onPressed: disableButtons ? null : _rotateRight,
              icon: const Icon(Icons.rotate_right_rounded),
              label: const Text('Phải 90°'),
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
                child: const Text('Đặt lại'),
              ),
          ],
        ),
      ],
    );
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
