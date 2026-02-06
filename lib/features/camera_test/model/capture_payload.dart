class CapturePayload {
  CapturePayload({
    required this.factory,
    required this.floor,
    required this.productName,
    required this.model,
    required this.sn,
    required this.time,
    required this.userName,
    required this.status,
    required this.comment,
    this.errorCode,
    this.images,
  });

  final String factory;
  final String floor;
  final String productName;
  final String model;
  final String sn;
  final String time;
  final String userName;
  final String status;
  final String comment;
  final String? errorCode;
  final List<String>? images;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'factory': factory,
      'floor': floor,
      'productName': productName,
      'model': model,
      'sn': sn,
      'time': time,
      'userName': userName,
      'status': status,
      'comment': comment,
    };

    if (errorCode != null) {
      payload['errorCode'] = errorCode;
    }
    if (images != null) {
      payload['images'] = images;
    }

    return payload;
  }
}
