class PdaSerialParser {

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

// // Trường hợp lấy serial trả về nguyên chuỗi
// class PdaSerialParser {
//
//   /// Trả về toàn bộ dữ liệu scan từ PDA
//   /// Ví dụ:
//   /// 692-9IAX0-000DL MT2605FT25188 A1
//   /// -> trả về nguyên chuỗi
//   static String extractSerial(String raw) {
//     final value = raw.trim();
//
//     if (value.isEmpty) return '';
//
//     // Chuẩn hoá khoảng trắng (tránh PDA gửi nhiều space)
//     final normalized = value.replaceAll(RegExp(r'\s+'), ' ');
//
//     return normalized;
//   }
// }
