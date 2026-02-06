class CapturePayload {
  final String factory;
  final String floor;
  final String serialNumber;
  final String station;
  final String result;
  final String comment;
  final String username;
  final String? errorCode;
  final String? errorName;
  final String? errorDescription;

  const CapturePayload({
    required this.factory,
    required this.floor,
    required this.serialNumber,
    required this.station,
    required this.result,
    required this.comment,
    required this.username,
    this.errorCode,
    this.errorName,
    this.errorDescription,
  });

  Map<String, String> toFields() {
    final fields = {
      "factory": factory,
      "floor": floor,
      "serialNumber": serialNumber,
      "station": station,
      "result": result,
      "comment": comment,
      "username": username,
    };

    if (errorCode != null) {
      fields["errorcode"] = errorCode!;
    }
    if (errorName != null) {
      fields["errorname"] = errorName!;
    }
    if (errorDescription != null) {
      fields["errordescription"] = errorDescription!;
    }

    return fields;
  }
}
