import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageFullscreenPage extends StatelessWidget {
  final ImageProvider image;
  final String componentName;
  final String status;

  const ImageFullscreenPage({
    super.key,
    required this.image,
    required this.componentName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isFail = status.toUpperCase() == "FAIL";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                panEnabled: true,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Image(
                    image: image,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              );
            },
          ),
          // Overlay thông tin như cũ
          Positioned(
            bottom: 40,
            left: 20,
            child: Text(
              componentName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    status.toUpperCase() == 'FAIL'
                        ? Colors.redAccent
                        : Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
          Positioned(
            top: 36,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }
}
