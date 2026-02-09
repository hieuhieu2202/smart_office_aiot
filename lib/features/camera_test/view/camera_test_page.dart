import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/bantha.dart';
import 'package:smart_factory/features/camera_test/controller/camera_test_controller.dart';
import 'package:smart_factory/features/camera_test/model/error_item.dart';

class CameraTestPage extends StatefulWidget {
  final bool autoScan;
  const CameraTestPage({super.key, this.autoScan = false});

  @override
  State<CameraTestPage> createState() => _CameraTestPageState();
}

class _CameraTestPageState extends State<CameraTestPage> {
  late final CameraTestController viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = Get.put(CameraTestController(autoScan: widget.autoScan));
  }

  @override
  void dispose() {
    Get.delete<CameraTestController>();
    super.dispose();
  }

  void _openErrorCodeSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F13),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final searchCtrl = TextEditingController();
        List<ErrorItem> filtered = BanthaConfig.errorCodes;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void onSearch(String q) {
              setSheetState(() {
                final s = q.toLowerCase();
                filtered = BanthaConfig.errorCodes.where((e) {
                  return e.code.toLowerCase().contains(s) ||
                      e.name.toLowerCase().contains(s);
                }).toList();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      onChanged: onSearch,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Tìm Error Code / Error Name",
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                        const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        return ListTile(
                          title: Text(
                            e.code,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            e.name,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onTap: () {
                            viewModel.errorCodeCtrl.text = e.code;
                            viewModel.errorNameCtrl.text = e.name;
                            viewModel.update();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // CAMERA + ZOOM
  Widget _cameraUI() {
    // Scan mode: before scan -> show prompt. After scan -> show stable background.
    if (viewModel.isScanMode && !viewModel.showCameraPreview) {
      if (!viewModel.hasScannedQr) {
        return const Center(
          child: Text(
            "Vui lòng quét QR để bắt đầu.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        );
      }
      return const ColoredBox(color: Color(0xff0d0d11));
    }

    final cameraController = viewModel.cameraController;

    if (viewModel.isScanMode &&
        viewModel.showCameraPreview &&
        viewModel.isInitializingCamera) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (cameraController == null ||
        !(cameraController.value.isInitialized)) {
      return const Center(
        child: Text("Đang khởi tạo camera...", style: TextStyle(color: Colors.white70)),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onScaleUpdate: (details) async {
              await viewModel.updateZoom(details.scale);
            },
            child: CameraPreview(cameraController),
          ),
        ),

        // Scan mode preview controls (close + shutter)
        if (viewModel.isScanMode && viewModel.showCameraPreview) ...[
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              tooltip: "Đóng camera",
              onPressed: viewModel.closeCameraPreview,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: viewModel.takePhotoFromPreview,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
          ),
        ],

        // NÚT ZOOM + / -
        if (!viewModel.isScanMode || !viewModel.showCameraPreview)
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                _zoomBtn(Icons.add, viewModel.zoomIn),
                const SizedBox(height: 10),
                _zoomBtn(Icons.remove, viewModel.zoomOut),
              ],
            ),
          ),
      ],
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // -----------------------------------------------------
  // THUMBNAILS – PHONE
  // -----------------------------------------------------
  Widget _thumbnailRow() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.captured.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.all(6),
          child: _thumbnail(i, 80),
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // THUMBNAILS – TABLET GRID
  // -----------------------------------------------------
  Widget _thumbnailGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: viewModel.captured.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) => Center(
        child: _thumbnail(i, 130), // Force thumbnail fixed size
      ),
    );
  }

  // -----------------------------------------------------
  // THUMBNAIL ITEM
  // -----------------------------------------------------
  Widget _thumbnail(int i, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FullImageView(path: viewModel.captured[i].path)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(viewModel.captured[i].path),
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => viewModel.removeCapturedAt(i),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------
  // BUTTONS – PHONE
  // -----------------------------------------------------
  Widget _phoneButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: "btn_cancel_phone",
          backgroundColor: Colors.red,
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.close),
        ),
        FloatingActionButton(
          heroTag: "btn_capture_phone",
          backgroundColor: Colors.blue,
          onPressed: viewModel.capture,
          child: const Icon(Icons.camera_alt),
        ),
        FloatingActionButton(
          heroTag: "btn_done_phone",
          backgroundColor: Colors.green,
          onPressed: () async {
            if (viewModel.captured.isEmpty) {
              Get.snackbar("Lỗi", "Chưa chụp ảnh");
              return;
            }
            await viewModel.finishCapture();
          },
          child: const Icon(Icons.check),
        ),
      ],
    );
  }

  // -----------------------------------------------------
  // BUTTONS – TABLET
  // -----------------------------------------------------
  Widget _tabletButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: "btn_cancel_tablet",
          backgroundColor: Colors.red,
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.close),
        ),
        FloatingActionButton(
          heroTag: "btn_capture_tablet",
          backgroundColor: Colors.blue,
          onPressed: viewModel.capture,
          child: const Icon(Icons.camera_alt),
        ),
        FloatingActionButton(
          heroTag: "btn_done_tablet",
          backgroundColor: Colors.green,
          onPressed: () async {
            if (viewModel.captured.isEmpty) {
              Get.snackbar("Lỗi", "Chưa chụp ảnh");
              return;
            }
            await viewModel.finishCapture();
          },
          child: const Icon(Icons.check),
        ),
      ],
    );
  }

  // -----------------------------------------------------
  // FORM OVERLAY
  // -----------------------------------------------------
  Widget _formOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: SafeArea(
          child: Stack(
            children: [
              // Content
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      // _imagePreviewStrip(),
                      // const SizedBox(height: 16),
                      _formContent(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade800,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                viewModel.cancelCapture();
                              },
                              child: const Text("Hủy"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => viewModel.sendToApi(viewModel.captured),
                              child: const Text("🚀 Gửi dữ liệu"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // NOTE: Removed the top-right close (X) button as requested.
            ],
          ),
        ),
      ),
    );
  }

  // Widget _imagePreviewStrip() {
  //   if (viewModel.captured.isEmpty) {
  //     return Container(
  //       width: double.infinity,
  //       padding: const EdgeInsets.all(14),
  //       decoration: BoxDecoration(
  //         color: const Color(0xFF101014),
  //         borderRadius: BorderRadius.circular(14),
  //         border: Border.all(color: Colors.white.withOpacity(0.06)),
  //       ),
  //       child: const Text(
  //         "Chưa có ảnh. Nếu FAIL, vui lòng chụp hoặc chọn ảnh ở bên dưới.",
  //         style: TextStyle(color: Colors.white70),
  //       ),
  //     );
  //   }
  //
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.symmetric(vertical: 10),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF101014),
  //       borderRadius: BorderRadius.circular(14),
  //       border: Border.all(color: Colors.white.withOpacity(0.06)),
  //     ),
  //     child: SizedBox(
  //       height: 96,
  //       child: ListView.separated(
  //         padding: const EdgeInsets.symmetric(horizontal: 10),
  //         scrollDirection: Axis.horizontal,
  //         itemCount: viewModel.captured.length,
  //         separatorBuilder: (_, __) => const SizedBox(width: 10),
  //         itemBuilder: (_, i) {
  //           return Stack(
  //             children: [
  //               GestureDetector(
  //                 onTap: () => Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (_) => FullImageView(path: viewModel.captured[i].path),
  //                   ),
  //                 ),
  //                 child: ClipRRect(
  //                   borderRadius: BorderRadius.circular(10),
  //                   child: Image.file(
  //                     File(viewModel.captured[i].path),
  //                     width: 96,
  //                     height: 96,
  //                     fit: BoxFit.cover,
  //                   ),
  //                 ),
  //               ),
  //               Positioned(
  //                 right: 6,
  //                 top: 6,
  //                 child: GestureDetector(
  //                   onTap: () => setState(() => viewModel.captured.removeAt(i)),
  //                   child: Container(
  //                     padding: const EdgeInsets.all(4),
  //                     decoration: BoxDecoration(
  //                       color: Colors.black.withOpacity(0.55),
  //                       shape: BoxShape.circle,
  //                       border: Border.all(color: Colors.white.withOpacity(0.2)),
  //                     ),
  //                     child: const Icon(Icons.close, size: 14, color: Colors.white),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  Widget _imageActionRow() {
    final caption = viewModel.captured.isEmpty
        ? "Chưa có ảnh"
        : "Đã thêm ${viewModel.captured.length} ảnh";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(caption, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: viewModel.capture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Chụp ảnh"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: viewModel.pickImagesFromDevice,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Chọn ảnh"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // FORM CONTENT

  Widget _formContent() {
    final bool isFail = viewModel.result == "FAIL";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        //  IMAGE CARD
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFail ? const Color(0xFF1A0F0F) : const Color(0xFF0F1A12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFail
                  ? Colors.redAccent.withOpacity(0.6)
                  : Colors.greenAccent.withOpacity(0.5),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // HEADER
              Row(
                children: [
                  Text(
                    isFail
                        ? "Ảnh lỗi (bắt buộc khi FAIL)"
                        : "Ảnh kiểm tra",
                    style: TextStyle(
                      color: isFail ? Colors.redAccent : Colors.greenAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 10),

              // THUMBNAILS
              if (viewModel.captured.isNotEmpty)
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: viewModel.captured.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FullImageView(path: viewModel.captured[i].path),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(viewModel.captured[i].path),
                              width: 86,
                              height: 86,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => viewModel.removeCapturedAt(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    isFail
                        ? "Chưa có ảnh. FAIL bắt buộc phải có ảnh."
                        : "Chưa có ảnh.",
                    style: TextStyle(
                      color: isFail
                          ? Colors.redAccent
                          : Colors.white70,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // ACTION BUTTONS
              _imageActionRow(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // PRODUCT INFO
        _sectionCard(
          title: "📦 Thông tin sản phẩm",
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: viewModel.selectedFactory,
                      decoration: _inputStyle("Factory"),
                      dropdownColor: Colors.black,
                      items: viewModel.factories
                          .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(
                          f,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        viewModel.factoryCtrl.text = val;
                        viewModel.onFactoryChanged(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: viewModel.selectedFloor,
                      decoration: _inputStyle("Floor"),
                      dropdownColor: Colors.black,
                      items: viewModel.floors
                          .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(
                          f,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        viewModel.onFloorChanged(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: viewModel.userCtrl,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white54),
                      decoration: _inputStyle("Username"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value:
                viewModel.stationCtrl.text.isEmpty ? null : viewModel.stationCtrl.text,
                decoration: _inputStyle("Station"),
                dropdownColor: Colors.black,
                items: BanthaConfig
                    .stationsOf(
                    viewModel.selectedFactory ?? "", viewModel.selectedFloor ?? "")
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s,
                    style:
                    const TextStyle(color: Colors.white),
                  ),
                ))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  viewModel.onStationChanged(val);
                },
              ),

              const SizedBox(height: 14),
              TextField(
                controller: viewModel.modelnameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle("Model Name"),
              ),

              const SizedBox(height: 14),
              TextField(
                controller: viewModel.serialCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle("Serial Number"),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // RESULT
        _sectionCard(
          title: "🧪 Kết quả kiểm tra",
          highlightFail: isFail,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: viewModel.result,
                decoration: _inputStyle("Result"),
                dropdownColor: Colors.black,
                items: const [
                  DropdownMenuItem(value: "PASS", child: Text("PASS")),
                  DropdownMenuItem(value: "FAIL", child: Text("FAIL")),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  viewModel.setResult(v);
                },
              ),
              if (isFail) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _openErrorCodeSearch,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: viewModel.errorCodeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle("Error Code").copyWith(
                        suffixIcon: const Icon(Icons.search, color: Colors.white54),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: viewModel.errorNameCtrl,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white70),
                  decoration: _inputStyle("Error Name"),
                ),

                const SizedBox(height: 14),
                TextField(
                  controller: viewModel.errorDescCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                  _inputStyle("Error Description"),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // COMMENT
        _sectionCard(
          title: "📝 Ghi chú",
          child: TextField(
            controller: viewModel.noteCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: _inputStyle("Comment"),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    bool highlightFail = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlightFail
            ? const Color(0xFF1A0F0F)
            : const Color(0xFF101014),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlightFail
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: highlightFail
                      ? Colors.redAccent
                      : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }


  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 12,
      ),
      filled: true,
      fillColor: const Color(0xFF111111),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _phoneUI() {
    final bool isScanMode = viewModel.isScanMode;

    // In scan mode, NEVER show the form overlay on top of the camera preview.
    final bool showFormOverlay = isScanMode
        ? (!viewModel.showCameraPreview &&
            ((viewModel.state == TestState.doneCapture ||
                    viewModel.state == TestState.captured) ||
                viewModel.showScanForm))
        : (viewModel.state == TestState.doneCapture ||
            viewModel.state == TestState.captured);

    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: _cameraUI()),

            // In scan mode, hide viewModel.capture thumbnails + buttons to avoid confusing UI.
            if (!isScanMode) ...[
              _thumbnailRow(),
              _phoneButtons(),
            ],
          ],
        ),
        if (showFormOverlay) _formOverlay(),
        if (viewModel.state == TestState.uploading) _uploadOverlay(),
      ],
    );
  }

  Widget _tabletUI() {
    final bool isScanMode = viewModel.isScanMode;

    // In scan mode, NEVER show the form overlay on top of the camera preview.
    final bool showFormOverlay = isScanMode
        ? (!viewModel.showCameraPreview &&
            ((viewModel.state == TestState.doneCapture ||
                    viewModel.state == TestState.captured) ||
                viewModel.showScanForm))
        : (viewModel.state == TestState.doneCapture ||
            viewModel.state == TestState.captured);

    if (isScanMode) {
      return Stack(
        children: [
          Positioned.fill(child: _cameraUI()),
          if (showFormOverlay) _formOverlay(),
          if (viewModel.state == TestState.uploading) _uploadOverlay(),
        ],
      );
    }

    // Non-scan tablet UI: keep using the same camera UI + overlay viewModel.states.
    return Stack(
      children: [
        Positioned.fill(child: _cameraUI()),
        if (showFormOverlay) _formOverlay(),
        if (viewModel.state == TestState.uploading) _uploadOverlay(),
      ],
    );
  }

  /// Standalone form (no Positioned) to safely render as a normal page body.
  /// This is used in scan mode right after QR scanned to avoid the "black screen" issue.
  Widget _formStandalone() {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // _imagePreviewStrip(),
              // const SizedBox(height: 16),
              _formContent(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        viewModel.cancelCapture();
                      },
                      child: const Text("Hủy"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => viewModel.sendToApi(viewModel.captured),
                      child: const Text("🚀 Gửi dữ liệu"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // Main content for scan mode AFTER scanning.
  // Render standalone form (no Positioned.fill) to guarantee it shows up.
  Widget _scanBody() {
    return Stack(
      children: [
        const ColoredBox(color: Color(0xff0d0d11)),
        _formStandalone(),
        if (viewModel.state == TestState.uploading) _uploadOverlay(),
      ],
    );
  }

  Widget _uploadOverlay() {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.cloud_upload, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                "Đang gửi dữ liệu...",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Vui lòng chờ trong giây lát",
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 14),
              const SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Color(0xFF2E2E36),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // RESPONSIVE + ROOT BUILD
  // -----------------------------------------------------
  bool isTablet(BuildContext context) => MediaQuery.of(context).size.width > 900;

  bool get _isBusy => viewModel.state == TestState.uploading;

  Future<bool> _onWillPop() async {
    if (_isBusy) return false;
    return viewModel.handleWillPop();
  }


  @override
  Widget build(BuildContext context) {
    return GetBuilder<CameraTestController>(
      builder: (_) {
        return PopScope(
          canPop: !_isBusy,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final allow = await _onWillPop();
            if (allow && mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop(result);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xff0d0d11),
            appBar: AppBar(
              backgroundColor: const Color(0xff0d0d11),
              title: const Text("Capture"),
            ),
            body: SafeArea(
              child: viewModel.isScanMode &&
                      viewModel.showScanForm &&
                      !viewModel.showCameraPreview
                  ? _scanBody()
                  : (isTablet(context) ? _tabletUI() : _phoneUI()),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// VIEW FULL IMAGE
// ---------------------------------------------------------
class FullImageView extends StatelessWidget {
  final String path;
  const FullImageView({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}
