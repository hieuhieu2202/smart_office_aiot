import 'package:flutter/foundation.dart';

/// Một node (CDU) trên layout
class CduNode {
  /// Nhãn hiển thị (thường là CDUName)
  final String id;

  /// Toạ độ và kích thước theo tỉ lệ 0..1 (đã chia /100 từ API)
  final double x;
  final double y;
  final double w;
  final double h;

  /// Trạng thái đơn giản để tô màu badge (on/off/warning/no_connect/...)
  final String status;

  /// Thông tin chi tiết (DataMonitor) dùng cho tooltip
  final Map<String, dynamic> detail;

  CduNode({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.status,
    required this.detail,
  });

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return 'CduNode(id=$id, x=$x, y=$y, w=$w, h=$h, status=$status)';
  }
}
