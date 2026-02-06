class ErrorItem {
  ErrorItem({
    required this.code,
    required this.description,
  });

  final String code;
  final String description;

  factory ErrorItem.fromCombined(String raw) {
    final parts = raw.split('-');
    if (parts.length < 2) {
      return ErrorItem(code: raw.trim(), description: '');
    }
    return ErrorItem(
      code: parts.first.trim(),
      description: parts.sublist(1).join('-').trim(),
    );
  }

  String get combinedLabel {
    if (description.isEmpty) {
      return code;
    }
    return '$code - $description';
  }
}
