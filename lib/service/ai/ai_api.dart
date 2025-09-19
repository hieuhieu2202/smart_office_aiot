import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/ApiConfig.dart'; // đảm bảo đúng tên file

class AiApi {
  static final AiApi _i = AiApi._();
  AiApi._();
  factory AiApi() => _i;

  final _client = http.Client();

  /// Gọi API chat (markdown trả về + nguồn + raw)
  Future<Map<String, dynamic>> ask({
    required String message,
    Map<String, Object?>? context,
  }) async {
    final url = Uri.parse(ApiConfig.chatEndpoint); // dùng đúng endpoint
    final bodyMap = {
      'message': message,
      'context': context ?? {},
    };
    final body = jsonEncode(bodyMap);

    // In debug thông tin endpoint & request body
    print('[AI API] POST → $url');
    print('[AI API] Body = $body');

    // Nếu server là self-signed HTTPS nội bộ, cần override trong dev
    HttpOverrides.global = _DevHttpOverrides();

    final res = await _client.post(
      url,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: body,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return data;
    }

    print('[AI API] ❌ Error ${res.statusCode}: ${res.body}');
    throw HttpException('HTTP ${res.statusCode}: ${res.body}');
  }
}

/// ⚠️ Chỉ dùng trong môi trường nội bộ/dev với chứng chỉ tự ký
class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? c) {
    final httpClient = super.createHttpClient(c);
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Cho phép IP nội bộ (tùy chỉnh theo IP server của bạn)
      return ApiConfig.allowSelfSignedFor(host);
    };
    return httpClient;
  }
}
