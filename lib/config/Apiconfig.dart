class ApiConfig {
  static const bool isProduction = true;

  static String get baseUrl => isProduction
      ? 'https://10.220.130.117:5555' // Server thật
      : 'http://192.168.0.197:5511';  // Server local/dev

  // ===== FIXTURE =====
  static String get fixtureEndpoint => '$baseUrl/Fixture/GetFixtureByQr';
  static String get logFileBase     => '$baseUrl/Data/Fixture';

  // ===== SHEILDING BOX =====
  static String get shieldingEndpoint => '$baseUrl/Admin/SheildingBox/GetSheildingBoxByQr';
  static String get shieldingFileBase => '$baseUrl/Data/Shelingbox';

  /// Chuẩn hoá lại URL nếu server trả FileName tương đối
  static String normalizeUrl(String url) =>
      url.startsWith('http') ? url : '$baseUrl/$url';
}
