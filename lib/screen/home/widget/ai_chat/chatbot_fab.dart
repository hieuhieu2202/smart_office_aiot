import 'dart:ui';
import 'package:flutter/material.dart';
import '../../controller/ai_controller.dart';
import 'ai_chat_sheet.dart';

enum TagStyle { gradient, glass }

class ChatbotFab extends StatefulWidget {
  final AiController controller;

  const ChatbotFab({super.key, required this.controller});

  @override
  State<ChatbotFab> createState() => _ChatbotFabState();
}

class _ChatbotFabState extends State<ChatbotFab> with TickerProviderStateMixin {
  // ===== Tuning nhanh =====
  static const double _iconSize = 84;
  static const Duration _pulseDur = Duration(milliseconds: 1400);
  static const Duration _tagAnimDur = Duration(seconds: 3);
  static const TagStyle _tagStyle = TagStyle.gradient;

  // ========================

  late final AnimationController _pulseCtrl;
  late final AnimationController _tagCtrl;
  late final Animation<double> _tagFade;
  late final Animation<Offset> _tagSlide;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this, duration: _pulseDur)
      ..repeat(reverse: true);

    _tagCtrl = AnimationController(vsync: this, duration: _tagAnimDur)
      ..repeat(reverse: true);

    final curve = CurvedAnimation(parent: _tagCtrl, curve: Curves.easeInOut);

    _tagFade = curve;
    _tagSlide = Tween<Offset>(
      begin: const Offset(-.12, 0),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final circleBg = isDark ? const Color(0xFF1C2533) : const Color(0xFFF2F5FF);
    final circleShadow =
        isDark ? Colors.black.withOpacity(.35) : Colors.indigo.withOpacity(.18);

    final scaleAnim = Tween(
      begin: .98,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    return ScaleTransition(
      scale: scaleAnim,
      child: GestureDetector(
        onTap: () => AiChatSheet.show(context, widget.controller),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Nền tròn sau icon
            Image.asset(
              'assets/images/robot_icon.png',
              width: _iconSize,
              height: _iconSize,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.text,
    required this.style,
    required this.isDark,
  });

  final String text;
  final TagStyle style;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color:
          isDark
              ? Colors.white.withOpacity(.65)
              : Colors.black.withOpacity(.55),
      width: 1.1,
    );

    switch (style) {
      case TagStyle.gradient:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: border,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? const [Color(0xFF2B6CB0), Color(0xFF0EA5E9)]
                      : const [Color(0xFFA5B4FC), Color(0xFF60A5FA)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? .35 : .18),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );

      case TagStyle.glass:
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: (isDark ? Colors.white : Colors.black).withOpacity(.08),
                border: border,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? .35 : .18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}
