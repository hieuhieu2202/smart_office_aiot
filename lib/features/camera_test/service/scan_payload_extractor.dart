import '../model/scan_result.dart';

class ScanPayloadExtractor {
  static ScanResult extract(String raw) {
    if (raw.trim().isEmpty) {
      return ScanResult();
    }
    return ScanResult(
      serial: raw.trim(),
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
