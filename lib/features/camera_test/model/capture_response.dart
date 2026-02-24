class CaptureResponse {
  final int statusCode;
  final String body;

  const CaptureResponse({
    required this.statusCode,
    required this.body,
  });

  bool get isSuccess => statusCode == 200;
}
