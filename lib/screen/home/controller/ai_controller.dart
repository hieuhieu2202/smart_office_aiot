import 'package:flutter/foundation.dart';
import '../../../service/ai/ai_api.dart';

class AiMessage {
  final String role; // 'user' | 'assistant' | 'system'
  final String text; // markdown
  final DateTime time;
  AiMessage({required this.role, required this.text}) : time = DateTime.now();
}

class AiController extends ChangeNotifier {
  final messages = <AiMessage>[];
  bool isLoading = false;

  final Map<String, Object?> _context = {};

  void setContext(Map<String, Object?> ctx) {
    _context
      ..clear()
      ..addAll(ctx);
    notifyListeners();
  }

  /// Bắt đầu phiên chat mới (xoá sạch lịch sử + có thể set context)
  void startNewChat({Map<String, Object?>? context}) {
    messages.clear();
    if (context != null) setContext(context);
    notifyListeners();
  }

  /// Dùng khi đóng sheet để đảm bảo state sạch
  void reset() => startNewChat();

  Future<void> ask(String message) async {
    if (message.trim().isEmpty) return;

    messages.add(AiMessage(role: 'user', text: message));
    isLoading = true;
    notifyListeners();

    try {
      final res = await AiApi().ask(message: message, context: _context);
      final md = (res['answer_md'] ?? '').toString();
      messages.add(AiMessage(role: 'assistant', text: md));
    } catch (e) {
      messages.add(AiMessage(role: 'system', text: '> Lỗi gọi API: ${e.toString()}'));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<String> get quickSuggestions => [
    'Tổng quan Curing Monitoring',
    'Phòng sấy ROOM1 hôm nay có bao nhiêu rack đang chạy?',
    'Curing tổng quan là bao nhiêu rack?',
    'PASS hiện tại bao nhiêu? ở curing',
    'CDU F16/F17 tổng quan',
    'CDU F17/3F tổng quan',
    'CDU nào đang OFF?',
    'F17 có bao nhiêu CDU abnormal?',
  ];
}
