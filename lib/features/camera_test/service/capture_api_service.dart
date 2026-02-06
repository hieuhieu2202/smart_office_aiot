import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:smart_factory/features/camera_test/model/capture_payload.dart';
import 'package:smart_factory/features/camera_test/model/capture_response.dart';

class CaptureApiService {
  static const String baseUrl =
      "http://192.168.0.117:2222/api/NVIDIA/SFCService/APP_PassVIStation";

  Future<CaptureResponse> sendCapture({
    required CapturePayload payload,
    List<XFile> images = const [],
  }) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse(baseUrl),
    );

    request.fields.addAll(payload.toFields());

    if (payload.result == "FAIL") {
      for (final img in images) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "images",
            img.path,
            filename: img.name,
          ),
        );
      }
    }

    final streamedRes = await request.send();
    final resBody = await streamedRes.stream.bytesToString();

    return CaptureResponse(statusCode: streamedRes.statusCode, body: resBody);
  }
}
