import 'package:intl/intl.dart';

class StencilDetail {
  const StencilDetail({
    required this.customer,
    required this.floor,
    required this.stencilSn,
    required this.vendorCode,
    required this.vendorName,
    this.mfrTime,
    this.mfrSn,
    this.stencilVersion,
    this.process,
    this.location,
    this.length,
    this.width,
    this.thickness,
    this.tension,
    this.limitWashTime,
    this.standardTimes,
    this.alertTimes,
    this.totalUseTimes,
    this.status,
    this.peEmp,
    this.checkTime,
    this.lineName,
    this.startTime,
  });

  factory StencilDetail.fromJson(Map<String, dynamic> json) {
    final normalized = <String, dynamic>{};
    json.forEach((key, value) {
      if (key == null) return;
      normalized[key.toString().toUpperCase()] = value;
    });

    String? _string(String key) {
      final value = normalized[key];
      if (value == null) return null;
      if (value is String) return value.trim();
      return value.toString();
    }

    String? _stringFromKeys(List<String> keys) {
      for (final key in keys) {
        final value = _string(key);
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    String _stringOrEmpty(String key) => _string(key) ?? '';

    int? _int(String key) {
      final value = normalized[key];
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString());
    }

    double? _double(String key) {
      final value = normalized[key];
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString());
    }

    DateTime? _date(String key) {
      final raw = _string(key);
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return StencilDetail(
      customer: _stringOrEmpty('CUSTOMER'),
      floor: _stringOrEmpty('FLOOR'),
      stencilSn: _stringOrEmpty('STENCIL_SN'),
      vendorCode: _stringFromKeys(['VENDOR_CODE', 'VENDER_CODE']) ?? '',
      vendorName: _stringFromKeys(['VENDOR_NAME', 'VENDER_NAME']) ?? '',
      mfrTime: _date('MFR_TIME'),
      mfrSn: _string('MFR_SN'),
      stencilVersion: _string('STENCIL_VER'),
      process: _string('PROCESS'),
      location: _string('LOCATION'),
      length: _double('LENGTH'),
      width: _double('WIDTH'),
      thickness: _string('THICKNESS'),
      tension: _double('TENSION'),
      limitWashTime: _int('LIMIT_WASH_TIME'),
      standardTimes: _int('STANDARD_TIMES'),
      alertTimes: _int('ALERT_TIMES'),
      totalUseTimes: _int('TOTAL_USE_TIMES'),
      status: _string('STATUS'),
      peEmp: _string('PE_EMP'),
      checkTime: _date('CHECK_TIME'),
      lineName: _string('LINE_NAME'),
      startTime: _date('START_TIME'),
    );
  }

  final String customer;
  final String floor;
  final String stencilSn;
  final String vendorCode;
  final String vendorName;
  final DateTime? mfrTime;
  final String? mfrSn;
  final String? stencilVersion;
  final String? process;
  final String? location;
  final double? length;
  final double? width;
  final String? thickness;
  final double? tension;
  final int? limitWashTime;
  final int? standardTimes;
  final int? alertTimes;
  final int? totalUseTimes;
  final String? status;
  final String? peEmp;
  final DateTime? checkTime;
  final String? lineName;
  final DateTime? startTime;

  String get customerLabel => _normalizeLabel(customer);
  String get floorLabel => _normalizeLabel(floor);

  String get statusLabel => _normalizeLabel(status ?? '');

  bool get isActive => startTime != null;

  double? get runningHours {
    if (startTime == null) return null;
    final diff = DateTime.now().difference(startTime!);
    return diff.inMinutes / 60.0;
  }

  String formatDate(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }

  static String _normalizeLabel(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'UNKNOWN' : trimmed;
  }
}
