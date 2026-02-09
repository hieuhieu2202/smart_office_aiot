class ScanResult {
  final String? serial;
  final String? model;

  ScanResult({
    this.serial,
    this.model,
  });

  bool get hasSerial => serial != null && serial!.isNotEmpty;
}
