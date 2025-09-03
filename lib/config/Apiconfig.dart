class ApiConfig {
  static const bool isProduction = true;

  static String get baseUrl => isProduction
      ? 'https://10.220.130.117:5555' // Server thật
      : 'http://192.168.0.197:5511';  // Server local/dev

  static String get fixtureEndpoint => '$baseUrl/Fixture/GetFixtureByQr';
  static String get logFileBase => '$baseUrl/Data/Fixture';
}
