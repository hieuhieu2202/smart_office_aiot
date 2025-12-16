import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:smart_factory/service/camera/product_capture_api.dart';
import 'package:smart_factory/model/Camera/product_capture_payload.dart';
import 'package:smart_factory/model/Camera/product_capture_response.dart';

class ProductCaptureController extends GetxController {


  var serial = "".obs;
  var status = "PASS".obs;
  var user = "".obs;
  var note = "".obs;

  var capturedFile = Rx<XFile?>(null);
  var isUploading = false.obs;

  // ==========================
  // HANDLE IMAGE → BASE64
  // ==========================

  Future<String> convertToBase64(XFile file) async {
    final bytes = await File(file.path).readAsBytes();
    return base64Encode(bytes);
  }

  // ==========================
  // SEND API
  // ==========================

  Future<ProductCaptureResponse?> send() async {
    if (capturedFile.value == null) {
      Get.snackbar("Lỗi", "Chưa có ảnh để gửi");
      return null;
    }

    try {
      isUploading.value = true;

      final base64Img = await convertToBase64(capturedFile.value!);

      final payload = ProductCapturePayload(
        serial: serial.value,
        status: status.value,
        user: user.value,
        imageBase64: base64Img,
        time: DateTime.now().toIso8601String(),
        note: note.value,
      );

      final response = await ProductCaptureApi.send(payload);

      if (response.success) {
        Get.snackbar("Thành công", response.message);
      } else {
        Get.snackbar("Thất bại", response.message);
      }

      return response;
    } catch (e) {
      Get.snackbar("Lỗi", e.toString());
      return null;
    } finally {
      isUploading.value = false;
    }
  }
}
