class AuthConfig {
  static const String baseUrl = 'https://10.220.23.244';
  static const String tokenEndpoint = '/connect/token';
  static const String clientId = 'smartfactoryapp';
  static const String clientSecret = 'smartfactoryapp';

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
}