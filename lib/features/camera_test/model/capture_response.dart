class CaptureResponse {
  CaptureResponse({
    required this.success,
    required this.message,
    this.savedFilePath,
  });

  final bool success;
  final String message;
  final String? savedFilePath;

  factory CaptureResponse.fromJson(Map<String, dynamic> json) {
    return CaptureResponse(
      success: json['Success'] ?? false,
      message: json['Message'] ?? '',
      savedFilePath: json['SavedFilePath'] as String?,
    );
  }
}
