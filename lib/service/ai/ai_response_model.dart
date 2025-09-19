class AiResponse {
  final String answerMd;
  final List<Map<String, dynamic>> sources;
  final Map<String, dynamic> raw;

  AiResponse({
    required this.answerMd,
    required this.sources,
    required this.raw,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      answerMd: json['answer_md'] ?? '',
      sources: List<Map<String, dynamic>>.from(json['sources'] ?? []),
      raw: Map<String, dynamic>.from(json['raw'] ?? {}),
    );
  }
}
