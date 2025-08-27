import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final PhotoViewController _controller = PhotoViewController();

  FullScreenImage({super.key, required this.imageUrl});

  Future<void> _saveImage() async {
    // Yêu cầu quyền (Android 13+ cần photos, Android <13 cần storage)
    final photosStatus = await Permission.photos.request();
    final storageStatus = await Permission.storage.request();

    if (!photosStatus.isGranted && !storageStatus.isGranted) {
      Get.snackbar(
        'Lỗi',
        'Quyền truy cập bị từ chối. Vui lòng cấp quyền trong cài đặt.',
        snackPosition: SnackPosition.BOTTOM,
        mainButton: TextButton(
          onPressed: () => openAppSettings(),
          child: const Text('Mở cài đặt'),
        ),
      );
      return;
    }

    try {
      // Tải ảnh từ URL
      final response = await http.get(Uri.parse(imageUrl));
      final Uint8List imageBytes = response.bodyBytes;

      // Lưu ảnh
      final result = await ImageGallerySaverPlus.saveImage(
        imageBytes,
        name: "smart_factory_${DateTime.now().millisecondsSinceEpoch}",
        // isReturnPathOfIOS: true,
      );

      if ((result['isSuccess'] ?? false) == true) {
        Get.snackbar(
          'Thành công',
          'Ảnh đã được lưu vào Thư viện ảnh',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể lưu ảnh',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Lỗi khi lưu ảnh: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            controller: _controller,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 5,
            loadingBuilder:
                (context, event) =>
                    const Center(child: CircularProgressIndicator()),
            errorBuilder:
                (context, error, stackTrace) => const Center(
                  child: Text(
                    'Không thể tải hình ảnh',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 30,
                      ),
                      color: Colors.black.withOpacity(0.5),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                      onSelected: (String value) {
                        if (value == 'download') {
                          _saveImage();
                        }
                      },
                      itemBuilder:
                          (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'download',
                              child: ListTile(
                                leading: Icon(
                                  Icons.download,
                                  color: Colors.white,
                                ),
                                title: Text(
                                  'Tải xuống',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
