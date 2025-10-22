import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hiển thị 3 ô nhỏ trong mỗi “giờ”: PASS | YR | RR
/// - PASS: in đậm nếu > 0
/// - YR:   <95% đỏ ; 95–<98% vàng ; ≥98% trắng đậm
/// - RR:   ≥5% đỏ ; 3–<5% vàng ; <3% trắng đậm
class TripleCell extends StatelessWidget {
  const TripleCell({
    super.key,
    required this.pass,
    required this.yr,
    required this.rr,
    this.compact = true,
    this.onTapPass,
    this.onTapYr,
    this.onTapRr,
  });

  final double pass; // số lượng pass tại giờ đó
  final double yr;   // Yield Rate %
  final double rr;   // Retest Rate %
  final bool compact;
  final VoidCallback? onTapPass;
  final VoidCallback? onTapYr;
  final VoidCallback? onTapRr;

  @override
  Widget build(BuildContext context) {
    // Màu sử dụng
    final blue    = const Color(0xFF2E8AF7);
    final green   = const Color(0xFF21C079);
    final red     = const Color(0xFFE05656);
    final warning = const Color(0xFFFFA726);

    // Kích thước cơ sở (sẽ co giãn theo LayoutBuilder)
    final baseHeight = compact ? 24.0 : 26.0;
    final baseGap    = compact ? 6.0  : 8.0;
    final baseFont   = compact ? 11.0 : 12.0;
    final radius     = 10.0;

    // Chuẩn bị style theo ngưỡng (đồng bộ web)
    final passStr   = pass.isNaN ? '0' : pass.round().toString();
    final passBold  = (pass > 0);

    final yrVal   = yr.isNaN ? 0.0 : yr;
    final yrText  = _pct(yrVal);
    _BadgeStyle yrStyle;
    if (yrVal <= 0) {
      yrStyle = _BadgeStyle.neutral(blue); // không dữ liệu
    } else if (yrVal < 95.0) {
      yrStyle = _BadgeStyle.solid(red);          // đỏ
    } else if (yrVal < 98.0) {
      yrStyle = _BadgeStyle.solid(warning);      // vàng
    } else {
      yrStyle = _BadgeStyle.neutral(blue, bold: true); // ≥98% trắng đậm
    }

    final rrVal  = rr.isNaN ? 0.0 : rr;
    final rrText = _pct(rrVal);
    _BadgeStyle rrStyle;
    if (rrVal < 0 || rrVal >= 5.0) {
      rrStyle = _BadgeStyle.solid(red);          // đỏ
    } else if (rrVal >= 3.0) {
      rrStyle = _BadgeStyle.solid(warning);      // vàng
    } else {
      rrStyle = _BadgeStyle.neutral(blue, bold: true); // <3% trắng đậm
    }

    // Dùng LayoutBuilder để chia bề rộng theo không gian thực tế,
    // tránh tràn (overflow) ở mọi kích thước ô chứa.
    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth;

        // Số khoảng cách giữa 3 pill là 2 (trái-giữa, giữa-phải)
        // Nếu không gian quá nhỏ, giảm gap và font xuống cho vừa.
        final gap   = (maxW >= 120) ? baseGap : (baseGap * 0.6);
        final gapsW = 2 * gap;

        // Bề rộng cho 3 pill: chia đều phần còn lại
        final pillW = ((maxW - gapsW) / 3).clamp(34.0, 1000.0);

        // Co font và chiều cao nếu quá chật
        final scale = (pillW < 40) ? 0.9 : 1.0;
        final h  = baseHeight * scale;
        final fs = baseFont   * scale;

        return Row(
          children: [
            _pill(
              text: passStr,
              width: pillW,
              height: h,
              fs: fs,
              // PASS neutral xanh, đậm khi >0
              style: _BadgeStyle.neutral(blue, bold: passBold),
              radius: radius,
              onTap: onTapPass,
            ),
            SizedBox(width: gap),
            _pill(
              text: yrText,
              width: pillW,
              height: h,
              fs: fs,
              style: yrStyle,
              radius: radius,
              onTap: onTapYr,
            ),
            SizedBox(width: gap),
            _pill(
              text: rrText,
              width: pillW,
              height: h,
              fs: fs,
              style: rrStyle,
              radius: radius,
              onTap: onTapRr,
            ),
          ],
        );
      },
    );
  }

  // ---- Widgets & helpers ----
  Widget _pill({
    required String text,
    required double width,
    required double height,
    required double fs,
    required _BadgeStyle style,
    double radius = 12,
    VoidCallback? onTap,
  }) {
    Widget pill = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.fillColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: style.borderColor, width: 1),
      ),
      // Đề phòng chữ dài khi pill quá hẹp
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fs,
            fontWeight: style.bold ? FontWeight.w700 : FontWeight.w500,
            color: style.textColor,
          ),
        ),
      ),
    );

    if (onTap == null) {
      return pill;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: pill,
      ),
    );
  }

  String _pct(double v) {
    final clamped = v.isNaN ? 0 : v.clamp(0, 100);
    return '${clamped.toStringAsFixed(2)}%';
  }
}

/// Định nghĩa style cho “pill”: neutral (viền) / solid (nền cảnh báo)
class _BadgeStyle {
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final bool bold;

  _BadgeStyle({
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.bold,
  });

  factory _BadgeStyle.neutral(Color tone, {bool bold = false}) {
    return _BadgeStyle(
      fillColor: tone.withOpacity(.10),
      borderColor: tone.withOpacity(.35),
      textColor: tone,
      bold: bold,
    );
  }

  factory _BadgeStyle.solid(Color tone) {
    return _BadgeStyle(
      fillColor: tone.withOpacity(.12),
      borderColor: tone.withOpacity(.55),
      textColor: tone,
      bold: true,
    );
  }
}
