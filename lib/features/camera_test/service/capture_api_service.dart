import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:smart_factory/features/camera_test/model/capture_payload.dart';
import 'package:smart_factory/features/camera_test/model/capture_response.dart';

class CaptureApiService {
  static const String baseUrl =
      "http://10.220.130.117:2222/api/APP/SFCNVIDIA/PassVIStation";

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

    // ===== DEBUG LOG =====
    print("=========== REQUEST DEBUG ===========");
    print("URL: $baseUrl");

    print("---- FIELDS ----");
    request.fields.forEach((key, value) {
      print("$key = '$value' (length: ${value.length})");
    });

    print("---- FILES ----");
    for (var file in request.files) {
      print("file field: ${file.field} | filename: ${file.filename}");
    }
    print("=====================================");
    // ===== END DEBUG =====

    final streamedRes = await request.send();
    final resBody = await streamedRes.stream.bytesToString();

    print("=========== RESPONSE DEBUG ===========");
    print("Status: ${streamedRes.statusCode}");
    print("Body: $resBody");
    print("======================================");

    return CaptureResponse(
      statusCode: streamedRes.statusCode,
      body: resBody,
    );
  }
}
