import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../controller/ai_controller.dart';

class AiChatSheet extends StatefulWidget {
  final AiController controller;

  const AiChatSheet({super.key, required this.controller});

  static Future<void> show(BuildContext context, AiController controller) {
    controller.startNewChat();
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.70,
            minChildSize: 0.40,
            maxChildSize: 0.95,
            builder:
                (_, controllerScroll) => AiChatSheet(controller: controller),
          ),
    ).whenComplete(() {
      controller.reset();
    });
  }

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet>
    with SingleTickerProviderStateMixin {
  final _input = TextEditingController();
  final _scrollCtrl = ScrollController();

  late final AnimationController _logoAnim; // animation cho logo

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      lowerBound: 0.96,
      upperBound: 1.04,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoAnim.dispose();
    _input.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() async {
    final msg = _input.text.trim();
    if (msg.isEmpty) return;
    _input.clear();
    await widget.controller.ask(msg);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _logoAnim,
                    builder:
                        (_, child) => Transform.scale(
                          scale: _logoAnim.value,
                          child: child,
                        ),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primaryContainer, cs.secondaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.35),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.smart_toy_rounded),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart‑Factory Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            _PulseDot(),
                            SizedBox(width: 6),
                            Text(
                              'Đang hoạt động',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Navigator.pop(context);
                      widget.controller.reset();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ===== Gợi ý nhanh =====
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: c.quickSuggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final s = c.quickSuggestions[i];
                    return ActionChip(
                      label: Text(s),
                      onPressed: () async {
                        await c.ask(s);
                        _scrollToEnd();
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // ===== Messages =====
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  itemCount: c.messages.length,
                  itemBuilder: (context, i) {
                    final m = c.messages[i];
                    final isUser = m.role == 'user';
                    final isSystem = m.role == 'system';

                    final bubbleColor =
                        isUser
                            ? cs.primaryContainer
                            : isSystem
                            ? cs.errorContainer
                            : cs.surfaceVariant;

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 560),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                isUser
                                    ? cs.primary.withOpacity(.15)
                                    : cs.outlineVariant,
                          ),
                        ),
                        child:
                            isUser
                                ? Text(m.text)
                                : MarkdownBody(
                                  data: m.text,
                                  shrinkWrap: true,
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet.fromTheme(
                                    Theme.of(context),
                                  ).copyWith(
                                    p: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                      ),
                    );
                  },
                ),
              ),

              if (c.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: _TypingBar(),
                ),

              // ===== Input =====
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi…',
                        prefixIcon: const Icon(Icons.factory_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Chấm xanh “đang hoạt động” nhô nhô cho logo/label
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: 0.8,
        end: 1.2,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _TypingBar extends StatelessWidget {
  const _TypingBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        minHeight: 3,
        color: cs.primary,
        backgroundColor: cs.primary.withOpacity(0.15),
      ),
    );
  }
}
