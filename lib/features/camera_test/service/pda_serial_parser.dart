class PdaSerialParser {

  /// Parse raw text từ PDA scan
  /// Ví dụ:
  /// 692-9IAX0-000DL MT2605FT25188 A1
  /// -> trả về MT2605FT25188
  static String extractSerial(String raw) {
    final value = raw.trim();

    if (value.isEmpty) return '';

    // Tách theo khoảng trắng (1 hoặc nhiều space)
    final parts = value.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return parts[1];
    }

    // Nếu format khác thì trả nguyên
    return value;
  }
}