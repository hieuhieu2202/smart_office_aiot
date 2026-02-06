import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_factory/features/camera_test/model/capture_payload.dart';

class CaptureApiService {
  CaptureApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl =
      'http://192.168.0.62:2020/api/Detail/upload';

  final http.Client _client;

  Future<http.Response> send(CapturePayload payload) {
    return _client.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload.toJson()),
    );
  }
}
