import '../model/scan_result.dart';

class ScanPayloadExtractor {
  static ScanResult extract(String raw) {
    if (raw.trim().isEmpty) {
      return ScanResult();
    }

    final text = raw.trim().toUpperCase();
    final tokens = text.split(RegExp(r'\s+'));

    String? model;
    String? serial;

    // Ưu tiên theo vị trí space
    if (tokens.length >= 2) {
      final t0 = tokens[0];
      final t1 = tokens[1];

      // Model: thường có dấu '-' và bắt đầu bằng số
      if (_looksLikeModel(t0)) {
        model = t0;
      }

      // Serial: thường dài, không có '-', không phải revision
      if (_looksLikeSerial(t1)) {
        serial = t1;
      }
    }

    //  FALLBACK
    for (final token in tokens) {
      if (token.isEmpty) continue;

      // bỏ revision
      if (RegExp(r'^[A-Z][0-9]$').hasMatch(token)) continue;

      if (model == null && _looksLikeModel(token)) {
        model = token;
        continue;
      }

      if (serial == null && _looksLikeSerial(token)) {
        serial = token;
      }
    }

    return ScanResult(
      model: model,
      serial: serial,
    );
  }

  // HELPERS
  static bool _looksLikeModel(String v) {
    // ví dụ 692-9IAG1-0100IH
    return RegExp(r'^[0-9]{3}-[A-Z0-9-]{6,}$').hasMatch(v);
  }

  static bool _looksLikeSerial(String v) {
    // serial dài, KHÔNG có '-', KHÔNG phải revision
    if (v.contains('-')) return false;
    if (RegExp(r'^[A-Z][0-9]$').hasMatch(v)) return false;

    return RegExp(r'^[A-Z0-9]{8,}$').hasMatch(v);
  }
}
