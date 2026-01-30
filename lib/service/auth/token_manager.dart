import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'auth_config.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();

  factory TokenManager() => _instance;

  TokenManager._internal();

  var civetToken = ''.obs;
  var refreshToken = ''.obs;

  void loadTokens(GetStorage box) {
    civetToken.value = box.read('access_token') ?? '';
    refreshToken.value = box.read('refresh_token') ?? '';
  }

  void saveTokens(Map<String, dynamic> data, GetStorage box) {
    civetToken.value = data['access_token'];
    refreshToken.value = data['refresh_token'];
    box.write('access_token', civetToken.value);
    box.write('refresh_token', refreshToken.value);
  }

  void clearTokens(GetStorage box) {
    civetToken.value = '';
    refreshToken.value = '';
    box.remove('access_token');
    box.remove('refresh_token');
  }

  Future<void> refreshAccessToken(
    GetStorage box,
    Function logoutCallback,
  ) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

      HttpClientRequest request = await client.postUrl(
        Uri.parse('${AuthConfig.baseUrl}${AuthConfig.tokenEndpoint}'),
      );
      // Thêm headers từng cái một thay vì addAll
      AuthConfig.getAuthHeaders().forEach((key, value) {
        request.headers.set(key, value);
      });
      Map<String, String> params = AuthConfig.getBaseParams('refresh_token');
      params['refresh_token'] = refreshToken.value;

      final query = Uri(queryParameters: params).query;
      request.write(query);

      HttpClientResponse response = await request.close();
      String responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        saveTokens(data, box);
        _startRefreshTimer(box, logoutCallback);
      } else {
        logoutCallback();
      }
    } catch (e) {
      // Xử lý lỗi mà không cần toast
    }
  }

  void _startRefreshTimer(GetStorage box, Function logoutCallback) {
    if (civetToken.value.isNotEmpty) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(civetToken.value);
      int exp = decodedToken['exp'];
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int timeToExpire = exp - now;

      int refreshTime = timeToExpire > 300 ? timeToExpire - 300 : timeToExpire;
      if (refreshTime > 0) {
        Future.delayed(Duration(seconds: refreshTime), () {
          refreshAccessToken(box, logoutCallback);
        });
      }
    }
  }

  int getRefreshTime() {
    if (civetToken.value.isNotEmpty) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(civetToken.value);
      int exp = decodedToken['exp'];
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int timeToExpire = exp - now;
      return timeToExpire > 300 ? timeToExpire - 300 : timeToExpire;
    }
    return 0;
  }

  String get userId {
    if (civetToken.value.isEmpty) return "";

    try {
      Map<String, dynamic> decoded = JwtDecoder.decode(civetToken.value);

      return decoded["sub"] ??
          decoded["employeeId"] ??
          decoded["id"] ??
          decoded["cardId"] ??
          decoded["UserId"] ??
          decoded["preferred_username"] ??
          "";
    } catch (e) {
      return "";
    }
  }
}
