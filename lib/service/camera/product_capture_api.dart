import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../model/Camera/product_capture_payload.dart';
import '../../model/Camera/product_capture_response.dart';

class ProductCaptureApi {
  static const String baseUrl =
      "http://192.168.0.62:2020/api/Detail/upload";

  static Future<ProductCaptureResponse> send(
      ProductCapturePayload data) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: { "Content-Type": "application/json" },
      body: jsonEncode(data.toJson()),
    );

    final json = jsonDecode(res.body);

    return ProductCaptureResponse.fromJson(json);
  }
}
