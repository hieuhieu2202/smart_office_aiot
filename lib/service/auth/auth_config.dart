
import 'package:smart_factory/service/auth/token_manager.dart';

class AuthConfig {
  static const String baseUrl = 'https://10.220.130.117:8008';
  static const String tokenEndpoint = '/connect/token';
  static const String clientId = 'smartfactoryapp';
  static const String clientSecret = 'smartfactoryapp';
  static String get token => TokenManager().civetToken.value;
  static Map<String, String> getAuthHeaders() {
    return {'Content-Type': 'application/x-www-form-urlencoded'};
  }

  static Map<String, String> getBaseParams(String grantType) {
    return {
      'client_id': clientId,
      'client_secret': clientSecret,
      'grant_type': grantType,
    };
  }

  static Map<String, String> getAuthorizedHeaders() {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}