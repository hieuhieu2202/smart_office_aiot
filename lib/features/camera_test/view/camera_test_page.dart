import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/bantha.dart';
import 'package:smart_factory/features/camera_test/controller/camera_test_controller.dart';
import 'package:smart_factory/features/camera_test/model/error_item.dart';
import 'camera_capture_screen.dart';
import 'package:smart_factory/features/camera_test/service/pda_serial_parser.dart';

class CameraTestPage extends StatefulWidget {
  const CameraTestPage({super.key});

  @override
  State<CameraTestPage> createState() => _CameraTestPageState();
}

class _CameraTestPageState extends State<CameraTestPage> {
  late final CameraTestController viewModel;
  final FocusNode serialFocus = FocusNode();
  bool _isParsing = false;

  @override
  void initState() {
    super.initState();
    viewModel = Get.put(CameraTestController());
    viewModel.serialCtrl.addListener(_handlePdaInput);

    Future.delayed(const Duration(milliseconds: 300), () {
      serialFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    viewModel.serialCtrl.removeListener(_handlePdaInput);
    Get.delete<CameraTestController>();
    serialFocus.dispose();
    super.dispose();
  }

  void _handlePdaInput() {
    if (_isParsing) return;

    final raw = viewModel.serialCtrl.text.trim();
    if (raw.isEmpty) return;

    final parsed = PdaSerialParser.extractSerial(raw);

    if (parsed.isNotEmpty && parsed != raw) {
      _isParsing = true;

      viewModel.serialCtrl
        ..text = parsed
        ..selection = TextSelection.collapsed(offset: parsed.length);

      _isParsing = false;
    }
  }

  // ================= ERROR SEARCH =================

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
                      decoration:
                      _inputStyle("Tìm Error Code / Error Name"),
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
                            style:
                            const TextStyle(color: Colors.white70),
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

  // ================= FORM =================

  Widget _formContent() {
    final isFail = viewModel.result == "FAIL";

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _imageSection(isFail),
          const SizedBox(height: 16),
          _productSection(),
          const SizedBox(height: 16),
          _resultSection(isFail),
          const SizedBox(height: 16),
          _commentSection(),
          const SizedBox(height: 20),
          _submitButtons(),
        ],
      ),
    );
  }

  // ================= IMAGE =================

  Widget _imageSection(bool isFail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFail ? const Color(0xFF1A0F0F) : const Color(0xFF101014),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFail
              ? Colors.redAccent.withOpacity(0.6)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 10),

          if (viewModel.captured.isNotEmpty)
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: viewModel.captured.length,
                separatorBuilder: (_, __) =>
                const SizedBox(width: 10),
                itemBuilder: (_, i) => Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FullImageView(path: viewModel.captured[i].path),
                          ),
                        );
                      },
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
                        onTap: () =>
                            viewModel.removeCapturedAt(i),
                        child: const Icon(Icons.close,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              isFail
                  ? "FAIL bắt buộc phải có ảnh."
                  : "Chưa có ảnh.",
              style: TextStyle(
                color:
                isFail ? Colors.redAccent : Colors.white70,
              ),
            ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: viewModel.capture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Chụp ảnh"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                  viewModel.pickImagesFromDevice,
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

  // ================= PRODUCT =================

  Widget _productSection() {
    return _sectionCard(
      title: "📦 Thông tin sản phẩm",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: viewModel.selectedFactory,
                  decoration: _inputStyle("Factory"),
                  dropdownColor: Colors.black,
                  items: viewModel.factories
                      .map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f,
                        style: const TextStyle(
                            color: Colors.white)),
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
                  value: viewModel.selectedFloor,
                  decoration: _inputStyle("Floor"),
                  dropdownColor: Colors.black,
                  items: viewModel.floors
                      .map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f,
                        style: const TextStyle(
                            color: Colors.white)),
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
                  style:
                  const TextStyle(color: Colors.white54),
                  decoration: _inputStyle("Username"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: viewModel.stationCtrl.text.isEmpty
                ? null
                : viewModel.stationCtrl.text,
            decoration: _inputStyle("Station"),
            dropdownColor: Colors.black,
            items: BanthaConfig.stationsOf(
                viewModel.selectedFactory ?? "",
                viewModel.selectedFloor ?? "")
                .map((s) => DropdownMenuItem(
              value: s,
              child: Text(s,
                  style: const TextStyle(
                      color: Colors.white)),
            ))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              viewModel.onStationChanged(val);
            },
          ),

          const SizedBox(height: 14),

          TextField(
            focusNode: serialFocus,
            controller: viewModel.serialCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _inputStyle("Serial Number"),
          ),
        ],
      ),
    );
  }

  // ================= RESULT =================

  Widget _resultSection(bool isFail) {
    return _sectionCard(
      title: "🧪 Kết quả kiểm tra",
      highlightFail: isFail,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: viewModel.result,
            decoration: _inputStyle("Result"),
            dropdownColor: Colors.black,
            items: const [
              DropdownMenuItem(
                  value: "PASS", child: Text("PASS")),
              DropdownMenuItem(
                  value: "FAIL", child: Text("FAIL")),
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
                  style:
                  const TextStyle(color: Colors.white),
                  decoration:
                  _inputStyle("Error Code").copyWith(
                    suffixIcon: const Icon(Icons.search,
                        color: Colors.white54),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: viewModel.errorNameCtrl,
              readOnly: true,
              style:
              const TextStyle(color: Colors.white70),
              decoration: _inputStyle("Error Name"),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: viewModel.errorDescCtrl,
              maxLines: 2,
              style:
              const TextStyle(color: Colors.white),
              decoration:
              _inputStyle("Error Description"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _commentSection() {
    return _sectionCard(
      title: "📝 Ghi chú",
      child: TextField(
        controller: viewModel.noteCtrl,
        maxLines: 3,
        style: const TextStyle(color: Colors.white),
        decoration: _inputStyle("Comment"),
      ),
    );
  }

  Widget _submitButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () =>
                viewModel.sendToApi(viewModel.captured),
            child: const Text("🚀 Gửi dữ liệu"),
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
          Text(title,
              style: TextStyle(
                color: highlightFail
                    ? Colors.redAccent
                    : Colors.white70,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
      const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF111111),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CameraTestController>(
      builder: (_) {
        if (viewModel.state == TestState.idle) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              serialFocus.requestFocus();
            }
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xff0d0d11),
          appBar: AppBar(
            backgroundColor: const Color(0xff0d0d11),
            title: const Text("Capture"),
          ),
          body: Stack(
            children: [
              _formContent(),

              if (viewModel.state == TestState.uploading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  Colors.greenAccent),
                            ),
                          ),
                          SizedBox(height: 14),
                          Text(
                            "Đang gửi dữ liệu...",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Vui lòng chờ",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
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
      },
    );
  }
}