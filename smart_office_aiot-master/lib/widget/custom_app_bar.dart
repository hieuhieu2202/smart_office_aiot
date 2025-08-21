import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic title; // String hoặc Widget (Row, Obx, ...)
  final bool isDark;
  final Color accent;
  final double height;
  final Widget? leading;
  final TextAlign titleAlign;
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.isDark,
    required this.accent,
    this.height = 50,
    this.leading,
    this.actions,
    this.titleAlign = TextAlign.center,
  }) : super(key: key);

  // Style dùng chung
  TextStyle get _titleStyle => TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: accent,
    letterSpacing: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    Widget titleWidget;
    if (title is String) {
      titleWidget = Text(
        title,
        textAlign: titleAlign,
        style: _titleStyle,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    } else if (title is Widget) {
      // Nếu là widget, bọc bằng DefaultTextStyle (và TextAlign)
      titleWidget = DefaultTextStyle(
        style: _titleStyle,
        child: Align(
          alignment: _textAlignToAlignment(titleAlign),
          child: title,
        ),
      );
    } else {
      titleWidget = const SizedBox.shrink();
    }

    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF222a36), const Color(0xFF19212a)]
                : [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // borderRadius: const BorderRadius.vertical(
          //   bottom: Radius.circular(22),
          // ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
            child: Row(
              children: [
                if (leading != null) leading!,
                if (leading != null) const SizedBox(width: 8),
                Expanded(child: titleWidget),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper chuyển TextAlign sang Alignment cho Align widget
  Alignment _textAlignToAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return Alignment.centerLeft;
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
