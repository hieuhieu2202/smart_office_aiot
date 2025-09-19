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

  // context mặc định: bạn có thể thay đổi để ghim Factory/Floor nếu cần
  final Map<String, Object?> _context = {};

  void setContext(Map<String, Object?> ctx) {
    _context
      ..clear()
      ..addAll(ctx);
  }

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
      messages.add(AiMessage(
        role: 'system',
        text: '> Lỗi gọi API: ${e.toString()}',
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Gợi ý mẫu câu — map theo 4 API của bạn
  List<String> get quickSuggestions => [
    // Curing Monitoring (theo ảnh bạn gửi chỉ có 1 màn)
    'Tổng quan Curing Monitoring',
    'Curing: model nào pass nhiều nhất?',
    'Curing: rack nào sắp hoàn thành?',
    // CDU Dashboard + Detail
    'CDU F16/F17 tổng quan',
    'CDU lỗi/abnormal đang có những máy nào?',
    'Xem chi tiết CDU#4 (F16)',
    'Xem chi tiết IP 10.122.206.25',
    // Rack (J_TAG, model, slot…)
    'Rack J_TAG: tổng quan hiệu suất',
    'Rack: RACK 6 chi tiết slot',
    'Model SA009400 đang ở rack nào?',
  ];
}
