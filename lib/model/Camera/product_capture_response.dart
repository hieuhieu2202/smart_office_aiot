class ProductCaptureResponse {
  bool success;
  String message;
  String? savedFilePath;

  ProductCaptureResponse({
    required this.success,
    required this.message,
    this.savedFilePath,
  });

  factory ProductCaptureResponse.fromJson(Map<String, dynamic> json) {
    return ProductCaptureResponse(
      success: json["Success"] ?? false,
      message: json["Message"] ?? "",
      savedFilePath: json["SavedFilePath"],
    );
  }
}
