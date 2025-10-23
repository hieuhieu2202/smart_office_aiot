import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hiển thị 3 giá trị PASS | YR | RR theo bố cục bảng giống web.
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
  final double yr; // Yield Rate %
  final double rr; // Retest Rate %
  final bool compact;
  final VoidCallback? onTapPass;
  final VoidCallback? onTapYr;
  final VoidCallback? onTapRr;

  @override
  Widget build(BuildContext context) {
    const dividerColor = Color(0xFF1C2F4A);
    const passColor = Color(0xFF38D893);
    const neutralColor = Colors.white70;
    const infoColor = Color(0xFF42A0FF);
    const warnColor = Color(0xFFFFC56F);
    const dangerColor = Color(0xFFFF6B6B);

    final baseFontSize = compact ? 12.0 : 13.0;

    final passValue = pass.isFinite ? pass : 0;
    final passText = passValue.round().toString();
    final passStyle = _metricStyle(
      fontSize: baseFontSize,
      color: passValue > 0 ? passColor : neutralColor,
      isBold: passValue > 0,
    );

    final yrValue = yr.isFinite ? yr : 0.0;
    final yrText = _pct(yrValue);
    final yrStyle = _metricStyle(
      fontSize: baseFontSize,
      color: yrValue <= 0
          ? neutralColor
          : yrValue < 95
              ? dangerColor
              : yrValue < 98
                  ? warnColor
                  : infoColor,
      isBold: yrValue >= 98,
    );

    final rrValue = rr.isFinite ? rr : 0.0;
    final rrText = _pct(rrValue);
    final rrStyle = _metricStyle(
      fontSize: baseFontSize,
      color: rrValue < 0 || rrValue >= 5
          ? dangerColor
          : rrValue >= 3
              ? warnColor
              : infoColor,
      isBold: rrValue > 0 && rrValue < 3,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _valueCell(text: passText, style: passStyle, onTap: onTapPass),
        _divider(dividerColor),
        _valueCell(text: yrText, style: yrStyle, onTap: onTapYr),
        _divider(dividerColor),
        _valueCell(text: rrText, style: rrStyle, onTap: onTapRr),
      ],
    );
  }

  TextStyle _metricStyle({
    required double fontSize,
    required Color color,
    bool isBold = false,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: .15,
      color: color,
    );
  }

  Widget _divider(Color color) => Container(
        width: 1,
        color: color.withOpacity(.65),
      );

  Widget _valueCell({
    required String text,
    required TextStyle style,
    VoidCallback? onTap,
  }) {
    Widget label = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );

    if (onTap != null) {
      label = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: label,
        ),
      );
    }

    return Expanded(child: label);
  }

  String _pct(double value) {
    if (value.isNaN || value <= 0) return '0%';
    final clamped = value.clamp(0, 100);
    if ((clamped - clamped.round()).abs() < 0.0001) {
      return '${clamped.round()}%';
    }
    final oneDecimal = (clamped * 10).roundToDouble() / 10;
    if ((clamped - oneDecimal).abs() < 0.0001) {
      return '${oneDecimal.toStringAsFixed(1)}%';
    }
    return '${clamped.toStringAsFixed(2)}%';
  }
}
