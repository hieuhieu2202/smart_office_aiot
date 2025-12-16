class ProductCapturePayload {
  String serial;
  String status;
  String user;
  String imageBase64;
  String time;
  String note;

  ProductCapturePayload({
    required this.serial,
    required this.status,
    required this.user,
    required this.imageBase64,
    required this.time,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
    "serial": serial,
    "status": status,
    "user": user,
    "imageBase64": imageBase64,
    "time": time,
    "note": note,
  };
}
