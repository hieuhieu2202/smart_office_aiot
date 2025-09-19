import 'package:flutter/material.dart';
import '../../controller/ai_controller.dart';
import 'ai_chat_sheet.dart';

class ChatbotFab extends StatelessWidget {
  final AiController controller;
  const ChatbotFab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => AiChatSheet.show(context, controller),
      icon: const Icon(Icons.smart_toy_outlined),
      label: const Text('Smart Chat'),
    );
  }
}
