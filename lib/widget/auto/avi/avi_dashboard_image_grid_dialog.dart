import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../service/aoivi_dashboard_api.dart';
import 'image_fullscreen_page.dart';

class PTHDashboardImageGridDialog extends StatelessWidget {
  final String serialNumber;
  final String imageDetailsJson;

  const PTHDashboardImageGridDialog({
    super.key,
    required this.serialNumber,
    required this.imageDetailsJson,
  });

  @override
  Widget build(BuildContext context) {
    final List imageList =
        (imageDetailsJson.isNotEmpty)
            ? List<Map<String, dynamic>>.from(json.decode(imageDetailsJson))
            : [];

    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "Ảnh kiểm tra SN: $serialNumber",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
            imageList.isEmpty
                ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Không có ảnh chi tiết!"),
                )
                : Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: imageList.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemBuilder: (context, idx) {
                      final img = imageList[idx];
                      final isFail =
                          (img['Status'] ?? "").toString().toUpperCase() ==
                          "FAIL";

                      return GestureDetector(
                        onTap: () async {
                          final image = await PTHDashboardApi.fetchRawImage(
                            img['Path'],
                          );
                          if (image != null && context.mounted) {
                            Get.to(
                              () => ImageFullscreenPage(
                                image: image,
                                componentName: img['ComponentName'] ?? '',
                                status: img['Status'] ?? '',
                              ),
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            FutureBuilder<ImageProvider?>(
                              future: PTHDashboardApi.fetchRawImage(
                                img['Path'],
                              ),
                              builder: (ctx, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                if (!snap.hasData) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.red[200],
                                      size: 32,
                                    ),
                                  );
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image(
                                    image: snap.data!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isFail
                                          ? Colors.red[600]
                                          : Colors.green[600],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  img['Status'] ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            const SizedBox(height: 9),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text("Đóng"),
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
