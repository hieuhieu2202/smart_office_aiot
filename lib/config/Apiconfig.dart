class ApiConfig {
  // ========== BẬT/TẮT chế độ production ==========
  static const bool isProduction = true;

  // ========== API chính: Fixture, ShieldingBox ==========
  static String get baseUrl => isProduction
      ? 'https://10.220.130.117:5555' // Server thật
      : 'http://192.168.0.197:5511'; // Server local/dev

  /// Context path (prefix) for the RemoteControl notification API.
  ///
  /// Đổi giá trị này nếu server dev/prod đặt ở đường dẫn khác.
  static const String _notificationContextPath = '/SendNoti';

  static String get _notificationHost => isProduction
      ? 'http://10.220.130.117:2222'
      : 'http://192.168.0.197:5511';

  static String get notificationBaseUrl {
    final context = _notificationContextPath.trim();
    if (context.isEmpty) {
      return _notificationHost;
    }

    final prefix = context.startsWith('/') ? context : '/$context';
    return '$_notificationHost$prefix';
  }

  static const String notificationAppKey = 'smartfactoryapp';

  // ========== Chat AI Web API ==========
  static String get chatBaseUrl => isProduction
      ? 'http://10.220.130.117:2222/ChatAI' // Server thật (virtual folder /ChatAI)
      : 'http://192.168.0.197:2323/ChatAI'; // Local/dev

  static String get chatEndpoint => '$chatBaseUrl/ai/chat';

  // ========== Cho phép chứng chỉ tự ký ==========
  static bool allowSelfSignedFor(String host) {
    const allowed = {
      '10.220.130.117',
      '192.168.0.197',
    };
    return allowed.contains(host);
  }

  // ========== Fixture ==========
  static String get fixtureEndpoint => '$baseUrl/Fixture/GetFixtureByQr';
  static String get logFileBase     => '$baseUrl/Data/Fixture';

  // ========== Shielding Box ==========
  static String get shieldingEndpoint => '$baseUrl/Admin/SheildingBox/GetSheildingBoxByQr';
  static String get shieldingFileBase => '$baseUrl/Data/Shelingbox';

  // ========== Chuẩn hóa file URL (dùng cho ảnh, PDF, v.v.) ==========
  static String normalizeUrl(String url) =>
      url.startsWith('http') ? url : '$baseUrl/$url';

  static String normalizeNotificationUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final context = _notificationContextPath.trim();
    final sanitizedContext = context.isEmpty
        ? ''
        : (context.startsWith('/') ? context : '/$context');
    final sanitizedPath = url.startsWith('/') ? url : '/$url';

    if (sanitizedContext.isNotEmpty &&
        (sanitizedPath == sanitizedContext ||
            sanitizedPath.startsWith('$sanitizedContext/'))) {
      return '$_notificationHost$sanitizedPath';
    }

    return '$_notificationHost$sanitizedContext$sanitizedPath';
  }
}
