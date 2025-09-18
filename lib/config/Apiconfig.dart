class ApiConfig {
  static const bool isProduction = true;

  static String get baseUrl => isProduction
      ? 'https://10.220.130.117:5555' // Server thật
      : 'http://192.168.0.197:5511'; // Server local/dev

  /// Context path (prefix) for the RemoteControl notification API.
  ///
  /// Đổi giá trị này nếu server dev/prod đặt ở đường dẫn khác.
  static const String _notificationContextPath = '/SendNoti';

  static String get notificationBaseUrl {
    final baseHost = isProduction
        ? 'http://10.220.130.117:2222'
        : 'http://192.168.0.197:5511';

    final context = _notificationContextPath.trim();
    if (context.isEmpty) {
      return baseHost;
    }

    if (context.startsWith('/')) {
      return '$baseHost$context';
    }

    return '$baseHost/$context';
  }

  static const String notificationAppKey = 'smartfactoryapp';

  // ===== FIXTURE =====
  static String get fixtureEndpoint => '$baseUrl/Fixture/GetFixtureByQr';
  static String get logFileBase     => '$baseUrl/Data/Fixture';

  // ===== SHEILDING BOX =====
  static String get shieldingEndpoint => '$baseUrl/Admin/SheildingBox/GetSheildingBoxByQr';
  static String get shieldingFileBase => '$baseUrl/Data/Shelingbox';

  /// Chuẩn hoá lại URL nếu server trả FileName tương đối
  static String normalizeUrl(String url) =>
      url.startsWith('http') ? url : '$baseUrl/$url';

  static String normalizeNotificationUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = notificationBaseUrl.endsWith('/')
        ? notificationBaseUrl.substring(0, notificationBaseUrl.length - 1)
        : notificationBaseUrl;
    if (url.startsWith('/')) {
      return '$base$url';
    }
    return '$base/$url';
  }
}
