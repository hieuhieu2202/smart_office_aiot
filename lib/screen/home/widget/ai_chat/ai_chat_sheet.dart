import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../controller/ai_controller.dart';

class AiChatSheet extends StatefulWidget {
  final AiController controller;
  const AiChatSheet({super.key, required this.controller});

  static Future<void> show(BuildContext context, AiController controller) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controllerScroll) => AiChatSheet(controller: controller),
      ),
    );
  }

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final _input = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() async {
    final msg = _input.text;
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
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8, top: 2),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.smart_toy_outlined, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Smart-office Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Gợi ý nhanh (chip)
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

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  itemCount: c.messages.length,
                  itemBuilder: (context, i) {
                    final m = c.messages[i];
                    final isUser = m.role == 'user';
                    final isSystem = m.role == 'system';

                    final bubbleColor = isUser
                        ? Theme.of(context).colorScheme.primaryContainer
                        : isSystem
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.surfaceVariant;

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 520),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: isUser
                            ? Text(m.text)
                            : MarkdownBody(
                          data: m.text,
                          shrinkWrap: true,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
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
                  child: LinearProgressIndicator(minHeight: 2),
                ),

              // Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi…',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
