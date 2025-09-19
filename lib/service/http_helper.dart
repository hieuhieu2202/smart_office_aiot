import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class HttpHelper {
  static final HttpHelper _i = HttpHelper._();
  HttpHelper._();
  factory HttpHelper() => _i;

  late final IOClient _client = _buildClient();

  IOClient _buildClient() {
    final io = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        /// DEV ONLY: chấp nhận cert tự ký cho IP nội bộ
        return host == '10.220.130.117';
      };
    return IOClient(io);
  }

  Future<http.Response> get(Uri uri,
      {Map<String, String>? headers, Duration? timeout}) async {
    final t = timeout ?? const Duration(seconds: 20);
    final res = await _client.get(uri, headers: headers).timeout(t);
    if (res.statusCode == 405) {
      /// SỬA: backend chỉ cho POST → thử POST rỗng
      final res2 = await _client
          .post(uri, headers: headers, body: jsonEncode({}))
          .timeout(t);
      return res2;
    }
    return res;
  }

  Future<http.Response> post(Uri uri,
      {Map<String, String>? headers, Object? body, Duration? timeout}) async {
    final t = timeout ?? const Duration(seconds: 20);
    return _client.post(uri, headers: headers, body: body).timeout(t);
  }
}
